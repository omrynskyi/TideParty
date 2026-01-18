import Foundation

// MARK: - Cerebras API Models

struct CerebrasChatRequest: Codable {
    let model: String
    let stream: Bool
    let messages: [CerebrasMessage]
    let temperature: Double
    let maxTokens: Int
    let seed: Int
    let topP: Double
    
    enum CodingKeys: String, CodingKey {
        case model, stream, messages, temperature, seed
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
}

struct CerebrasMessage: Codable {
    let content: String
    let role: String
}

struct CerebrasChatResponse: Codable {
    let id: String
    let choices: [CerebrasChoice]
    let created: Int
    let model: String
}

struct CerebrasChoice: Codable {
    let index: Int
    let message: CerebrasMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}
