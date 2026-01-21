//
//  WeatherService.swift
//  Glasscast
//

import Foundation

enum WeatherError: Error, LocalizedError {
    case notConfigured
    case invalidCity
    case fetchFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Weather API not configured. Please check your Config.xcconfig file."
        case .invalidCity:
            return "Invalid city"
        case .fetchFailed(let error):
            return "Failed to fetch weather: \(error.localizedDescription)"
        case .noData:
            return "No weather data available"
        }
    }
}

actor WeatherService {
    static let shared = WeatherService()

    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let geoURL = "https://api.openweathermap.org/geo/1.0"
    private let cache = CacheService.shared

    private init() {}

    var isConfigured: Bool {
        !AppConfig.openWeatherMapAPIKey.isEmpty
    }

    // MARK: - Cache-only access (instant, no network)

    func getCachedWeather(lat: Double, lon: Double) async -> Weather? {
        await cache.getCachedWeather(lat: lat, lon: lon)
    }

    func getCachedForecast(lat: Double, lon: Double) async -> [Forecast]? {
        await cache.getCachedForecast(lat: lat, lon: lon)
    }

    // MARK: - Network fetch (always hits network, updates cache)

    func fetchWeather(lat: Double, lon: Double, units: String = "metric") async throws -> Weather {
        guard isConfigured else {
            throw WeatherError.notConfigured
        }

        let apiKey = AppConfig.openWeatherMapAPIKey
        let urlString = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&units=\(units)&appid=\(apiKey)"

        do {
            let response: OpenWeatherResponse = try await NetworkManager.shared.fetch(urlString: urlString)
            let weather = Weather.from(response: response)

            // Cache the result
            await cache.cacheWeather(weather, lat: lat, lon: lon)

            return weather
        } catch {
            // If network fails, try to return cached data (even if expired)
            if let cached = await cache.getCachedWeather(lat: lat, lon: lon) {
                return cached
            }
            throw WeatherError.fetchFailed(error)
        }
    }

    func fetchForecast(lat: Double, lon: Double, units: String = "metric") async throws -> [Forecast] {
        guard isConfigured else {
            throw WeatherError.notConfigured
        }

        let apiKey = AppConfig.openWeatherMapAPIKey
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&units=\(units)&appid=\(apiKey)"

        do {
            let response: OpenWeatherForecastResponse = try await NetworkManager.shared.fetch(urlString: urlString)
            let forecast = processForecastResponse(response)

            // Cache the result
            await cache.cacheForecast(forecast, lat: lat, lon: lon)

            return forecast
        } catch {
            // If network fails, try to return cached data (even if expired)
            if let cached = await cache.getCachedForecast(lat: lat, lon: lon) {
                return cached
            }
            throw WeatherError.fetchFailed(error)
        }
    }

    // MARK: - Legacy methods (for compatibility)

    func getCurrentWeather(lat: Double, lon: Double, units: String = "metric", forceRefresh: Bool = false) async throws -> Weather {
        // Always fetch fresh data now
        return try await fetchWeather(lat: lat, lon: lon, units: units)
    }

    func getCurrentWeather(cityName: String, units: String = "metric") async throws -> Weather {
        guard isConfigured else {
            throw WeatherError.notConfigured
        }

        let apiKey = AppConfig.openWeatherMapAPIKey
        let encodedCity = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cityName
        let urlString = "\(baseURL)/weather?q=\(encodedCity)&units=\(units)&appid=\(apiKey)"

        do {
            let response: OpenWeatherResponse = try await NetworkManager.shared.fetch(urlString: urlString)
            return Weather.from(response: response)
        } catch {
            throw WeatherError.fetchFailed(error)
        }
    }

    func getForecast(lat: Double, lon: Double, units: String = "metric", forceRefresh: Bool = false) async throws -> [Forecast] {
        // Always fetch fresh data now
        return try await fetchForecast(lat: lat, lon: lon, units: units)
    }

    func searchCities(query: String, limit: Int = 5) async throws -> [City] {
        guard isConfigured else {
            throw WeatherError.notConfigured
        }

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let apiKey = AppConfig.openWeatherMapAPIKey
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(geoURL)/direct?q=\(encodedQuery)&limit=\(limit)&appid=\(apiKey)"

        do {
            let responses: [GeocodingResponse] = try await NetworkManager.shared.fetch(urlString: urlString)
            return responses.map { City.from(response: $0) }
        } catch {
            throw WeatherError.fetchFailed(error)
        }
    }

    private func processForecastResponse(_ response: OpenWeatherForecastResponse) -> [Forecast] {
        let calendar = Calendar.current

        var dailyForecasts: [Date: [OpenWeatherForecastResponse.ForecastItem]] = [:]

        for item in response.list {
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            let dayStart = calendar.startOfDay(for: date)

            if dailyForecasts[dayStart] == nil {
                dailyForecasts[dayStart] = []
            }
            dailyForecasts[dayStart]?.append(item)
        }

        let sortedDays = dailyForecasts.keys.sorted()
        let today = calendar.startOfDay(for: Date())

        return sortedDays
            .filter { $0 > today }
            .prefix(5)
            .compactMap { day -> Forecast? in
                guard let items = dailyForecasts[day], !items.isEmpty else { return nil }

                let tempMin = items.map { $0.main.tempMin }.min() ?? 0
                let tempMax = items.map { $0.main.tempMax }.max() ?? 0
                let maxPop = items.map { $0.pop }.max() ?? 0

                let middayItem = items.first { item in
                    let hour = calendar.component(.hour, from: Date(timeIntervalSince1970: TimeInterval(item.dt)))
                    return hour >= 11 && hour <= 14
                } ?? items[items.count / 2]

                let weatherInfo = middayItem.weather.first

                return Forecast(
                    date: day,
                    tempMin: tempMin,
                    tempMax: tempMax,
                    condition: WeatherCondition.from(apiCondition: weatherInfo?.main ?? "Unknown"),
                    iconCode: weatherInfo?.icon ?? "",
                    rainChance: Int(maxPop * 100)
                )
            }
    }

    /// Get today's daily high/low from forecast data
    func getTodayHighLow(lat: Double, lon: Double, forceRefresh: Bool = false) async throws -> (tempMin: Double, tempMax: Double)? {
        // Check cache first (unless force refresh)
        if !forceRefresh, let cached = await cache.getCachedForecast(lat: lat, lon: lon) {
            // We still need to process today from the raw response
        }

        guard isConfigured else {
            throw WeatherError.notConfigured
        }

        let apiKey = AppConfig.openWeatherMapAPIKey
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&units=metric&appid=\(apiKey)"

        do {
            let response: OpenWeatherForecastResponse = try await NetworkManager.shared.fetch(urlString: urlString)
            return processTodayHighLow(response)
        } catch {
            return nil
        }
    }

    /// Extract today's high/low from forecast response
    private func processTodayHighLow(_ response: OpenWeatherForecastResponse) -> (tempMin: Double, tempMax: Double)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get all forecast items for today
        let todayItems = response.list.filter { item in
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            return calendar.startOfDay(for: date) == today
        }

        guard !todayItems.isEmpty else { return nil }

        let tempMin = todayItems.map { $0.main.tempMin }.min() ?? 0
        let tempMax = todayItems.map { $0.main.tempMax }.max() ?? 0

        return (tempMin, tempMax)
    }
}
