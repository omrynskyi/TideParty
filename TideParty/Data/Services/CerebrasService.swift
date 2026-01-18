import Foundation

/// Service for generating AI insights using Cerebras API
class CerebrasService: AIServiceProtocol {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.cerebras.ai/v1/chat/completions")!
    
    init() {
        // Load API key from plist
        guard let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["CAL_API_KEY"] as? String else {
            print("⚠️ Warning: CAL_API_KEY not found in GenerativeAI-Info.plist")
            self.apiKey = ""
            return
        }
        self.apiKey = key
    }
    
    func generateInsight(
        tideHeight: Double,
        tideDirection: String,
        weatherCondition: String,
        temperature: Int,
        location: String
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GenAIError.apiError(NSError(domain: "CerebrasService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing API Key"]))
        }
        
        // Construct the prompt
        let prompt = """
        You are an enthusiastic local marine biologist showing a friend around the tide pools in \(location), California! 🌊
        
        Current Conditions:
        - Tide: \(String(format: "%.1f", tideHeight))ft (\(tideDirection.lowercased()))
        - Weather: \(weatherCondition), \(temperature)°F
        
        Give me a fun, specific tip about what to look for right now. Mention a specific creature that would be active or visible in these conditions and where it likes to hide. Make it sound exciting and welcoming!
        
        Keep it to 2-3 short sentences. No emojis in the output (I'll add my own).
        """
        
        // Prepare Request Body
        let requestBody = CerebrasChatRequest(
            model: "llama-3.3-70b",
            stream: false,
            messages: [
                CerebrasMessage(content: prompt, role: "user")
            ],
            temperature: 0,
            maxTokens: -1,
            seed: 0,
            topP: 1
        )
        
        // Configure URL Request
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GenAIError.apiError(NSError(domain: "CerebrasService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Cerebras API Error: \(httpResponse.statusCode) - \(errorText)")
                }
                throw GenAIError.apiError(NSError(domain: "CerebrasService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error \(httpResponse.statusCode)"]))
            }
            
            let charResponse = try JSONDecoder().decode(CerebrasChatResponse.self, from: data)
            
            guard let content = charResponse.choices.first?.message.content else {
                throw GenAIError.emptyResponse
            }
            
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch {
            print("❌ Cerebras Network Error: \(error)")
            throw GenAIError.apiError(error)
        }
    }
    
    func generateQuizQuestion(creature: String) async throws -> QuizQuestion {
        guard !apiKey.isEmpty else {
            throw GenAIError.apiError(NSError(domain: "CerebrasService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing API Key"]))
        }
        
        // 1. Load and sample examples from JSON
        var examplesContext = ""
        if let url = Bundle.main.url(forResource: "question_ex", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let allQuestions = try? JSONDecoder().decode([QuizQuestion].self, from: data) {
            
            // Pick 3 random examples
            let randomExamples = allQuestions.shuffled().prefix(3)
            
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
        
        // 3. Prepare Request Body
        let requestBody = CerebrasChatRequest(
            model: "llama-3.3-70b",
            stream: false,
            messages: [
                CerebrasMessage(content: prompt, role: "user")
            ],
            temperature: 0.8, // Increased for variety
            maxTokens: -1,
            seed: 0,
            topP: 1
        )
        
        // 4. Configure URL Request
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GenAIError.apiError(NSError(domain: "CerebrasService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Cerebras API Error: \(httpResponse.statusCode) - \(errorText)")
                }
                throw GenAIError.apiError(NSError(domain: "CerebrasService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error \(httpResponse.statusCode)"]))
            }
            
            let charResponse = try JSONDecoder().decode(CerebrasChatResponse.self, from: data)
            
            guard let content = charResponse.choices.first?.message.content else {
                throw GenAIError.emptyResponse
            }
            
            // Clean up response: Find first { and last }
            var jsonString = content
            if let firstOpen = content.firstIndex(of: "{"),
               let lastClose = content.lastIndex(of: "}") {
                jsonString = String(content[firstOpen...lastClose])
            }
            
            // Log raw response for debugging
            print("📝 Cerebras Raw Response: \(content)")
            print("🧹 Cleaned JSON: \(jsonString)")
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                print("❌ Failed to convert string to data")
                throw GenAIError.invalidJSON
            }
            
            // 5. Decode JSON
            if let question = try? JSONDecoder().decode(QuizQuestion.self, from: jsonData) {
                return question
            }
            
            if let questions = try? JSONDecoder().decode([QuizQuestion].self, from: jsonData),
               let first = questions.first {
                return first
            }
            
            throw GenAIError.invalidJSON
            
        } catch {
            print("❌ Cerebras Network Error: \(error)")
            throw GenAIError.apiError(error)
        }
    }
    
    func generateFactSheet(creature: String) async throws -> CreatureFactSheet {
        guard !apiKey.isEmpty else {
            throw GenAIError.apiError(NSError(domain: "CerebrasService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing API Key"]))
        }
        
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
        
        let requestBody = CerebrasChatRequest(
            model: "llama-3.3-70b",
            stream: false,
            messages: [
                CerebrasMessage(content: prompt, role: "user")
            ],
            temperature: 0.7,
            maxTokens: -1,
            seed: 0,
            topP: 1
        )
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw GenAIError.apiError(NSError(domain: "CerebrasService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Error"]))
            }
            
            let charResponse = try JSONDecoder().decode(CerebrasChatResponse.self, from: data)
            
            guard let content = charResponse.choices.first?.message.content else {
                throw GenAIError.emptyResponse
            }
            
            // Clean up JSON
            var jsonString = content
            if let firstOpen = content.firstIndex(of: "{"),
               let lastClose = content.lastIndex(of: "}") {
                jsonString = String(content[firstOpen...lastClose])
            }
            
            print("📝 Learn Fact Sheet Raw: \(content)")
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw GenAIError.invalidJSON
            }
            
            return try JSONDecoder().decode(CreatureFactSheet.self, from: jsonData)
            
        } catch {
            print("❌ Learn API Error: \(error)")
            throw GenAIError.apiError(error)
        }
    }
}
