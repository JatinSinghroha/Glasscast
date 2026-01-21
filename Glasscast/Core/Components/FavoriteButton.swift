//
//  FavoriteButton.swift
//  Glasscast
//

import SwiftUI

/// Animated favorite heart button with teal color scheme
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    var size: ButtonSize = .medium
    var isLoading: Bool = false

    enum ButtonSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 24
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }

        var progressSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
    }

    @State private var isAnimating = false

    var body: some View {
        Button {
            guard !isLoading else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppColors.teal)
                        .scaleEffect(size.progressSize / 20)
                } else {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: size.iconSize))
                        .foregroundStyle(isFavorite ? AppColors.teal : AppColors.textSecondary)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                }
            }
            .frame(width: size.iconSize, height: size.iconSize)
            .padding(size.padding)
            .background {
                Circle()
                    .fill(isFavorite ? AppColors.teal.opacity(0.15) : Color.clear)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isFavorite)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isFavorite)
    }
}

/// Larger favorite button with label for toolbars
struct FavoriteToolbarButton: View {
    let isFavorite: Bool
    let action: () -> Void
    var isLoading: Bool = false

    @State private var isAnimating = false

    var body: some View {
        Button {
            guard !isLoading else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppColors.teal)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .medium))
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                }
            }
            .frame(width: 20, height: 20)
            .foregroundStyle(isFavorite ? AppColors.teal : AppColors.textSecondary)
        }
        .disabled(isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isFavorite)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isFavorite)
    }
}

#Preview {
    ZStack {
        AppBackgroundGradient()
        VStack(spacing: 32) {
            HStack(spacing: 24) {
                FavoriteButton(isFavorite: false, action: {}, size: .small)
                FavoriteButton(isFavorite: true, action: {}, size: .small)
            }
            HStack(spacing: 24) {
                FavoriteButton(isFavorite: false, action: {}, size: .medium)
                FavoriteButton(isFavorite: true, action: {}, size: .medium)
            }
            HStack(spacing: 24) {
                FavoriteButton(isFavorite: false, action: {}, size: .large)
                FavoriteButton(isFavorite: true, action: {}, size: .large)
            }
            HStack(spacing: 24) {
                FavoriteToolbarButton(isFavorite: false, action: {})
                FavoriteToolbarButton(isFavorite: true, action: {})
            }
        }
        .padding()
    }
}
