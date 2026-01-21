//
//  AuthService.swift
//  Glasscast
//

import Foundation
import Supabase
import Combine
import SwiftUI

enum AuthError: Error, LocalizedError {
    case notConfigured
    case invalidEmail
    case signInFailed(Error)
    case signUpFailed(Error)
    case verifyOTPFailed(Error)
    case signOutFailed(Error)
    case noSession
    case unknown

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please check your Config.xcconfig file."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .signUpFailed(let error):
            return "Sign up failed: \(error.localizedDescription)"
        case .verifyOTPFailed(let error):
            return "Verification failed: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Sign out failed: \(error.localizedDescription)"
        case .noSession:
            return "No active session"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

enum SessionState: Equatable {
    case unknown      // Initial state - checking session
    case authenticated
    case unauthenticated
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var sessionState: SessionState = .unknown
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading = false

    // Store auth state in UserDefaults for instant access on app launch
    @AppStorage("wasAuthenticated") private var wasAuthenticated = false

    private var supabase: SupabaseClient?

    var isAuthenticated: Bool {
        sessionState == .authenticated
    }

    private init() {
        // If user was previously authenticated, assume authenticated until verified
        // This prevents the auth screen flash
        if wasAuthenticated {
            sessionState = .unknown // Will be verified shortly
        } else {
            sessionState = .unauthenticated
        }
        setupSupabase()
    }

    private func setupSupabase() {
        let url = AppConfig.supabaseURL
        let key = AppConfig.supabaseAnonKey

        guard !url.isEmpty,
              !key.isEmpty,
              let supabaseURL = URL(string: url),
              let host = supabaseURL.host,
              host.contains(".supabase.co") else {
            #if DEBUG
            print("AuthService: Supabase not configured - need valid supabase.co URL")
            #endif
            sessionState = .unauthenticated
            return
        }

        supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
        Task {
            await checkSession()
        }
    }

    var isConfigured: Bool {
        supabase != nil
    }

    func checkSession() async {
        guard let supabase = supabase else {
            sessionState = .unauthenticated
            wasAuthenticated = false
            return
        }

        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            sessionState = .authenticated
            wasAuthenticated = true
        } catch {
            currentUser = nil
            sessionState = .unauthenticated
            wasAuthenticated = false
        }
    }

    func sendOTP(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signInWithOTP(email: email)
        } catch {
            throw AuthError.signInFailed(error)
        }
    }

    func verifyOTP(email: String, token: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )

            // Clear any cached data from previous user before setting new user
            await clearUserData()

            currentUser = session.user
            sessionState = .authenticated
            wasAuthenticated = true
        } catch {
            throw AuthError.verifyOTPFailed(error)
        }
    }

    func signOut() async throws {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            sessionState = .unauthenticated
            wasAuthenticated = false

            // Clear all user-specific data
            await clearUserData()
        } catch {
            throw AuthError.signOutFailed(error)
        }
    }

    /// Clear all user-specific cached data
    private func clearUserData() async {
        // Clear FavoritesManager
        FavoritesManager.shared.clearAllData()

        // Clear all cache
        await CacheService.shared.clearAll()

        // Clear persisted selected city
        UserDefaults.standard.removeObject(forKey: "selectedCityId")
    }

    func getCurrentUserId() -> UUID? {
        currentUser?.id
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
