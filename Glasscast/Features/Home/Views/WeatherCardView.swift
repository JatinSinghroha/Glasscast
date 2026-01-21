//
//  WeatherCardView.swift
//  Glasscast
//

import SwiftUI

struct WeatherCardView: View {
    let weather: Weather

    private var tempFormatter: TemperatureFormatter {
        TemperatureFormatter.shared
    }

    var body: some View {
        VStack(spacing: 20) {
            // Main temperature display
            HStack(alignment: .top) {
                // Weather icon
                ZStack {
                    Circle()
                        .fill(AppColors.teal.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: weather.condition.iconName)
                        .font(.system(size: 40))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppColors.teal)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(tempFormatter.format(weather.temperature))
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(weather.condition.rawValue)
                        .font(.title3)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            // Weather details pills
            HStack(spacing: 12) {
                WeatherPill(icon: "arrow.up", text: tempFormatter.format(weather.tempMax))
                WeatherPill(icon: "arrow.down", text: tempFormatter.format(weather.tempMin))
                WeatherPill(icon: "drop.fill", text: weather.rainChanceFormatted)
                WeatherPill(icon: "wind", text: weather.windSpeedFormatted)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
    }
}

struct WeatherPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(AppColors.teal.opacity(0.1))
        }
    }
}

#Preview {
    ZStack {
        AppBackgroundGradient()
        WeatherCardView(weather: .preview)
            .padding()
    }
}

extension Weather {
    static var preview: Weather {
        Weather(
            cityName: "San Francisco",
            country: "US",
            temperature: 18,
            feelsLike: 17,
            tempMin: 14,
            tempMax: 22,
            humidity: 65,
            windSpeed: 12,
            condition: .clear,
            description: "Clear sky",
            iconCode: "01d",
            rainChance: 10,
            timestamp: Date()
        )
    }
}
