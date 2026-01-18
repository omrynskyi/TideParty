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
}
