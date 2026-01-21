//
//  AuthViewModel.swift
//  Glasscast
//

import Foundation
import SwiftUI

enum AuthState {
    case idle
    case enterEmail
    case enterOTP
    case loading
    case error(String)
}

@MainActor
@Observable
final class AuthViewModel {
    var email: String = ""
    var otpCode: String = ""
    var authState: AuthState = .enterEmail
    var errorMessage: String?
    var showError: Bool = false

    private let authService = AuthService.shared

    var isConfigured: Bool {
        authService.isConfigured
    }

    var isLoading: Bool {
        if case .loading = authState { return true }
        return false
    }

    var isValidEmail: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return false }

        // Simple but effective email validation regex
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmedEmail.range(of: emailRegex, options: .regularExpression) != nil
    }

    var canSendOTP: Bool {
        isValidEmail && !isLoading
    }

    var canVerifyOTP: Bool {
        otpCode.count == 6 && !isLoading
    }

    func sendOTP() async {
        authState = .loading
        errorMessage = nil

        do {
            try await authService.sendOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            authState = .enterOTP
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            authState = .enterEmail
        }
    }

    func verifyOTP() async {
        authState = .loading
        errorMessage = nil

        do {
            try await authService.verifyOTP(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                token: otpCode
            )
            authState = .idle
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            authState = .enterOTP
        }
    }

    func resendOTP() async {
        otpCode = ""
        await sendOTP()
    }

    func goBackToEmail() {
        otpCode = ""
        authState = .enterEmail
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
