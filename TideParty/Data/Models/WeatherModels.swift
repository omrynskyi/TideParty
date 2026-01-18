import Foundation

// MARK: - API Response Types

struct OpenMeteoResponse: Codable {
    let current: CurrentWeather?
    let minutely_15: Minutely15?
    let daily: Daily?
    
    struct CurrentWeather: Codable {
        let temperature_2m: Double
        let weather_code: Int
        let is_day: Int
    }
    
    struct Minutely15: Codable {
        let time: [String]
        let temperature_2m: [Double]
        let weather_code: [Int]
    }
    
    struct Daily: Codable {
        let sunrise: [String]
        let sunset: [String]
    }
}

// MARK: - Domain / UI Types

struct WeatherDisplayData {
    let temp: Int
    let conditionIcon: String
    let description: String
    let isSunnyOrPartlyCloudy: Bool
}

// For storing the 15-min forecast array
struct WeatherTimePoint: Identifiable {
    let id = UUID()
    let date: Date
    let temp: Int
    let conditionIcon: String
}
