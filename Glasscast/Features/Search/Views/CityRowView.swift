//
//  CityRowView.swift
//  Glasscast
//

import SwiftUI

struct CityRowView: View {
    let city: City
    let isAdded: Bool
    let onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Location pin icon
            ZStack {
                Circle()
                    .fill(AppColors.teal.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.teal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text(city.displayName)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            if isAdded {
                // Checkmark to show it's added
                ZStack {
                    Circle()
                        .fill(AppColors.teal.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.teal)
                }
            } else {
                // Not added - show add button
                Button {
                    onAddTapped()
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppColors.teal)
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
    }
}

#Preview {
    ZStack {
        AppBackgroundGradient()
        VStack(spacing: 16) {
            CityRowView(
                city: City(
                    name: "San Francisco",
                    country: "US",
                    state: "California",
                    lat: 37.7749,
                    lon: -122.4194
                ),
                isAdded: false,
                onAddTapped: {}
            )
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
            }

            CityRowView(
                city: City(
                    name: "New York",
                    country: "US",
                    state: "New York",
                    lat: 40.7128,
                    lon: -74.0060
                ),
                isAdded: true,
                onAddTapped: {}
            )
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
            }
        }
        .padding()
    }
}
