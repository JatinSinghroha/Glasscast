//
//  AppTheme.swift
//  Glasscast
//

import SwiftUI

// MARK: - App Colors (from Asset Catalog - auto adapts to light/dark mode)
enum AppColors {
    /// Main app background - adapts to light/dark mode
    static let background = Color("AppBackground")

    /// Card/container background - adapts to light/dark mode
    static let cardBackground = Color("CardBackground")

    /// Primary text color - adapts to light/dark mode
    static let textPrimary = Color("TextPrimary")

    /// Secondary text color - adapts to light/dark mode
    static let textSecondary = Color("TextSecondary")

    /// Divider color - adapts to light/dark mode
    static let divider = Color("Divider")

    /// Primary teal accent color
    static let teal = Color("AppTeal")

    /// Darker teal variant
    static let darkTeal = Color("DarkTeal")
}

// MARK: - Legacy AppTheme (for backwards compatibility)
enum AppTheme {
    static var teal: Color { AppColors.teal }
    static var darkTeal: Color { AppColors.darkTeal }
    static var accent: Color { AppColors.teal }

    static var darkBackground: Color { AppColors.background }
    static var darkCardBackground: Color { AppColors.cardBackground }
    static var lightBackground: Color { AppColors.background }
    static var lightCardBackground: Color { AppColors.cardBackground }
}

// MARK: - App Background View
struct AppBackgroundGradient: View {
    var body: some View {
        AppColors.background
            .ignoresSafeArea()
    }
}

// MARK: - Weather Background Gradient
struct WeatherBackgroundGradient: View {
    let condition: WeatherCondition

    var body: some View {
        LinearGradient(
            colors: [
                AppColors.background,
                conditionTint.opacity(0.3),
                AppColors.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var conditionTint: Color {
        switch condition {
        case .clear:
            return .orange.opacity(0.3)
        case .clouds:
            return .gray.opacity(0.3)
        case .rain, .drizzle:
            return .blue.opacity(0.3)
        case .thunderstorm:
            return .purple.opacity(0.3)
        case .snow:
            return .cyan.opacity(0.3)
        default:
            return AppColors.teal.opacity(0.2)
        }
    }
}

// MARK: - Card Style Modifier
struct AppCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardStyle())
    }
}
