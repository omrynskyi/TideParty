import Foundation

class TideService: TideServiceProtocol {
    
    private let stationId = "9413745" // Santa Cruz
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    // Fetch directly from NOAA
    func fetchTides() async throws -> TideData {
        // We will repurpose TideData to hold the curve, or better, return the domain model.
        // For now, let's stick to the protocol but we might need to expand `TideData` 
        // OR add a new method to the protocol `fetchDailyCurve`.
        // Let's implement the specific method for the graph.
        
        let curve = try await fetchDailyTideCurve()
        
        // Find next low tide for the legacy 'TideData' struct
        let nextLow = curve.first(where: { $0.type == "L" && $0.date > Date() }) ?? curve.first!
        let currentHeight = interpolateHeight(at: Date(), points: curve)
        
        return TideData(
            height: currentHeight,
            trend: "Falling", // TODO: Calculate real trend
            nextLowTide: nextLow.date
        )
    }
    
    func fetchDailyTideCurve() async throws -> [TideCurvePoint] {
        // Correct NOAA Endpoint for High/Low predictions
        let urlString = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=\(stationId)&product=predictions&datum=MLLW&time_zone=lst_ldt&units=english&interval=hilo&format=json"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TideResponse.self, from: data)
        
        // Convert High/Low predictions to Dates
        let extremas: [TideCurvePoint] = response.predictions.compactMap { pred in
            guard let date = dateFormatter.date(from: pred.t),
                  let height = Double(pred.v) else { return nil }
            return TideCurvePoint(date: date, height: height, type: pred.type)
        }
        
        // Interpolate to create a smooth curve (every 15 mins)
        // We need start of day to end of day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var interpolatedPoints: [TideCurvePoint] = []
        let interval: TimeInterval = 15 * 60 // 15 minutes
        
        var currentDate = startOfDay
        while currentDate <= endOfDay {
            let height = cosineInterpolate(at: currentDate, extremas: extremas)
            // Check if this specific minute is close to an extrema to label it? 
            // For now just generic points.
            interpolatedPoints.append(TideCurvePoint(date: currentDate, height: height, type: nil))
            currentDate.addTimeInterval(interval)
        }
        
        return interpolatedPoints
    }
    
    // MARK: - Math Logic
    
    private func cosineInterpolate(at date: Date, extremas: [TideCurvePoint]) -> Double {
        // 1. Find the surrounding peaks/troughs
        // Since 'extremas' are sorted by time...
        
        // Handle edges: if before first extrema, or after last
        guard let first = extremas.first, let last = extremas.last else { return 0.0 }
        
        if date <= first.date { return first.height } // Clamp to first
        if date >= last.date { return last.height }   // Clamp to last
        
        // Find p1 (previous) and p2 (next)
        // We iterate to find the pair where p1.date <= date <= p2.date
        for i in 0..<(extremas.count - 1) {
            let p1 = extremas[i]
            let p2 = extremas[i+1]
            
            if date >= p1.date && date <= p2.date {
                // Percentage of time passed between p1 and p2
                let totalDuration = p2.date.timeIntervalSince(p1.date)
                let elapsed = date.timeIntervalSince(p1.date)
                let t = elapsed / totalDuration // 0.0 to 1.0
                
                // Cosine Interpolation Formula:
                // mu2 = (1 - cos(t * PI)) / 2
                // y = y1 * (1 - mu2) + y2 * mu2
                
                let mu2 = (1 - cos(t * .pi)) / 2
                return (p1.height * (1 - mu2)) + (p2.height * mu2)
            }
        }
        
        return 0.0
    }
    
    private func interpolateHeight(at date: Date, points: [TideCurvePoint]) -> Double {
         // Simple linear lookup for already interpolated array
         return points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })?.height ?? 0.0
    }
}
