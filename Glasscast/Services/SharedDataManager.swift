//
//  SharedDataManager.swift
//  Glasscast
//
//  Manages shared data between the main app and widgets via App Group

import Foundation
import WidgetKit

/// Shared data structure for widget weather display
struct WidgetWeatherData: Codable {
    let cityName: String
    let temperature: Double
    let tempMin: Double
    let tempMax: Double
    let condition: String
    let conditionIcon: String
    let updatedAt: Date

    /// Convert Weather model to WidgetWeatherData
    init(from weather: Weather, cityName: String) {
        self.cityName = cityName
        self.temperature = weather.temperature
        self.tempMin = weather.tempMin
        self.tempMax = weather.tempMax
        self.condition = weather.condition.rawValue
        self.conditionIcon = weather.condition.iconName
        self.updatedAt = Date()
    }

    init(cityName: String, temperature: Double, tempMin: Double, tempMax: Double, condition: String, conditionIcon: String, updatedAt: Date) {
        self.cityName = cityName
        self.temperature = temperature
        self.tempMin = tempMin
        self.tempMax = tempMax
        self.condition = condition
        self.conditionIcon = conditionIcon
        self.updatedAt = updatedAt
    }
}

/// Manager for sharing data between main app and widgets
final class SharedDataManager {
    static let shared = SharedDataManager()

    // IMPORTANT: Update this to match your App Group identifier
    // Format: group.com.yourteam.glasscast
    private let appGroupIdentifier = "group.com.glasscast.shared"
    private let weatherDataKey = "widgetWeatherData"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Save Weather Data

    /// Save weather data for widget display
    func saveWeatherForWidget(_ weather: Weather, cityName: String) {
        let widgetData = WidgetWeatherData(from: weather, cityName: cityName)
        saveWidgetData(widgetData)
    }

    /// Save widget data to shared UserDefaults
    private func saveWidgetData(_ data: WidgetWeatherData) {
        guard let sharedDefaults = sharedDefaults else {
            print("SharedDataManager: App Group not configured")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            sharedDefaults.set(encoded, forKey: weatherDataKey)
            sharedDefaults.synchronize()

            // Trigger widget refresh
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("SharedDataManager: Failed to encode weather data - \(error)")
        }
    }

    // MARK: - Load Weather Data

    /// Load weather data for widget display
    func loadWeatherForWidget() -> WidgetWeatherData? {
        guard let sharedDefaults = sharedDefaults else {
            print("SharedDataManager: App Group not configured")
            return nil
        }

        guard let data = sharedDefaults.data(forKey: weatherDataKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetWeatherData.self, from: data)
        } catch {
            print("SharedDataManager: Failed to decode weather data - \(error)")
            return nil
        }
    }

    // MARK: - Clear Data

    /// Clear all shared data (call on logout)
    func clearAll() {
        sharedDefaults?.removeObject(forKey: weatherDataKey)
        sharedDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
