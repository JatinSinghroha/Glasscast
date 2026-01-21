//
//  AuthView.swift
//  Glasscast
//

import SwiftUI

struct AuthView: View {
    @State private var viewModel = AuthViewModel()
    @FocusState private var emailFieldFocused: Bool
    @FocusState private var otpFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // System-adaptive background
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                headerSection

                switch viewModel.authState {
                case .enterEmail, .idle:
                    emailSection
                case .enterOTP:
                    otpSection
                case .loading:
                    loadingSection
                case .error:
                    emailSection
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // App icon with teal gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.teal.opacity(0.3), AppTheme.darkTeal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.teal)
            }

            Text("Glasscast")
                .font(.largeTitle.bold())
                .foregroundColor(AppColors.textPrimary)

            Text("Sign in to sync your favorites")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var emailSection: some View {
        VStack(spacing: 20) {
            emailInputField
            sendCodeButton
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var emailInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppColors.textSecondary)

            emailTextField
        }
    }

    private var emailTextField: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $viewModel.email, prompt: Text("your@example.com").foregroundColor(.black))
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .foregroundColor(AppColors.textPrimary)
                .tint(AppTheme.teal)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(emailFieldFocused ? AppTheme.teal.opacity(0.5) : AppColors.divider, lineWidth: 1)
        )
        .focused($emailFieldFocused)
    }

    private var sendCodeButton: some View {
        Button {
            Task {
                await viewModel.sendOTP()
            }
        } label: {
            HStack {
                Text("Send Code")
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [AppTheme.teal, AppTheme.darkTeal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppTheme.teal.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canSendOTP)
        .opacity(viewModel.canSendOTP ? 1.0 : 0.5)
    }

    private var otpSection: some View {
        VStack(spacing: 20) {
            otpHeader
            otpTextField
            verifyButton
            otpActionButtons
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var otpHeader: some View {
        VStack(spacing: 8) {
            Text("Enter Verification Code")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            Text("We sent a 6-digit code to")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Text(viewModel.email)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.teal)
        }
    }

    private var otpTextField: some View {
        ZStack {
            // Placeholder
            if viewModel.otpCode.isEmpty {
                Text("000000")
                    .font(.title.monospaced())
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }

            TextField("", text: $viewModel.otpCode)
                .textFieldStyle(.plain)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.title.monospaced())
                .padding()
                .foregroundColor(AppColors.textPrimary)
                .tint(AppTheme.teal)
                .onChange(of: viewModel.otpCode) { _, newValue in
                    viewModel.otpCode = String(newValue.prefix(6).filter { $0.isNumber })
                }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(otpFieldFocused ? AppTheme.teal.opacity(0.5) : AppColors.divider, lineWidth: 1)
        )
        .focused($otpFieldFocused)
    }

    private var verifyButton: some View {
        Button {
            Task {
                await viewModel.verifyOTP()
            }
        } label: {
            HStack {
                Text("Verify & Sign In")
                    .fontWeight(.semibold)
                Image(systemName: "checkmark.circle.fill")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [AppTheme.teal, AppTheme.darkTeal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppTheme.teal.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canVerifyOTP)
        .opacity(viewModel.canVerifyOTP ? 1.0 : 0.5)
    }

    private var otpActionButtons: some View {
        HStack(spacing: 24) {
            Button {
                viewModel.goBackToEmail()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                    Text("Back")
                }
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            }

            Button {
                Task {
                    await viewModel.resendOTP()
                }
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.teal)
            }
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppTheme.teal)
                .scaleEffect(1.5)

            Text("Please wait...")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }
}

#Preview {
    AuthView()
}
