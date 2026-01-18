import Foundation

/// Model representing a generated quiz question
struct QuizQuestion: Codable {
    let question: String
    let answer1: String
    let answer2: String
    let answer3: String
    let answer4: String
    let correctAnswer: Int
    let reason: String
    
    enum CodingKeys: String, CodingKey {
        case question
        case answer1, answer2, answer3, answer4
        case correctAnswer = "correct_answer"
        case reason
        case options // For handling array-based format
    }
    
    init(question: String, answer1: String, answer2: String, answer3: String, answer4: String, correctAnswer: Int, reason: String) {
        self.question = question
        self.answer1 = answer1
        self.answer2 = answer2
        self.answer3 = answer3
        self.answer4 = answer4
        self.correctAnswer = correctAnswer
        self.reason = reason
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.question = try container.decode(String.self, forKey: .question)
        self.correctAnswer = try container.decode(Int.self, forKey: .correctAnswer)
        self.reason = try container.decode(String.self, forKey: .reason)
        
        // Try decoding individual fields first
        if let a1 = try? container.decode(String.self, forKey: .answer1),
           let a2 = try? container.decode(String.self, forKey: .answer2),
           let a3 = try? container.decode(String.self, forKey: .answer3),
           let a4 = try? container.decode(String.self, forKey: .answer4) {
            self.answer1 = a1
            self.answer2 = a2
            self.answer3 = a3
            self.answer4 = a4
        } else if let options = try? container.decode([String].self, forKey: .options), options.count >= 4 {
            // Fallback: Map options array to fields
            self.answer1 = options[0]
            self.answer2 = options[1]
            self.answer3 = options[2]
            self.answer4 = options[3]
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Expected either answer1...4 or options array"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(question, forKey: .question)
        try container.encode(answer1, forKey: .answer1)
        try container.encode(answer2, forKey: .answer2)
        try container.encode(answer3, forKey: .answer3)
        try container.encode(answer4, forKey: .answer4)
        try container.encode(correctAnswer, forKey: .correctAnswer)
        try container.encode(reason, forKey: .reason)
    }
}

/// Model representing educational content about a creature
struct CreatureFactSheet: Codable {
    let scientificName: String
    let about: String // Short paragraph describing the creature
    let ecosystemRole: String // How it contributes to the environment
    let funFact: String // One interesting trivia nugget
    
    enum CodingKeys: String, CodingKey {
        case scientificName = "scientific_name"
        case about
        case ecosystemRole = "ecosystem_role"
        case funFact = "fun_fact"
    }
}

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
    
    /// Generates a quiz question relevant to the captured creature or general ocean conservation
    /// - Parameter creature: The name of the creature captured (e.g., "Starfish")
    /// - Returns: A generated QuizQuestion
    func generateQuizQuestion(creature: String) async throws -> QuizQuestion
    
    /// Generates an educational fact sheet about the creature
    /// - Parameter creature: The name of the creature captured
    /// - Returns: A generated CreatureFactSheet
    func generateFactSheet(creature: String) async throws -> CreatureFactSheet
}
