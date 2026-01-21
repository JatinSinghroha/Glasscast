//
//  TemperatureFormatter.swift
//  Glasscast
//

import Foundation
import SwiftUI

/// Formats temperatures based on user preference (Celsius or Fahrenheit)
@MainActor
@Observable
final class TemperatureFormatter {
    static let shared = TemperatureFormatter()

    var unit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(unit.rawValue, forKey: "temperatureUnit")
        }
    }

    private init() {
        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit")
        unit = TemperatureUnit(rawValue: savedUnit ?? "") ?? .celsius
    }

    /// Convert Celsius to user's preferred unit
    func convert(_ celsius: Double) -> Double {
        switch unit {
        case .celsius:
            return celsius
        case .fahrenheit:
            return celsius * 9 / 5 + 32
        }
    }

    /// Format temperature with unit symbol
    func format(_ celsius: Double, showUnit: Bool = false) -> String {
        let converted = convert(celsius)
        let rounded = Int(round(converted))
        if showUnit {
            return "\(rounded)°\(unit.symbol)"
        }
        return "\(rounded)°"
    }

    /// Format temperature without degree symbol (for custom formatting)
    func formatValue(_ celsius: Double) -> String {
        let converted = convert(celsius)
        return "\(Int(round(converted)))"
    }

    /// Unit symbol (°C or °F)
    var unitSymbol: String {
        "°\(unit.symbol)"
    }
}

// Extension to move TemperatureUnit to a shared location
extension TemperatureUnit {
    /// Convert Celsius to this unit
    func convert(_ celsius: Double) -> Double {
        switch self {
        case .celsius:
            return celsius
        case .fahrenheit:
            return celsius * 9 / 5 + 32
        }
    }

    /// Format temperature in this unit
    func format(_ celsius: Double) -> String {
        let converted = convert(celsius)
        return "\(Int(round(converted)))°"
    }
}
