import SwiftUI

struct DesignSystem {
    struct Colors {
        static let primaryBlue = Color("MainBlue")
        static let background = Color.white
        static let textPrimary = Color.black
        static let oceanFill = Color("MainBlue").opacity(0.8)
    }
}

struct WaveShape: Shape {
    var offset: Double = 0  // Phase offset for layered waves
    var amplitude: Double = 20  // Wave amplitude
    
    // Make offset animatable for smooth wave motion
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Start at bottom left
        path.move(to: CGPoint(x: 0, y: height))
        
        // Draw wave using sine function for organic look
        let resolution = 60  // Reduced for performance
        for i in 0...resolution {
            let x = (Double(i) / Double(resolution)) * width
            
            // Multiple sine waves combined for organic look
            let normalizedX = x / width
            let wave1 = sin((normalizedX * 2 * .pi) + (offset * .pi * 2)) * amplitude
            let wave2 = sin((normalizedX * 4 * .pi) + (offset * .pi * 2)) * (amplitude * 0.3)  // Full cycle for seamless loop
            
            let y = height * 0.4 - wave1 - wave2
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close path
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// Reusable Static Button Style (No highlight)
struct StaticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// Reusable Animated Wave View
struct AnimatedWaveView<Content: View>: View {
    @State private var waveOffset: Double = 0
    let content: Content
    
    init(@ViewBuilder content: () -> Content = { EmptyView() }) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Background wave layers (lighter)
                WaveShape(offset: waveOffset + 0.3, amplitude: 8)
                    .fill(Color("MainBlue").opacity(0.3))
                    .frame(height: 70)
                
                WaveShape(offset: waveOffset + 0.6, amplitude: 6)
                    .fill(Color("MainBlue").opacity(0.5))
                    .frame(height: 60)
                
                // Main wave (solid)
                WaveShape(offset: waveOffset, amplitude: 10)
                    .fill(Color("MainBlue"))
                    .frame(height: 48)
            }
            
            // Solid blue area with content
            Color("MainBlue")
                .frame(height: 90)
                .overlay(
                    content
                        .offset(y: -8)
                )
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                waveOffset = 1.0
            }
        }
    }
}
