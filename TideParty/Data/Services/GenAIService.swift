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
    
    /// Generates a quiz question relevant to the captured creature or general ocean conservation
    func generateQuizQuestion(creature: String) async throws -> QuizQuestion {
        // 1. Load and sample examples from JSON
        var examplesContext = ""
        if let url = Bundle.main.url(forResource: "question_ex", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let allQuestions = try? JSONDecoder().decode([QuizQuestion].self, from: data) {
            
            // Pick 3 random examples to provide style/format without overwhelming the context
            let randomExamples = allQuestions.shuffled().prefix(3)
            
            // Re-encode to JSON string
            if let sampledData = try? JSONEncoder().encode(Array(randomExamples)),
               let sampledString = String(data: sampledData, encoding: .utf8) {
                examplesContext = sampledString
            }
        }
        
        // 2. Construct Prompt
        let prompt = """
        You are an expert marine biologist educator creating a trivia game for TideParty.
        
        Here is a dataset of example questions and the expected JSON format:
        \(examplesContext)
        
        TASK:
        Generate a NEW, unique multiple-choice question about the marine creature: "\(creature)".
        If specific facts about "\(creature)" are not available, generate a question about general ocean conservation or tide pool ecosystems.
        
        CRITICAL: 
        - DO NOT reuse any questions from the provided examples.
        - Create a completely new question that is not in the dataset.
        
        REQUIREMENTS:
        - The Output must be valid JSON matching the structure of the examples.
        - "correct_answer" must be an integer (1, 2, 3, or 4).
        - "reason" should explain why the answer is correct in 1-2 sentences.
        - Return ONLY the raw JSON object. Do not wrap in markdown code blocks.
        """
        
        // 3. Call Gemini
        do {
            let response = try await model.generateContent(prompt)
            
            guard let text = response.text else {
                throw GenAIError.emptyResponse
            }
            
            // Clean up response if it contains markdown formatting
            let cleanText = text.replacingOccurrences(of: "```json", with: "")
                                .replacingOccurrences(of: "```", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let data = cleanText.data(using: .utf8) else {
                throw GenAIError.invalidJSON
            }
            
            // 4. Decode JSON
            // The API might return a single object or a list. We asked for "a NEW question", so likely an object.
            // But if it mimics the examples which are a list, it might return a list.
            // Let's try to decode as single object first.
            if let question = try? JSONDecoder().decode(QuizQuestion.self, from: data) {
                return question
            }
            
            // If that fails, maybe it returned an array of 1?
            if let questions = try? JSONDecoder().decode([QuizQuestion].self, from: data),
               let first = questions.first {
                return first
            }
            
            throw GenAIError.invalidJSON
            
        } catch {
            print("❌ GenAI Quiz Error: \(error)")
            if let genAIError = error as? GenAIError {
                throw genAIError
            }
            throw GenAIError.apiError(error)
        }
    }
    
    func generateFactSheet(creature: String) async throws -> CreatureFactSheet {
        let prompt = """
        You are an expert marine biologist writing for a field guide app called TideParty.
        
        TASK:
        Create an educational fact sheet for the marine creature: "\(creature)".
        
        REQUIREMENTS:
        - Output strict JSON with these keys: "scientific_name", "about", "ecosystem_role", "fun_fact".
        - "about": A concise (2-3 sentences), engaging description of what the creature looks like and where it lives.
        - "ecosystem_role": Explain its job in the food web or environment (e.g., cleaner, predator, prey) in 1-2 sentences.
        - "fun_fact": A weird or surprising trivia fact.
        - Tone: Enthusiastic, educational, and accessible to general users.
        - Return ONLY raw JSON. No markdown.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            
            guard let text = response.text else {
                throw GenAIError.emptyResponse
            }
            
            // Clean up JSON
            var jsonString = text
            if let firstOpen = text.firstIndex(of: "{"),
               let lastClose = text.lastIndex(of: "}") {
                jsonString = String(text[firstOpen...lastClose])
            }
            
            print("📝 Gemini Fact Sheet Raw: \(text)")
            
            guard let data = jsonString.data(using: .utf8) else {
                throw GenAIError.invalidJSON
            }
            
            return try JSONDecoder().decode(CreatureFactSheet.self, from: data)
            
        } catch {
            print("❌ Gemini Learn Error: \(error)")
            throw GenAIError.apiError(error)
        }
    }
}

// MARK: - Error Types
enum GenAIError: LocalizedError {
    case emptyResponse
    case invalidJSON
    case apiError(Error)
    
    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "The AI did not return a response."
        case .invalidJSON:
            return "The AI response could not be parsed as a valid question."
        case .apiError(let error):
            return "API Error: \(error.localizedDescription)"
        }
    }
}
