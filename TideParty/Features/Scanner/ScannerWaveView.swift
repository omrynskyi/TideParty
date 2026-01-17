import SwiftUI

struct ScannerWaveView: View {
    @State private var waveOffset: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Background wave layers (lighter)
                WaveShape(offset: waveOffset + 0.3, amplitude: 6)
                    .fill(Color("MainBlue").opacity(0.3))
                    .frame(height: 50)
                
                WaveShape(offset: waveOffset + 0.6, amplitude: 4)
                    .fill(Color("MainBlue").opacity(0.5))
                    .frame(height: 40)
                
                // Main wave (solid)
                WaveShape(offset: waveOffset, amplitude: 8)
                    .fill(Color("MainBlue"))
                    .frame(height: 30) // Significantly shorter than global 48
            }
            
            // Solid blue area
            Color("MainBlue")
                .frame(height: 40) // Shorter than global 90/60
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                waveOffset = 1.0
            }
        }
    }
}

#Preview {
    ScannerWaveView()
}
