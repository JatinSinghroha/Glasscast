//
//  ForecastRowView.swift
//  Glasscast
//

import SwiftUI

struct ForecastRowView: View {
    let forecast: Forecast

    private var tempFormatter: TemperatureFormatter {
        TemperatureFormatter.shared
    }

    var body: some View {
        HStack {
            Text(forecast.dayOfWeek)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 50, alignment: .leading)

            Image(systemName: forecast.condition.iconName)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppColors.teal)
                .frame(width: 40)

            if forecast.rainChance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                    Text("\(forecast.rainChance)%")
                        .font(.caption)
                }
                .foregroundStyle(AppColors.teal)
                .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(tempFormatter.formatValue(forecast.tempMin))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 30, alignment: .trailing)

                TemperatureBar(
                    tempMin: forecast.tempMin,
                    tempMax: forecast.tempMax,
                    rangeMin: 0,
                    rangeMax: 40
                )
                .frame(width: 60, height: 4)

                Text(tempFormatter.formatValue(forecast.tempMax))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 30, alignment: .leading)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct TemperatureBar: View {
    let tempMin: Double
    let tempMax: Double
    let rangeMin: Double
    let rangeMax: Double

    var body: some View {
        GeometryReader { geometry in
            let totalRange = rangeMax - rangeMin
            let startPercent = max(0, (tempMin - rangeMin) / totalRange)
            let endPercent = min(1, (tempMax - rangeMin) / totalRange)

            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.divider)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.teal, AppColors.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (endPercent - startPercent))
                        .offset(x: geometry.size.width * startPercent)
                }
        }
    }
}

struct ForecastListView: View {
    let forecasts: [Forecast]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("5-Day Forecast")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()
                .background(AppColors.divider)
                .padding(.horizontal, 16)

            ForEach(forecasts) { forecast in
                ForecastRowView(forecast: forecast)

                if forecast.id != forecasts.last?.id {
                    Divider()
                        .background(AppColors.divider)
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.bottom, 8)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    ZStack {
        AppBackgroundGradient()
        ForecastListView(forecasts: Forecast.previews)
            .padding()
    }
}

extension Forecast {
    static var previews: [Forecast] {
        let calendar = Calendar.current
        return (1...5).map { dayOffset in
            Forecast(
                date: calendar.date(byAdding: .day, value: dayOffset, to: Date())!,
                tempMin: Double.random(in: 10...18),
                tempMax: Double.random(in: 20...28),
                condition: [.clear, .clouds, .rain, .clear, .clouds][dayOffset - 1],
                iconCode: "01d",
                rainChance: [0, 20, 80, 0, 30][dayOffset - 1]
            )
        }
    }
}
