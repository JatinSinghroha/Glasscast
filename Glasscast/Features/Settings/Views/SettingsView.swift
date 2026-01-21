//
//  SettingsView.swift
//  Glasscast
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showPrivacyAlert = false
    @State private var showHelpAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundGradient()

                ScrollView {
                    VStack(spacing: 20) {
                        profileSection
                        preferencesSection
                        aboutSection
                        signOutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Privacy Policy", isPresented: $showPrivacyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Privacy Policy")
        }
        .alert("Help & Support", isPresented: $showHelpAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Help & Support")
        }
        .confirmationDialog("Sign Out", isPresented: $viewModel.showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await viewModel.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var profileSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Profile")

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.teal, AppColors.darkTeal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Text(viewModel.userEmail?.prefix(1).uppercased() ?? "?")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    Text(viewModel.userEmail ?? "Not signed in")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                }

                Spacer()
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var preferencesSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Preferences")

            VStack(spacing: 0) {
                settingsRow(
                    icon: "thermometer",
                    title: "Temperature Unit",
                    trailing: {
                        Picker("", selection: $viewModel.temperatureUnit) {
                            ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.teal)
                    }
                )

                Divider()
                    .background(AppColors.divider)
                    .padding(.leading, 52)

                settingsRow(
                    icon: "paintbrush",
                    title: "Appearance",
                    trailing: {
                        Picker("", selection: $viewModel.appearance) {
                            ForEach(AppAppearance.allCases, id: \.self) { appearance in
                                Text(appearance.rawValue).tag(appearance)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.teal)
                    }
                )
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            sectionHeader("About")

            VStack(spacing: 0) {
                Button {
                    showPrivacyAlert = true
                } label: {
                    settingsRowContent(
                        icon: "lock.shield",
                        title: "Privacy Policy",
                        trailing: {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .background(AppColors.divider)
                    .padding(.leading, 52)

                Button {
                    showHelpAlert = true
                } label: {
                    settingsRowContent(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        trailing: {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .background(AppColors.divider)
                    .padding(.leading, 52)

                settingsRowContent(
                    icon: "info.circle",
                    title: "Version",
                    trailing: {
                        Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                )
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var signOutSection: some View {
        Button {
            viewModel.showSignOutConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.body)
                    .foregroundStyle(.red)
                    .frame(width: 28)

                Text("Sign Out")
                    .font(.body)
                    .foregroundStyle(.red)

                Spacer()

                if viewModel.isSigningOut {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.red)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .disabled(viewModel.isSigningOut)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    private func settingsRow<Trailing: View>(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        settingsRowContent(icon: icon, title: title, trailing: trailing)
    }

    private func settingsRowContent<Trailing: View>(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 28)

            Text(title)
                .font(.body)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
}
