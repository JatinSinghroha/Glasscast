//
//  SettingsViewModel.swift
//  Glasscast
//

import Foundation
import SwiftUI
internal import Auth

enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"

    var symbol: String {
        switch self {
        case .celsius: return "C"
        case .fahrenheit: return "F"
        }
    }
}

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
@Observable
final class SettingsViewModel {
    var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
            // Sync with shared formatter
            TemperatureFormatter.shared.unit = temperatureUnit
        }
    }

    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appearance")
        }
    }

    var isSigningOut = false
    var errorMessage: String?
    var showError = false
    var showSignOutConfirmation = false

    private let authService = AuthService.shared

    var userEmail: String? {
        authService.currentUser?.email
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    init() {
        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit")
        temperatureUnit = TemperatureUnit(rawValue: savedUnit ?? "") ?? .celsius

        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")

        let savedAppearance = UserDefaults.standard.string(forKey: "appearance")
        appearance = AppAppearance(rawValue: savedAppearance ?? "") ?? .system
    }

    func signOut() async {
        isSigningOut = true
        errorMessage = nil

        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSigningOut = false
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
