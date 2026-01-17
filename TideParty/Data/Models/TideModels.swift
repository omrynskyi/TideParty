import Foundation

// MARK: - API Response
struct TideResponse: Codable {
    let predictions: [TidePrediction]
}

struct TidePrediction: Codable {
    let t: String // Timestamp "yyyy-MM-dd HH:mm"
    let v: String // Value (Height) in feet
    let type: String // "H" or "L"
}

// MARK: - Domain Model
struct TideCurvePoint: Identifiable {
    let id = UUID()
    let date: Date
    let height: Double
    let type: String? // "H" or "L" or nil for interpolated
}
