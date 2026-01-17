import SwiftUI

struct TideGraphView: View {
    let tideData: [TideCurvePoint]
    @Binding var selectedTime: Date?
    var currentWeatherIcon: String? // Pass from ViewModel
    var currentTemp: Int? // Pass from ViewModel
    
    // Computed range for Y-axis with padding to avoid hitting edges
    // User wants the wave to be about half height max, so we double the "range" effectively by increasing max H.
    private var minHeight: Double {
        let actualMin = tideData.map(\.height).min() ?? -1.0
        let actualMax = tideData.map(\.height).max() ?? 6.0
        let range = actualMax - actualMin
        // Subtract a percentage of the range from the minimum to push the curve up
        return actualMin - (range * 0.2) // Increased padding at bottom
    }
    private var maxHeight: Double {
        let actualMax = tideData.map(\.height).max() ?? 6.0
        let actualMin = tideData.map(\.height).min() ?? -1.0
        let range = actualMax - actualMin
        // To make the wave occupy ~60% of bottom, we extend the 'max' coordinate upwards.
        return actualMax + (range * 0.8) 
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 1. The Curve Area (Filled)
                TideCurveShape(points: tideData, minH: minHeight, maxH: maxHeight, shouldClose: true)
                    .fill(Color("MainBlue"))
                // 2. The Curve Stroke (Line on top) - Removed to match reference (solid fill only usually implies no disparate stroke needed, or same color)
                // If reference shows just a solid shape, we can remove the stroke or keep it if it adds definition.
                // The prompt says "no gradient", "blue filled". Usually implies a flat vector feel.
                // We'll remove the stroke to be cleaner, or make it same color.
                // Text says "blue sine-wave shape filled to the bottom".
                
                
                // 3. Scrubber Line Only (info moved to parent view)
                let displayTime = selectedTime ?? Date()
                let xPos = xPosition(for: displayTime, width: geometry.size.width)
                
                // Vertical Line
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: geometry.size.height)
                    .position(x: xPos, y: geometry.size.height / 2)
            }
            .contentShape(Rectangle()) // Make entire area touchable
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateSelectedTime(at: value.location.x, width: geometry.size.width)
                    }
                    .onEnded { _ in
                        // Snap back to current time on release
                        selectedTime = nil
                    }
            )
        }
    }
    
    // MARK: - Helpers
    
    private func updateSelectedTime(at x: CGFloat, width: CGFloat) {
        guard !tideData.isEmpty else { return }
        let progress = max(0, min(1, x / width)) // 0.0 to 1.0
        
        let startTime = tideData.first!.date.timeIntervalSince1970
        let endTime = tideData.last!.date.timeIntervalSince1970
        let totalDuration = endTime - startTime
        
        let targetTime = startTime + (totalDuration * Double(progress))
        let targetDate = Date(timeIntervalSince1970: targetTime)
        
        // Snap to nearest point in data for smooth scrubbing
        if let nearest = tideData.min(by: { abs($0.date.timeIntervalSince(targetDate)) < abs($1.date.timeIntervalSince(targetDate)) }) {
            selectedTime = nearest.date
        }
    }
    
    // Inverse of updateSelectedTime
    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        guard let first = tideData.first, let last = tideData.last else { return 0 }
        
        let start = first.date.timeIntervalSince1970
        let end = last.date.timeIntervalSince1970
        let range = end - start
        
        let current = date.timeIntervalSince1970 - start
        let progress = current / range
        
        return width * CGFloat(progress)
    }
}

// MARK: - The Shape
struct TideCurveShape: Shape {
    let points: [TideCurvePoint]
    let minH: Double
    let maxH: Double
    var shouldClose: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        
        let width = rect.width
        let height = rect.height
        
        // Helper to map data point to view coordinates
        // Y is flipped (0 is top), so Max height goes to 0 Y, Min height goes to Height Y.
        let hRange = maxH - minH
        
        func point(at index: Int) -> CGPoint {
            let p = points[index]
            
            // X Mapping: Time based
            // Assumes points cover the full width evenly or we calculate relative to start/end
            // Let's assume points are startOfDay to endOfDay
            let startTime = points.first!.date.timeIntervalSince1970
            let totalTime = points.last!.date.timeIntervalSince1970 - startTime
            
            let timeProgress = (p.date.timeIntervalSince1970 - startTime) / totalTime
            let x = width * CGFloat(timeProgress)
            
            // Y Mapping: Height based
            // Normalize height 0.0 to 1.0
            let heightProgress = (p.height - minH) / hRange
            // Invert for CoreGraphics (1.0 is top 0)
            let y = height * (1 - CGFloat(heightProgress))
            
            return CGPoint(x: x, y: y)
        }
        
        // Start
        let startPt = point(at: 0)
        path.move(to: startPt)
        
        // Draw lines
        for i in 1..<points.count {
            path.addLine(to: point(at: i))
        }
        
        if shouldClose {
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        }
        
        return path
    }
}
