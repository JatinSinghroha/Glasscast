//
//  FavoritesViewModel.swift
//  Glasscast
//

import Foundation
import SwiftUI

enum CitiesViewMode {
    case allCities      // For My Cities tab - shows all saved cities
    case favoritesOnly  // For Favorites tab - shows only favorited cities
}

@MainActor
@Observable
final class FavoritesViewModel {
    var favorites: [FavoriteCity] = []
    var isLoading = false
    var isSyncing = false
    var errorMessage: String?
    var showError = false

    private let favoritesService = FavoritesService.shared
    private let weatherService = WeatherService.shared
    private let authService = AuthService.shared

    /// The mode determines whether to load all cities or favorites only
    var viewMode: CitiesViewMode = .favoritesOnly

    var isConfigured: Bool {
        get async { await favoritesService.isConfigured }
    }

    var hasNoFavorites: Bool {
        favorites.isEmpty && !isLoading
    }

    // MARK: - Load Cities

    func loadFavorites() async {
        await loadCities(mode: viewMode)
    }

    func loadCities(mode: CitiesViewMode, forceRefresh: Bool = false) async {
        guard let userId = authService.getCurrentUserId() else {
            return
        }

        // Only show loading if we don't have data yet (cache-first UX)
        let showLoadingIndicator = favorites.isEmpty
        if showLoadingIndicator {
            isLoading = true
        }
        // Always show syncing indicator for background refresh
        isSyncing = !showLoadingIndicator && forceRefresh
        errorMessage = nil

        do {
            var loadedCities: [FavoriteCity]

            switch mode {
            case .allCities:
                loadedCities = try await favoritesService.getAllCities(userId: userId, forceRefresh: forceRefresh)
            case .favoritesOnly:
                loadedCities = try await favoritesService.getFavorites(userId: userId, forceRefresh: forceRefresh)
            }

            // Load weather for each city - always fetch fresh from network
            await withTaskGroup(of: (Int, Weather?).self) { group in
                for (index, city) in loadedCities.enumerated() {
                    group.addTask { [weatherService] in
                        do {
                            var weather = try await weatherService.fetchWeather(
                                lat: city.lat,
                                lon: city.lon
                            )

                            // Get today's actual high/low from forecast data
                            if let highLow = try? await weatherService.getTodayHighLow(
                                lat: city.lat,
                                lon: city.lon,
                                forceRefresh: true
                            ) {
                                weather = Weather(
                                    id: weather.id,
                                    cityName: weather.cityName,
                                    country: weather.country,
                                    temperature: weather.temperature,
                                    feelsLike: weather.feelsLike,
                                    tempMin: highLow.tempMin,
                                    tempMax: highLow.tempMax,
                                    humidity: weather.humidity,
                                    windSpeed: weather.windSpeed,
                                    condition: weather.condition,
                                    description: weather.description,
                                    iconCode: weather.iconCode,
                                    rainChance: weather.rainChance,
                                    timestamp: weather.timestamp
                                )
                            }

                            return (index, weather)
                        } catch {
                            return (index, nil)
                        }
                    }
                }

                for await (index, weather) in group {
                    if let weather = weather {
                        loadedCities[index].weather = weather
                    }
                }
            }

            favorites = loadedCities
        } catch is CancellationError {
            // Ignore cancellation - this is normal during navigation/refresh
        } catch {
            // Only show error if we don't have cached data
            if favorites.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        isLoading = false
        isSyncing = false
    }

    // MARK: - Toggle Favorite Status

    func toggleFavorite(_ city: FavoriteCity) async {
        let newStatus = !city.isFavorite

        // Optimistic update - update local state first for immediate UI feedback
        if let index = favorites.firstIndex(where: { $0.id == city.id }) {
            favorites[index].isFavorite = newStatus
        }

        // If in favorites-only mode and we unfavorited, remove from list
        if viewMode == .favoritesOnly && !newStatus {
            favorites.removeAll { $0.id == city.id }
        }

        // Try to persist to database (may silently fail if column doesn't exist)
        do {
            try await favoritesService.toggleFavorite(cityId: city.id, isFavorite: newStatus)
        } catch is CancellationError {
            // Ignore cancellation
        } catch {
            // Revert local state on error
            if let index = favorites.firstIndex(where: { $0.id == city.id }) {
                favorites[index].isFavorite = !newStatus
            }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Delete City (removes from both Cities and Favorites)

    func deleteCity(_ city: FavoriteCity) async {
        do {
            try await favoritesService.deleteCity(cityId: city.id)
            favorites.removeAll { $0.id == city.id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deleteFavorite(_ favorite: FavoriteCity) async {
        await deleteCity(favorite)
    }

    func deleteFavorites(at offsets: IndexSet) async {
        for index in offsets {
            let favorite = favorites[index]
            await deleteFavorite(favorite)
        }
    }

    /// Refresh data - uses forceRefresh to bypass cache
    func refresh() async {
        await loadCities(mode: viewMode, forceRefresh: true)
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
