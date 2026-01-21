//
//  FavoriteCityCard.swift
//  Glasscast
//

import SwiftUI

struct FavoriteCityCard: View {
    let favorite: FavoriteCity
    let onTap: () -> Void
    var isToggling: Bool = false
    var onUnfavorite: (() -> Void)? = nil

    private var tempFormatter: TemperatureFormatter {
        TemperatureFormatter.shared
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Weather icon
                ZStack {
                    Circle()
                        .fill(AppColors.teal.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: (favorite.weather?.condition ?? .clear).iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.teal)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.cityName)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    if let country = favorite.country {
                        Text(country)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    if let weather = favorite.weather {
                        Text(weather.condition.rawValue)
                            .font(.caption)
                            .foregroundStyle(AppColors.teal)
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    let displayWeather = favorite.weather ?? .placeholder

                    Text(tempFormatter.format(displayWeather.temperature))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(spacing: 4) {
                        Label(tempFormatter.format(displayWeather.tempMax), systemImage: "arrow.up")
                        Label(tempFormatter.format(displayWeather.tempMin), systemImage: "arrow.down")
                    }
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
                }
                .redacted(reason: favorite.weather == nil ? .placeholder : [])

                // Unfavorite button
                if let onUnfavorite = onUnfavorite {
                    FavoriteButton(
                        isFavorite: true,
                        action: onUnfavorite,
                        size: .medium,
                        isLoading: isToggling
                    )
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        AppBackgroundGradient()
        VStack(spacing: 12) {
            FavoriteCityCard(
                favorite: FavoriteCity(
                    userId: UUID(),
                    cityName: "San Francisco",
                    country: "US",
                    lat: 37.7749,
                    lon: -122.4194,
                    isFavorite: true,
                    weather: .preview
                ),
                onTap: {}
            )

            FavoriteCityCard(
                favorite: FavoriteCity(
                    userId: UUID(),
                    cityName: "New York",
                    country: "US",
                    lat: 40.7128,
                    lon: -74.0060,
                    isFavorite: true
                ),
                onTap: {}
            )
        }
        .padding()
    }
}
