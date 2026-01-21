//
//  GlasscastApp.swift
//  Glasscast
//
//  Created by Jatin Singhroha on 21/01/26.
//

import SwiftUI

@main
struct GlasscastApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("appearance") private var appearanceRawValue: String = "System"

    private var colorScheme: ColorScheme? {
        switch appearanceRawValue {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil // System
        }
    }

    var body: some View {
        Group {
            switch authService.sessionState {
            case .unknown:
                // Show loading while checking auth state
                // This prevents the auth screen flash
                SplashView()
            case .authenticated:
                MainTabView()
            case .unauthenticated:
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authService.sessionState)
        .preferredColorScheme(colorScheme)
    }
}

// Splash screen shown while checking auth state
struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Use AppColors.background for proper light/dark support
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.teal.opacity(0.3), AppColors.darkTeal.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 48))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppColors.teal)
                }

                Text("Glasscast")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppColors.textPrimary)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppColors.teal)
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
    }
}
