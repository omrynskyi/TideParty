import SwiftUI

struct DesignSystem {
    struct Colors {
        static let primaryBlue = Color.blue
        static let background = Color.white
        static let textPrimary = Color.black
        static let oceanFill = Color.blue.opacity(0.8)
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at bottom left
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        
        // Draw up to start of wave (left side)
        path.addLine(to: CGPoint(x: 0, y: rect.maxY * 0.7))
        
        // Create a gentle sine wave
        // We'll prioritize the look from the mockup: flat-ish start, then a rise.
        // Actually, looking at the mockup, it looks like a big swell.
        // Let's do a simple sine wave for now.
        
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.6
        let waveHeight = height * 0.2
        
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control1: CGPoint(x: width * 0.4, y: midHeight - waveHeight),
            control2: CGPoint(x: width * 0.7, y: midHeight + waveHeight)
        )
        
        // Line down to bottom right
        path.addLine(to: CGPoint(x: width, y: height))
        
        // Close path
        path.addLine(to: CGPoint(x: 0, y: height))
        
        return path
    }
}
