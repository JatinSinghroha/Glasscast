//
//  SharedWeatherData.swift
//  GlasscastWidgets
//
//  Shared data structures for widget weather display
//  This file should be added to BOTH the main app target AND the widget target

import Foundation

/// Shared data structure for widget weather display
struct WidgetWeatherData: Codable {
    let cityName: String
    let temperature: Double
    let tempMin: Double
    let tempMax: Double
    let condition: String
    let conditionIcon: String
    let updatedAt: Date

    /// Default placeholder data
    static var placeholder: WidgetWeatherData {
        WidgetWeatherData(
            cityName: "San Francisco",
            temperature: 18,
            tempMin: 14,
            tempMax: 22,
            condition: "Clear",
            conditionIcon: "sun.max.fill",
            updatedAt: Date()
        )
    }
}

/// Reads shared weather data from App Group UserDefaults
/// Used by the widget to get weather data saved by the main app
final class WidgetDataReader {
    static let shared = WidgetDataReader()

    // IMPORTANT: This must match the App Group identifier in the main app
    private let appGroupIdentifier = "group.com.glasscast.shared"
    private let weatherDataKey = "widgetWeatherData"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    /// Load weather data saved by the main app
    func loadWeatherData() -> WidgetWeatherData? {
        guard let sharedDefaults = sharedDefaults else {
            print("WidgetDataReader: App Group not configured")
            return nil
        }

        guard let data = sharedDefaults.data(forKey: weatherDataKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetWeatherData.self, from: data)
        } catch {
            print("WidgetDataReader: Failed to decode weather data - \(error)")
            return nil
        }
    }
}
