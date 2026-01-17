import Foundation

// MARK: - Protocols

protocol WeatherServiceProtocol {
    func fetchWeather() async throws -> WeatherData
}

protocol TideServiceProtocol {
    func fetchTides() async throws -> TideData
}

// MARK: - Mocks

class MockWeatherService: WeatherServiceProtocol {
    func fetchWeather() async throws -> WeatherData {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Return "Good Day" condition
        return WeatherData(temp: 68, condition: "Sunny", isSunny: true)
    }
}

class MockTideService: TideServiceProtocol {
    func fetchTides() async throws -> TideData {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Return low tide < 2.0ft
        return TideData(
            height: 1.5, // Perfect for tide pooling
            trend: "Falling",
            nextLowTide: Date().addingTimeInterval(3600 * 2) // 2 hours from now
        )
    }
}
