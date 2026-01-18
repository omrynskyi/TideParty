import Foundation

/// Protocol defining the interface for AI insights generation
protocol AIServiceProtocol {
    /// Generates a personalized tide pooling insight based on current conditions
    /// - Parameters:
    ///   - tideHeight: Current tide height in feet
    ///   - tideDirection: Tide trend ("Rising" or "Falling")
    ///   - weatherCondition: Current weather description
    ///   - temperature: Current temperature in Fahrenheit
    ///   - location: Location name (e.g., "Santa Cruz")
    /// - Returns: A friendly, informative tip about tide pooling
    func generateInsight(
        tideHeight: Double,
        tideDirection: String,
        weatherCondition: String,
        temperature: Int,
        location: String
    ) async throws -> String
}
