//
//  FavoriteCity.swift
//  Glasscast
//

import Foundation

/// Represents a saved city in the user's list
/// - Cities are added from Search
/// - Cities can be marked as favorites (isFavorite = true)
struct FavoriteCity: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let userId: UUID
    let cityName: String
    let country: String?
    let lat: Double
    let lon: Double
    let createdAt: Date
    var isFavorite: Bool

    var weather: Weather?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cityName = "city_name"
        case country
        case lat
        case lon
        case createdAt = "created_at"
        case isFavorite = "is_favorite"
    }

    init(id: UUID = UUID(), userId: UUID, cityName: String, country: String?, lat: Double, lon: Double, createdAt: Date = Date(), isFavorite: Bool = false, weather: Weather? = nil) {
        self.id = id
        self.userId = userId
        self.cityName = cityName
        self.country = country
        self.lat = lat
        self.lon = lon
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.weather = weather
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        cityName = try container.decode(String.self, forKey: .cityName)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        // Default to true if column doesn't exist (backwards compatibility)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? true
        weather = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(cityName, forKey: .cityName)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encode(lat, forKey: .lat)
        try container.encode(lon, forKey: .lon)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isFavorite, forKey: .isFavorite)
    }

    static func == (lhs: FavoriteCity, rhs: FavoriteCity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Insert model without is_favorite to support databases without the column
struct InsertFavoriteCity: Codable {
    let userId: UUID
    let cityName: String
    let country: String?
    let lat: Double
    let lon: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cityName = "city_name"
        case country
        case lat
        case lon
    }

    init(userId: UUID, cityName: String, country: String?, lat: Double, lon: Double) {
        self.userId = userId
        self.cityName = cityName
        self.country = country
        self.lat = lat
        self.lon = lon
    }
}

/// Insert model with is_favorite for databases that have the column
struct InsertFavoriteCityWithFlag: Codable {
    let userId: UUID
    let cityName: String
    let country: String?
    let lat: Double
    let lon: Double
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cityName = "city_name"
        case country
        case lat
        case lon
        case isFavorite = "is_favorite"
    }

    init(userId: UUID, cityName: String, country: String?, lat: Double, lon: Double, isFavorite: Bool = false) {
        self.userId = userId
        self.cityName = cityName
        self.country = country
        self.lat = lat
        self.lon = lon
        self.isFavorite = isFavorite
    }
}
