//
//  CacheService.swift
//  Glasscast
//

import Foundation

actor CacheService {
    static let shared = CacheService()

    // Cache expiration times
    private let weatherCacheExpiration: TimeInterval = 10 * 60  // 10 minutes
    private let forecastCacheExpiration: TimeInterval = 30 * 60 // 30 minutes
    private let citiesCacheExpiration: TimeInterval = 60 * 60   // 1 hour

    // In-memory cache
    private var weatherCache: [String: CacheEntry<Weather>] = [:]
    private var forecastCache: [String: CacheEntry<[Forecast]>] = [:]
    private var citiesCache: CacheEntry<[FavoriteCity]>?

    // UserDefaults keys
    private let weatherCacheKey = "cached_weather"
    private let forecastCacheKey = "cached_forecast"
    private let citiesCacheKey = "cached_cities"

    private init() {
        loadFromDisk()
    }

    // MARK: - Weather Cache

    func getCachedWeather(lat: Double, lon: Double) -> Weather? {
        let key = weatherKey(lat: lat, lon: lon)
        guard let entry = weatherCache[key],
              !entry.isExpired(expiration: weatherCacheExpiration) else {
            return nil
        }
        return entry.data
    }

    func cacheWeather(_ weather: Weather, lat: Double, lon: Double) {
        let key = weatherKey(lat: lat, lon: lon)
        weatherCache[key] = CacheEntry(data: weather, timestamp: Date())
        saveToDisk()
    }

    // MARK: - Forecast Cache

    func getCachedForecast(lat: Double, lon: Double) -> [Forecast]? {
        let key = weatherKey(lat: lat, lon: lon)
        guard let entry = forecastCache[key],
              !entry.isExpired(expiration: forecastCacheExpiration) else {
            return nil
        }
        return entry.data
    }

    func cacheForecast(_ forecast: [Forecast], lat: Double, lon: Double) {
        let key = weatherKey(lat: lat, lon: lon)
        forecastCache[key] = CacheEntry(data: forecast, timestamp: Date())
        saveToDisk()
    }

    // MARK: - Cities Cache

    func getCachedCities() -> [FavoriteCity]? {
        guard let entry = citiesCache,
              !entry.isExpired(expiration: citiesCacheExpiration) else {
            return nil
        }
        return entry.data
    }

    func cacheCities(_ cities: [FavoriteCity]) {
        citiesCache = CacheEntry(data: cities, timestamp: Date())
        saveToDisk()
    }

    func invalidateCitiesCache() {
        citiesCache = nil
        saveToDisk()
    }

    // MARK: - Clear All Cache

    func clearAll() {
        weatherCache.removeAll()
        forecastCache.removeAll()
        citiesCache = nil

        UserDefaults.standard.removeObject(forKey: weatherCacheKey)
        UserDefaults.standard.removeObject(forKey: forecastCacheKey)
        UserDefaults.standard.removeObject(forKey: citiesCacheKey)
    }

    // MARK: - Private Helpers

    private func weatherKey(lat: Double, lon: Double) -> String {
        return "\(String(format: "%.2f", lat)),\(String(format: "%.2f", lon))"
    }

    private func loadFromDisk() {
        // Load weather cache
        if let data = UserDefaults.standard.data(forKey: weatherCacheKey),
           let decoded = try? JSONDecoder().decode([String: CacheEntry<Weather>].self, from: data) {
            weatherCache = decoded
        }

        // Load forecast cache
        if let data = UserDefaults.standard.data(forKey: forecastCacheKey),
           let decoded = try? JSONDecoder().decode([String: CacheEntry<[Forecast]>].self, from: data) {
            forecastCache = decoded
        }

        // Load cities cache
        if let data = UserDefaults.standard.data(forKey: citiesCacheKey),
           let decoded = try? JSONDecoder().decode(CacheEntry<[FavoriteCity]>.self, from: data) {
            citiesCache = decoded
        }
    }

    private func saveToDisk() {
        // Save weather cache
        if let encoded = try? JSONEncoder().encode(weatherCache) {
            UserDefaults.standard.set(encoded, forKey: weatherCacheKey)
        }

        // Save forecast cache
        if let encoded = try? JSONEncoder().encode(forecastCache) {
            UserDefaults.standard.set(encoded, forKey: forecastCacheKey)
        }

        // Save cities cache
        if let citiesCache = citiesCache,
           let encoded = try? JSONEncoder().encode(citiesCache) {
            UserDefaults.standard.set(encoded, forKey: citiesCacheKey)
        } else {
            UserDefaults.standard.removeObject(forKey: citiesCacheKey)
        }
    }
}

// MARK: - Cache Entry

struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date

    func isExpired(expiration: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > expiration
    }
}
