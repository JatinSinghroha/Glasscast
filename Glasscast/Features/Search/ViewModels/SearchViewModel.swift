//
//  SearchViewModel.swift
//  Glasscast
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SearchViewModel {
    var searchText: String = "" {
        didSet {
            scheduleSearch()
        }
    }

    var searchResults: [City] = []
    var isSearching = false
    var errorMessage: String?
    var showError = false
    var showAddedToast = false
    var addedCityName: String?

    /// Set of city keys that are already added (cityName_country)
    var addedCityKeys: Set<String> = []

    /// Map of city keys to their FavoriteCity for favorite toggling
    var addedCitiesMap: [String: FavoriteCity] = [:]

    private var searchTask: Task<Void, Never>?
    private let weatherService = WeatherService.shared
    private let favoritesService = FavoritesService.shared
    private let authService = AuthService.shared
    private var favoritesManager = FavoritesManager.shared

    var isConfigured: Bool {
        get async { await weatherService.isConfigured }
    }

    var hasSearchText: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var resultCount: Int {
        searchResults.count
    }

    /// Load already added cities to track which ones to show checkmark for
    func loadAddedCities() async {
        guard let userId = authService.getCurrentUserId() else { return }

        do {
            let cities = try await favoritesService.getAllCities(userId: userId)
            addedCityKeys = Set(cities.map { cityKey(name: $0.cityName, country: $0.country) })
            addedCitiesMap = Dictionary(uniqueKeysWithValues: cities.map {
                (cityKey(name: $0.cityName, country: $0.country), $0)
            })
            // Also sync with FavoritesManager
            await favoritesManager.loadCities()
        } catch {
            // Silently fail - just won't show checkmarks
        }
    }

    /// Check if a city is already added
    func isCityAdded(_ city: City) -> Bool {
        addedCityKeys.contains(cityKey(name: city.name, country: city.country))
    }

    /// Check if a city is a favorite
    func isCityFavorite(_ city: City) -> Bool {
        let key = cityKey(name: city.name, country: city.country)
        guard let favoriteCity = addedCitiesMap[key] else { return false }
        return favoritesManager.isFavorite(favoriteCity.id)
    }

    /// Get the FavoriteCity for a City
    func getFavoriteCity(_ city: City) -> FavoriteCity? {
        let key = cityKey(name: city.name, country: city.country)
        return addedCitiesMap[key]
    }

    /// Toggle favorite status for a city
    func toggleFavorite(_ city: City) async {
        guard let favoriteCity = getFavoriteCity(city) else { return }
        await favoritesManager.toggleFavorite(favoriteCity)
    }

    private func cityKey(name: String, country: String?) -> String {
        "\(name)_\(country ?? "")"
    }

    private func scheduleSearch() {
        // Cancel any existing search task
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        // Create new debounced search task
        searchTask = Task {
            // 500ms debounce
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                // Task was cancelled during sleep - this is expected
                return
            }

            // Check if task was cancelled
            guard !Task.isCancelled else { return }

            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        guard !Task.isCancelled else { return }

        errorMessage = nil

        do {
            let results = try await weatherService.searchCities(query: query)

            // Check cancellation after async call
            guard !Task.isCancelled else { return }

            searchResults = results
        } catch is CancellationError {
            // Silently handle cancellation - this is expected behavior
            return
        } catch {
            // Only show error if not cancelled
            guard !Task.isCancelled else { return }

            // Don't show "cancelled" errors to user
            let errorString = error.localizedDescription.lowercased()
            if !errorString.contains("cancel") {
                errorMessage = error.localizedDescription
                showError = true
            }
            searchResults = []
        }

        isSearching = false
    }

    func addToMyCities(_ city: City) async {
        guard let userId = authService.getCurrentUserId() else {
            errorMessage = "Please sign in to add cities"
            showError = true
            return
        }

        do {
            let addedCity = try await favoritesService.addCity(userId: userId, city: city)

            // Add to local tracking set and map
            let key = cityKey(name: city.name, country: city.country)
            addedCityKeys.insert(key)
            addedCitiesMap[key] = addedCity

            // Update FavoritesManager
            favoritesManager.addCity(addedCity)

            addedCityName = city.name
            showAddedToast = true

            Task {
                try? await Task.sleep(for: .seconds(2))
                showAddedToast = false
            }
        } catch let error as FavoritesError {
            if case .alreadyExists = error {
                // Also add to tracking set in case it wasn't there
                addedCityKeys.insert(cityKey(name: city.name, country: city.country))
                errorMessage = "\(city.name) is already in your cities"
            } else {
                errorMessage = error.localizedDescription
            }
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // Legacy method for backwards compatibility
    func addToFavorites(_ city: City) async {
        await addToMyCities(city)
    }

    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        searchResults = []
        isSearching = false
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
