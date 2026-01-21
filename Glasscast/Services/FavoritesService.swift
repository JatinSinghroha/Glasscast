//
//  FavoritesService.swift
//  Glasscast
//

import Foundation
import Supabase

enum FavoritesError: Error, LocalizedError {
    case notConfigured
    case notAuthenticated
    case fetchFailed(Error)
    case addFailed(Error)
    case deleteFailed(Error)
    case updateFailed(Error)
    case alreadyExists
    case notInCities

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please check your Config.xcconfig file."
        case .notAuthenticated:
            return "Please sign in to manage cities."
        case .fetchFailed(let error):
            return "Failed to fetch cities: \(error.localizedDescription)"
        case .addFailed(let error):
            return "Failed to add city: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete city: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update city: \(error.localizedDescription)"
        case .alreadyExists:
            return "This city is already in your list."
        case .notInCities:
            return "City must be added to My Cities first before favoriting."
        }
    }
}

actor FavoritesService {
    static let shared = FavoritesService()

    private var supabase: SupabaseClient?
    private let tableName = "favorite_cities"
    private let cache = CacheService.shared

    private init() {
        setupSupabase()
    }

    private func setupSupabase() {
        let url = AppConfig.supabaseURL
        let key = AppConfig.supabaseAnonKey

        guard !url.isEmpty,
              !key.isEmpty,
              let supabaseURL = URL(string: url),
              let host = supabaseURL.host,
              host.contains(".supabase.co") else {
            return
        }

        supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
    }

    var isConfigured: Bool {
        supabase != nil
    }

    // MARK: - Get All Cities (for My Cities tab)

    func getAllCities(userId: UUID, forceRefresh: Bool = false) async throws -> [FavoriteCity] {
        // Check cache first (unless force refresh)
        if !forceRefresh, let cached = await cache.getCachedCities() {
            return cached
        }

        guard let supabase = supabase else {
            throw FavoritesError.notConfigured
        }

        do {
            let cities: [FavoriteCity] = try await supabase
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            // Cache the result
            await cache.cacheCities(cities)

            return cities
        } catch {
            // If network fails, try to return cached data (even if expired)
            if let cached = await cache.getCachedCities() {
                return cached
            }
            throw FavoritesError.fetchFailed(error)
        }
    }

    // MARK: - Get Only Favorites (for Favorites tab)

    func getFavorites(userId: UUID, forceRefresh: Bool = false) async throws -> [FavoriteCity] {
        // Get all cities first (uses cache)
        let allCities = try await getAllCities(userId: userId, forceRefresh: forceRefresh)
        return allCities.filter { $0.isFavorite }
    }

    // MARK: - Add City (from Search - adds with isFavorite = false)

    func addCity(userId: UUID, city: City) async throws -> FavoriteCity {
        guard let supabase = supabase else {
            throw FavoritesError.notConfigured
        }

        // Check if city already exists (using cache when possible)
        let existingCities = try await getAllCities(userId: userId)
        if existingCities.contains(where: { $0.cityName == city.name && $0.country == city.country }) {
            throw FavoritesError.alreadyExists
        }

        let newCity = InsertFavoriteCity(
            userId: userId,
            cityName: city.name,
            country: city.country,
            lat: city.lat,
            lon: city.lon
        )

        do {
            let inserted: FavoriteCity = try await supabase
                .from(tableName)
                .insert(newCity)
                .select()
                .single()
                .execute()
                .value

            // Invalidate cache after modification
            await cache.invalidateCitiesCache()

            return inserted
        } catch {
            throw FavoritesError.addFailed(error)
        }
    }

    // MARK: - Legacy method for backwards compatibility

    func addFavorite(userId: UUID, city: City) async throws -> FavoriteCity {
        return try await addCity(userId: userId, city: city)
    }

    // MARK: - Toggle Favorite Status

    func toggleFavorite(cityId: UUID, isFavorite: Bool) async throws {
        guard let supabase = supabase else {
            throw FavoritesError.notConfigured
        }

        do {
            try await supabase
                .from(tableName)
                .update(["is_favorite": isFavorite])
                .eq("id", value: cityId.uuidString)
                .execute()

            // Invalidate cache after modification
            await cache.invalidateCitiesCache()
        } catch {
            // If the is_favorite column doesn't exist, silently ignore
            // The user needs to run the SQL migration to add the column
            let errorString = String(describing: error)
            if errorString.contains("is_favorite") {
                #if DEBUG
                print("FavoritesService: is_favorite column not found. Run SQL migration to add it.")
                #endif
                return
            }
            throw FavoritesError.updateFailed(error)
        }
    }

    // MARK: - Delete City (removes from both Cities and Favorites)

    func deleteCity(cityId: UUID) async throws {
        guard let supabase = supabase else {
            throw FavoritesError.notConfigured
        }

        do {
            try await supabase
                .from(tableName)
                .delete()
                .eq("id", value: cityId.uuidString)
                .execute()

            // Invalidate cache after modification
            await cache.invalidateCitiesCache()
        } catch {
            throw FavoritesError.deleteFailed(error)
        }
    }

    // MARK: - Legacy method for backwards compatibility

    func deleteFavorite(favoriteId: UUID) async throws {
        try await deleteCity(cityId: favoriteId)
    }

    // MARK: - Check if city exists

    func cityExists(userId: UUID, cityName: String, country: String?) async throws -> Bool {
        let cities = try await getAllCities(userId: userId)
        return cities.contains { $0.cityName == cityName && $0.country == country }
    }

    func isFavorite(userId: UUID, cityName: String, country: String?) async throws -> Bool {
        let favorites = try await getFavorites(userId: userId)
        return favorites.contains { $0.cityName == cityName && $0.country == country }
    }
}
