//
//  HomeViewModel.swift
//  Glasscast
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    var weather: Weather?
    var forecast: [Forecast] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private(set) var currentCity: FavoriteCity?
    private let weatherService = WeatherService.shared

    var isConfigured: Bool {
        get async { await weatherService.isConfigured }
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    var cityDisplayName: String {
        guard let weather = weather else {
            return currentCity?.cityName ?? "Unknown"
        }
        if weather.country.isEmpty {
            return weather.cityName
        }
        return "\(weather.cityName), \(weather.country)"
    }

    func loadWeather(for city: FavoriteCity, forceRefresh: Bool = false) async {
        currentCity = city
        errorMessage = nil

        // Step 1: Load cached data first for instant display (if no data yet)
        if weather == nil {
            if let cachedWeather = await weatherService.getCachedWeather(lat: city.lat, lon: city.lon) {
                weather = cachedWeather
            }
            if let cachedForecast = await weatherService.getCachedForecast(lat: city.lat, lon: city.lon) {
                forecast = cachedForecast
            }
        }

        // Show loading only if we still don't have any data
        let showLoadingIndicator = weather == nil
        if showLoadingIndicator {
            isLoading = true
        }

        // Step 2: Always fetch fresh data from network
        do {
            async let weatherTask = weatherService.fetchWeather(lat: city.lat, lon: city.lon)
            async let forecastTask = weatherService.fetchForecast(lat: city.lat, lon: city.lon)
            async let todayHighLowTask = weatherService.getTodayHighLow(lat: city.lat, lon: city.lon, forceRefresh: true)

            let (weatherResult, forecastResult, todayHighLow) = try await (weatherTask, forecastTask, todayHighLowTask)

            // Apply today's actual high/low from forecast data
            var updatedWeather = weatherResult
            if let highLow = todayHighLow {
                updatedWeather = Weather(
                    id: weatherResult.id,
                    cityName: weatherResult.cityName,
                    country: weatherResult.country,
                    temperature: weatherResult.temperature,
                    feelsLike: weatherResult.feelsLike,
                    tempMin: highLow.tempMin,
                    tempMax: highLow.tempMax,
                    humidity: weatherResult.humidity,
                    windSpeed: weatherResult.windSpeed,
                    condition: weatherResult.condition,
                    description: weatherResult.description,
                    iconCode: weatherResult.iconCode,
                    rainChance: weatherResult.rainChance,
                    timestamp: weatherResult.timestamp
                )
            }

            weather = updatedWeather
            forecast = forecastResult

            // Save to widget shared storage
            SharedDataManager.shared.saveWeatherForWidget(updatedWeather, cityName: city.cityName)
        } catch is CancellationError {
            // Ignore cancellation - this is normal during navigation/refresh
        } catch {
            // Only show error if we don't have any data to display
            if weather == nil {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        isLoading = false
    }

    func loadWeather(lat: Double, lon: Double, forceRefresh: Bool = false) async {
        errorMessage = nil

        // Step 1: Load cached data first for instant display
        if weather == nil {
            if let cachedWeather = await weatherService.getCachedWeather(lat: lat, lon: lon) {
                weather = cachedWeather
            }
            if let cachedForecast = await weatherService.getCachedForecast(lat: lat, lon: lon) {
                forecast = cachedForecast
            }
        }

        // Show loading only if we still don't have any data
        let showLoadingIndicator = weather == nil
        if showLoadingIndicator {
            isLoading = true
        }

        // Step 2: Always fetch fresh data from network
        do {
            async let weatherTask = weatherService.fetchWeather(lat: lat, lon: lon)
            async let forecastTask = weatherService.fetchForecast(lat: lat, lon: lon)
            async let todayHighLowTask = weatherService.getTodayHighLow(lat: lat, lon: lon, forceRefresh: true)

            let (weatherResult, forecastResult, todayHighLow) = try await (weatherTask, forecastTask, todayHighLowTask)

            // Apply today's actual high/low from forecast data
            var updatedWeather = weatherResult
            if let highLow = todayHighLow {
                updatedWeather = Weather(
                    id: weatherResult.id,
                    cityName: weatherResult.cityName,
                    country: weatherResult.country,
                    temperature: weatherResult.temperature,
                    feelsLike: weatherResult.feelsLike,
                    tempMin: highLow.tempMin,
                    tempMax: highLow.tempMax,
                    humidity: weatherResult.humidity,
                    windSpeed: weatherResult.windSpeed,
                    condition: weatherResult.condition,
                    description: weatherResult.description,
                    iconCode: weatherResult.iconCode,
                    rainChance: weatherResult.rainChance,
                    timestamp: weatherResult.timestamp
                )
            }

            weather = updatedWeather
            forecast = forecastResult
        } catch is CancellationError {
            // Ignore cancellation - this is normal during navigation/refresh
        } catch {
            // Only show error if we don't have any data to display
            if weather == nil {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        isLoading = false
    }

    /// Refresh forces a cache bypass
    func refresh() async {
        if let city = currentCity {
            await loadWeather(for: city, forceRefresh: true)
        }
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
