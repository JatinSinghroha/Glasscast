//
//  Weather.swift
//  Glasscast
//

import Foundation

struct Weather: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    let cityName: String
    let country: String
    let temperature: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let humidity: Int
    let windSpeed: Double
    let condition: WeatherCondition
    let description: String
    let iconCode: String
    let rainChance: Int
    let timestamp: Date

    init(
        id: UUID = UUID(),
        cityName: String,
        country: String,
        temperature: Double,
        feelsLike: Double,
        tempMin: Double,
        tempMax: Double,
        humidity: Int,
        windSpeed: Double,
        condition: WeatherCondition,
        description: String,
        iconCode: String,
        rainChance: Int,
        timestamp: Date
    ) {
        self.id = id
        self.cityName = cityName
        self.country = country
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.tempMin = tempMin
        self.tempMax = tempMax
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.condition = condition
        self.description = description
        self.iconCode = iconCode
        self.rainChance = rainChance
        self.timestamp = timestamp
    }

    var temperatureFormatted: String {
        "\(Int(round(temperature)))"
    }

    var tempMinFormatted: String {
        "\(Int(round(tempMin)))"
    }

    var tempMaxFormatted: String {
        "\(Int(round(tempMax)))"
    }

    var windSpeedFormatted: String {
        "\(Int(round(windSpeed))) km/h"
    }

    var rainChanceFormatted: String {
        "\(rainChance)%"
    }

    /// Placeholder for redacted loading state
    static var placeholder: Weather {
        Weather(
            cityName: "Loading City",
            country: "XX",
            temperature: 20,
            feelsLike: 18,
            tempMin: 15,
            tempMax: 25,
            humidity: 50,
            windSpeed: 10,
            condition: .clear,
            description: "Loading...",
            iconCode: "01d",
            rainChance: 0,
            timestamp: Date()
        )
    }
}

enum WeatherCondition: String, Equatable, Hashable, Codable {
    case clear = "Clear"
    case clouds = "Clouds"
    case rain = "Rain"
    case drizzle = "Drizzle"
    case thunderstorm = "Thunderstorm"
    case snow = "Snow"
    case mist = "Mist"
    case fog = "Fog"
    case haze = "Haze"
    case dust = "Dust"
    case smoke = "Smoke"
    case unknown = "Unknown"

    var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .clouds: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .mist, .fog, .haze: return "cloud.fog.fill"
        case .dust, .smoke: return "sun.haze.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    static func from(apiCondition: String) -> WeatherCondition {
        WeatherCondition(rawValue: apiCondition) ?? .unknown
    }
}

struct Forecast: Identifiable, Equatable, Codable {
    var id: UUID
    let date: Date
    let tempMin: Double
    let tempMax: Double
    let condition: WeatherCondition
    let iconCode: String
    let rainChance: Int

    init(
        id: UUID = UUID(),
        date: Date,
        tempMin: Double,
        tempMax: Double,
        condition: WeatherCondition,
        iconCode: String,
        rainChance: Int
    ) {
        self.id = id
        self.date = date
        self.tempMin = tempMin
        self.tempMax = tempMax
        self.condition = condition
        self.iconCode = iconCode
        self.rainChance = rainChance
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var tempMinFormatted: String {
        "\(Int(round(tempMin)))"
    }

    var tempMaxFormatted: String {
        "\(Int(round(tempMax)))"
    }

    /// Placeholder forecasts for redacted loading state
    static var placeholders: [Forecast] {
        let calendar = Calendar.current
        return (1...5).map { dayOffset in
            Forecast(
                date: calendar.date(byAdding: .day, value: dayOffset, to: Date())!,
                tempMin: 15,
                tempMax: 25,
                condition: .clear,
                iconCode: "01d",
                rainChance: 0
            )
        }
    }
}

// MARK: - OpenWeatherMap API Response Models

struct OpenWeatherResponse: Codable {
    let coord: Coordinates
    let weather: [WeatherInfo]
    let main: MainInfo
    let wind: WindInfo
    let clouds: CloudsInfo
    let rain: RainInfo?
    let name: String
    let sys: SysInfo
    let dt: Int

    struct Coordinates: Codable {
        let lon: Double
        let lat: Double
    }

    struct WeatherInfo: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    struct MainInfo: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let humidity: Int

        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
            case humidity
        }
    }

    struct WindInfo: Codable {
        let speed: Double
    }

    struct CloudsInfo: Codable {
        let all: Int
    }

    struct RainInfo: Codable {
        let oneHour: Double?
        let threeHour: Double?

        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
            case threeHour = "3h"
        }
    }

    struct SysInfo: Codable {
        let country: String?
    }
}

struct OpenWeatherForecastResponse: Codable {
    let list: [ForecastItem]
    let city: CityInfo

    struct ForecastItem: Codable {
        let dt: Int
        let main: OpenWeatherResponse.MainInfo
        let weather: [OpenWeatherResponse.WeatherInfo]
        let pop: Double
    }

    struct CityInfo: Codable {
        let name: String
        let country: String
    }
}

extension Weather {
    static func from(response: OpenWeatherResponse) -> Weather {
        let weatherInfo = response.weather.first
        return Weather(
            cityName: response.name,
            country: response.sys.country ?? "",
            temperature: response.main.temp,
            feelsLike: response.main.feelsLike,
            tempMin: response.main.tempMin,
            tempMax: response.main.tempMax,
            humidity: response.main.humidity,
            windSpeed: response.wind.speed * 3.6,
            condition: WeatherCondition.from(apiCondition: weatherInfo?.main ?? "Unknown"),
            description: weatherInfo?.description.capitalized ?? "",
            iconCode: weatherInfo?.icon ?? "",
            rainChance: Int((response.rain?.oneHour ?? 0) * 10),
            timestamp: Date(timeIntervalSince1970: TimeInterval(response.dt))
        )
    }
}

extension Forecast {
    static func from(item: OpenWeatherForecastResponse.ForecastItem) -> Forecast {
        let weatherInfo = item.weather.first
        return Forecast(
            date: Date(timeIntervalSince1970: TimeInterval(item.dt)),
            tempMin: item.main.tempMin,
            tempMax: item.main.tempMax,
            condition: WeatherCondition.from(apiCondition: weatherInfo?.main ?? "Unknown"),
            iconCode: weatherInfo?.icon ?? "",
            rainChance: Int(item.pop * 100)
        )
    }
}
