//
//  FavoritesManager.swift
//  Glasscast
//

import Foundation
import SwiftUI

/// Shared manager for syncing favorite status across all views
@MainActor
@Observable
final class FavoritesManager {
    static let shared = FavoritesManager()

    /// All user's cities with their favorite status
    private(set) var cities: [FavoriteCity] = []

    /// Set of city IDs that are favorites
    private(set) var favoriteIds: Set<UUID> = []

    /// Set of city IDs currently being toggled (to prevent race conditions)
    private(set) var togglingIds: Set<UUID> = []

    /// Loading state
    var isLoading = false

    private let favoritesService = FavoritesService.shared
    private let authService = AuthService.shared

    private init() {}

    /// Check if a city is currently being toggled
    func isToggling(_ cityId: UUID) -> Bool {
        togglingIds.contains(cityId)
    }

    // MARK: - Public Methods

    /// Load all cities from the service
    func loadCities(forceRefresh: Bool = false) async {
        guard let userId = authService.getCurrentUserId() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            cities = try await favoritesService.getAllCities(userId: userId, forceRefresh: forceRefresh)
            updateFavoriteIds()
        } catch {
            // Silently fail - views have their own error handling
        }
    }

    /// Check if a city is a favorite
    func isFavorite(_ cityId: UUID) -> Bool {
        favoriteIds.contains(cityId)
    }

    /// Check if a city is a favorite by name and country
    func isFavorite(cityName: String, country: String?) -> Bool {
        cities.contains { $0.cityName == cityName && $0.country == country && $0.isFavorite }
    }

    /// Toggle favorite status with smooth animation
    func toggleFavorite(_ city: FavoriteCity) async {
        // Prevent race conditions - ignore if already toggling this city
        guard !togglingIds.contains(city.id) else { return }

        // Get current state from our array (not the passed city which might be stale)
        guard let index = cities.firstIndex(where: { $0.id == city.id }) else { return }
        let currentStatus = cities[index].isFavorite
        let newStatus = !currentStatus

        // Mark as toggling
        togglingIds.insert(city.id)

        // Optimistic update with animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cities[index].isFavorite = newStatus
            updateFavoriteIds()
        }

        // Persist to database
        do {
            try await favoritesService.toggleFavorite(cityId: city.id, isFavorite: newStatus)
        } catch {
            // Revert on error with animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if let idx = cities.firstIndex(where: { $0.id == city.id }) {
                    cities[idx].isFavorite = currentStatus
                }
                updateFavoriteIds()
            }
        }

        // Mark as done toggling
        togglingIds.remove(city.id)
    }

    /// Toggle favorite by city ID
    func toggleFavorite(cityId: UUID) async {
        guard let city = cities.first(where: { $0.id == cityId }) else { return }
        await toggleFavorite(city)
    }

    /// Get city by ID
    func getCity(_ cityId: UUID) -> FavoriteCity? {
        cities.first { $0.id == cityId }
    }

    /// Get all favorites
    var favorites: [FavoriteCity] {
        cities.filter { $0.isFavorite }
    }

    /// Add a new city (called after search add)
    func addCity(_ city: FavoriteCity) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if !cities.contains(where: { $0.id == city.id }) {
                cities.insert(city, at: 0)
            }
            updateFavoriteIds()
        }
    }

    /// Remove a city
    func removeCity(_ cityId: UUID) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cities.removeAll { $0.id == cityId }
            updateFavoriteIds()
        }
    }

    /// Invalidate and reload
    func refresh() async {
        await loadCities(forceRefresh: true)
    }

    /// Clear all data (used when user signs out or changes)
    func clearAllData() {
        cities = []
        favoriteIds = []
        togglingIds = []
    }

    // MARK: - Private Methods

    private func updateFavoriteIds() {
        favoriteIds = Set(cities.filter { $0.isFavorite }.map { $0.id })
    }
}
