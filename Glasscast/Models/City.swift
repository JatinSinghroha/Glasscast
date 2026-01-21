//
//  City.swift
//  Glasscast
//

import Foundation

struct City: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let country: String
    let state: String?
    let lat: Double
    let lon: Double

    var displayName: String {
        if let state = state, !state.isEmpty {
            return "\(name), \(state), \(country)"
        }
        return "\(name), \(country)"
    }

    var shortDisplayName: String {
        "\(name), \(country)"
    }
}

// MARK: - OpenWeatherMap Geocoding API Response

struct GeocodingResponse: Codable {
    let name: String
    let localNames: [String: String]?
    let lat: Double
    let lon: Double
    let country: String
    let state: String?

    enum CodingKeys: String, CodingKey {
        case name
        case localNames = "local_names"
        case lat
        case lon
        case country
        case state
    }
}

extension City {
    static func from(response: GeocodingResponse) -> City {
        City(
            name: response.name,
            country: response.country,
            state: response.state,
            lat: response.lat,
            lon: response.lon
        )
    }
}
