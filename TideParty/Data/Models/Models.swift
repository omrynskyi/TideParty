import Foundation

struct WeatherData {
    let temp: Int
    let condition: String // "Sunny", "Cloudy", etc.
    let isSunny: Bool
}

struct TideData {
    let height: Double
    let trend: String // "Rising" or "Falling"
    let nextLowTide: Date
}
