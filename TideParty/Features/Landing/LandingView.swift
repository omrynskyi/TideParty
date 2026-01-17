import SwiftUI

struct LandingView: View {
    @StateObject private var viewModel = LandingViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            // Header (Notch/Ears)
            HStack {
                HStack {
                    Text("Santa Cruz")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
                
                Circle()
                    .fill(Color("MainBlue").opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(Text("🦦").font(.system(size: 20)))
            }
            .padding(.horizontal, 16)
            .padding(.top, 2) // Slight adjustment for status bar
            .zIndex(1) // Ensure it stays on top
            
            VStack(spacing: 20) {
                // Spacer to push content down below header/notch
                Spacer().frame(height: 12)
                
                // Hero Message & Weather
                HStack(alignment: .top) {
                    Text(viewModel.heroMessage)
                        .font(.system(size: 30, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    if let weather = viewModel.weather {
                        VStack {
                            Image(systemName: "sun.max.fill") // Placeholder for nice cloud/sun
                                .resizable()
                                .renderingMode(.original)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.yellow)
                            HStack{
                                Text("\(weather.temp)°")
                                    .font(.system(size: 18, weight: .bold))
                                    .kerning(-1.0)
                                
                                Text("70° in 2h")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .kerning(-0.5)

                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Find Spots Button
                Button(action: {
                    // Action
                }) {
                    Text("Find Spots Nearby")
                        .font(.custom("Inter-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color("MainBlue"))
                        .cornerRadius(30)
                }
                .padding(.horizontal, 90)
                
                // Map Card Placeholder
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hue: 0.25, saturation: 0.1, brightness: 0.9)) // Light green map placeholder
                    .overlay(
                        Text("Map Placeholder")
                            .foregroundColor(.gray.opacity(0.5))
                    )
                    .frame(height: 220)
                    .padding(.horizontal)
                
                // Tide Graph Card
                if let tide = viewModel.tide {
                    TideGraphView(tide: tide)
                        .frame(height: 180)
                        .padding(.horizontal)
                }
                
                Spacer() // Push everything up
            }
            .padding(.top)
            
            // Bottom Wave
            ZStack(alignment: .bottom) {
                WaveShape()
                    .fill(Color("MainBlue"))
                    .frame(height: 160)
                    .shadow(radius: 10)
                
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text("See anything cool?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 50)
            }
            .ignoresSafeArea(edges: .bottom)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .task {
            await viewModel.refreshData()
        }
    }
}

// Subcomponent: TideGraphView
struct TideGraphView: View {
    let tide: TideData
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("MainBlue").opacity(0.1))
            
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text("\(Int(tide.height))'")
                        .font(.system(size: 32, weight: .medium))
                    Image(systemName: "arrow.down")
                        .font(.system(size: 20, weight: .medium))
                        .padding(.top, 6)
                }
                
                Text("Low Tide in 2h")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(20)
            
            // Decorative Sine Wave inside the card
            GeometryReader { geometry in
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h * 0.6))
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.8),
                        control1: CGPoint(x: w * 0.4, y: h * 0.2),
                        control2: CGPoint(x: w * 0.7, y: h * 0.9)
                    )
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(Color("MainBlue"))
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}


#Preview {
    LandingView()
}
