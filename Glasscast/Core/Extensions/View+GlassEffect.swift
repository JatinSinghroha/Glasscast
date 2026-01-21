//
//  View+GlassEffect.swift
//  Glasscast
//

import SwiftUI

extension View {
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .glassEffect()
            }
    }

    @ViewBuilder
    func glassPill() -> some View {
        self
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .glassEffect()
            }
    }

    @ViewBuilder
    func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .glassEffect()
            }
    }
}

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .glassEffect()
            }
    }
}

// MARK: - Legacy Gradient Background (uses AppColors now)
struct GradientBackground: View {
    var body: some View {
        AppColors.background
            .ignoresSafeArea()
    }
}
