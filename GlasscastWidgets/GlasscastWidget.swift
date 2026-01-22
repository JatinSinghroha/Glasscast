//
//  GlasscastWidget.swift
//  GlasscastWidgets
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct WeatherEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let temperature: Int
    let condition: String
    let conditionIcon: String
    let highTemp: Int
    let lowTemp: Int
    let isPlaceholder: Bool

    /// Initialize from shared weather data
    init(from data: WidgetWeatherData) {
        self.date = data.updatedAt
        self.cityName = data.cityName
        self.temperature = Int(round(data.temperature))
        self.condition = data.condition
        self.conditionIcon = data.conditionIcon
        self.highTemp = Int(round(data.tempMax))
        self.lowTemp = Int(round(data.tempMin))
        self.isPlaceholder = false
    }

    init(date: Date, cityName: String, temperature: Int, condition: String, conditionIcon: String, highTemp: Int, lowTemp: Int, isPlaceholder: Bool) {
        self.date = date
        self.cityName = cityName
        self.temperature = temperature
        self.condition = condition
        self.conditionIcon = conditionIcon
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.isPlaceholder = isPlaceholder
    }

    static var placeholder: WeatherEntry {
        WeatherEntry(
            date: Date(),
            cityName: "San Francisco",
            temperature: 18,
            condition: "Clear",
            conditionIcon: "sun.max.fill",
            highTemp: 22,
            lowTemp: 14,
            isPlaceholder: true
        )
    }

    static var preview: WeatherEntry {
        WeatherEntry(
            date: Date(),
            cityName: "San Francisco",
            temperature: 18,
            condition: "Clear",
            conditionIcon: "sun.max.fill",
            highTemp: 22,
            lowTemp: 14,
            isPlaceholder: false
        )
    }
}

// MARK: - Timeline Provider
struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        // Try to get real data for snapshot, fall back to preview
        if let weatherData = WidgetDataReader.shared.loadWeatherData() {
            let entry = WeatherEntry(from: weatherData)
            completion(entry)
        } else {
            completion(.preview)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let entry: WeatherEntry

        // Load real weather data from shared App Group storage
        if let weatherData = WidgetDataReader.shared.loadWeatherData() {
            entry = WeatherEntry(from: weatherData)
        } else {
            // No data yet - show placeholder
            entry = WeatherEntry(
                date: Date(),
                cityName: "Open App",
                temperature: 0,
                condition: "No Data",
                conditionIcon: "cloud.fill",
                highTemp: 0,
                lowTemp: 0,
                isPlaceholder: true
            )
        }

        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Theme Colors
enum WidgetTheme {
    static let teal = Color(red: 0.0, green: 0.65, blue: 0.65)
    static let darkTeal = Color(red: 0.0, green: 0.5, blue: 0.55)
    static let darkBackground = Color(red: 0.08, green: 0.12, blue: 0.16)
    static let darkCardBackground = Color(red: 0.12, green: 0.16, blue: 0.20)
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: WeatherEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.conditionIcon)
                    .font(.title2)
                    .foregroundStyle(WidgetTheme.teal)

                Spacer()
            }

            Spacer()

            Text("\(entry.temperature)°")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(colorScheme == .dark ? .white : .primary)

            Text(entry.cityName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)

            Text(entry.condition)
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [WidgetTheme.darkBackground, WidgetTheme.darkCardBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.92, blue: 0.98), Color(red: 0.90, green: 0.95, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: WeatherEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Left side - main info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.cityName)
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)

                Text("\(entry.temperature)°")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)

                Text(entry.condition)
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)

                Spacer()

                HStack(spacing: 12) {
                    Label("H: \(entry.highTemp)°", systemImage: "arrow.up")
                    Label("L: \(entry.lowTemp)°", systemImage: "arrow.down")
                }
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .secondary)
            }

            Spacer()

            // Right side - icon
            VStack {
                ZStack {
                    Circle()
                        .fill(WidgetTheme.teal.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Image(systemName: entry.conditionIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(WidgetTheme.teal)
                }

                Spacer()
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [WidgetTheme.darkBackground, WidgetTheme.darkCardBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.92, blue: 0.98), Color(red: 0.90, green: 0.95, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: WeatherEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.cityName)
                        .font(.title2.bold())
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)

                    Text(entry.condition)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(WidgetTheme.teal.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: entry.conditionIcon)
                        .font(.system(size: 28))
                        .foregroundStyle(WidgetTheme.teal)
                }
            }

            // Temperature
            HStack(alignment: .top) {
                Text("\(entry.temperature)°")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)

                Spacer()
            }

            Spacer()

            // Footer with high/low
            HStack {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                        Text("\(entry.highTemp)°")
                            .font(.subheadline.weight(.medium))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                        Text("\(entry.lowTemp)°")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)

                Spacer()

                Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : .gray.opacity(0.6))
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [WidgetTheme.darkBackground, WidgetTheme.darkCardBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.92, blue: 0.98), Color(red: 0.90, green: 0.95, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Widget Entry View
struct GlasscastWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: WeatherProvider.Entry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct GlasscastWidget: Widget {
    let kind: String = "GlasscastWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            GlasscastWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("View current weather at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    GlasscastWidget()
} timeline: {
    WeatherEntry.preview
}

#Preview("Medium", as: .systemMedium) {
    GlasscastWidget()
} timeline: {
    WeatherEntry.preview
}

#Preview("Large", as: .systemLarge) {
    GlasscastWidget()
} timeline: {
    WeatherEntry.preview
}
