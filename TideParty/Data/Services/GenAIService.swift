import Foundation
import GoogleGenerativeAI

/// Service for generating AI-powered tide pooling insights using Google's Gemini API
class GenAIService: AIServiceProtocol {
    private let model: GenerativeModel
    
    init() {
        // Load API key from plist
        guard let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["API_KEY"] as? String else {
            fatalError("Failed to load API_KEY from GenerativeAI-Info.plist")
        }
        
        
        self.model = GenerativeModel(name: "gemini-2.5-flash-lite", apiKey: apiKey)
    }
    
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
        location: String = "Santa Cruz"
    ) async throws -> String {
        let prompt = """
        You are a friendly marine biologist helping people explore tide pools in \(location), California.
        
        Current conditions:
        - Tide: \(String(format: "%.1f", tideHeight))ft and \(tideDirection.lowercased())
        - Weather: \(weatherCondition), \(temperature)°F
        
        Generate exactly 2 sentences about what specific creatures or marine life they can see RIGHT NOW in these conditions.
        Focus only on what's visible and where to look. Be specific and conversational.
        Do not use emojis. Maximum 50 words.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            
            guard let text = response.text else {
                throw GenAIError.emptyResponse
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("❌ GenAI Error: \(error)")
            throw GenAIError.apiError(error)
        }
    }
}

// MARK: - Error Types
enum GenAIError: LocalizedError {
    case emptyResponse
    case apiError(Error)
    
    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "The AI did not return a response."
        case .apiError(let error):
            return "API Error: \(error.localizedDescription)"
        }
    }
}
