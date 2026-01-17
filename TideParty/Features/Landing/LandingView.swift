import SwiftUI

struct LandingView: View {
    @StateObject private var viewModel = LandingViewModel()
    @State private var waveOffset: Double = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background - blue at bottom covers home bar area only
            ZStack(alignment: .bottom) {
                Color.white
                Color("MainBlue")
                    .frame(height: 100) // Just enough to cover home bar
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header (scrolls with content)
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
                    .padding(.top, 8)
                    
                    // Hero Message & Weather
                    HStack(alignment: .top) {
                        Text(viewModel.heroMessage)
                            .font(.system(size: 30, weight: .bold))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                        if let weather = viewModel.weather {
                            VStack {
                                Image(systemName: weather.condition)
                                    .resizable()
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(weather.condition.contains("moon") ? Color("MainBlue") : .yellow, .gray)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                HStack{
                                    Text("\(weather.temp)°")
                                        .font(.system(size: 18, weight: .bold))
                                        .kerning(-1.0)
                                    
                                    Text("\(weather.forecastTemp ?? 0)° in 2h")
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
                        .fill(Color(hue: 0.25, saturation: 0.1, brightness: 0.9))
                        .overlay(
                            Text("Map Placeholder")
                                .foregroundColor(.gray.opacity(0.5))
                        )
                        .frame(height: 220)
                        .padding(.horizontal)
                    
                    // Tide Graph Card (Interactive)
                    if !viewModel.tideCurve.isEmpty {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color("MainBlue").opacity(0.1))
                            
                            TideGraphView(
                                tideData: viewModel.tideCurve,
                                selectedTime: $viewModel.selectedGraphDate,
                                currentWeatherIcon: viewModel.weather?.condition,
                                currentTemp: viewModel.weather?.temp
                            )
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .center, spacing: 2) {
                                    let height = viewModel.selectedGraphData?.height ?? viewModel.tide?.height ?? 0
                                    Text(String(format: "%.1f'", height))
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.black)
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                
                                HStack(spacing: 6) {
                                    let displayTime = viewModel.selectedGraphDate ?? Date()
                                    Text(displayTime.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    if let weatherPoint = viewModel.getWeatherForDisplay() {
                                        HStack(spacing: 3) {
                                            Text("\(weatherPoint.temp)°")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.black)
                                            Image(systemName: weatherPoint.conditionIcon)
                                                .font(.system(size: 11))
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.yellow, .gray)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 12)
                            .padding(.leading, 16)
                            .allowsHitTesting(false)
                        }
                        .frame(height: 180)
                        .padding(.horizontal)
                    }
                    
                    // Bottom padding to account for sticky wave section
                    Spacer().frame(height: 180)
                }
                .padding(.top)
            }
            .padding(.bottom, 100) // Clip in middle of waves
            .clipped()
            
            // Bottom Wave Section (animated)
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    // Background wave layers (lighter)
                    WaveShape(offset: waveOffset + 0.3, amplitude: 8)
                        .fill(Color("MainBlue").opacity(0.3))
                        .frame(height: 80)
                    
                    WaveShape(offset: waveOffset + 0.6, amplitude: 6)
                        .fill(Color("MainBlue").opacity(0.5))
                        .frame(height: 65)
                    
                    // Main wave (solid)
                    WaveShape(offset: waveOffset, amplitude: 10)
                        .fill(Color("MainBlue"))
                        .frame(height: 50)
                }
                
                // Solid blue area with content
                Color("MainBlue")
                    .frame(height: 80)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "camera")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("See anything cool?")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(y: -8)
                    )
            }
            .ignoresSafeArea(edges: .bottom)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .zIndex(10) // Keep waves on top of scroll content
        }
        .task {
            await viewModel.refreshData()
        }
        .onAppear {
            // Slow, subtle infinite wave animation (one direction)
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                waveOffset = 1.0  // Full cycle = seamless loop
            }
        }
    }
}

// Old static graph view removed/replaced by Components/TideGraphView.swift usage
// We need to remove the internal struct definition if we are importing the new one.
// Since the new one is in the same module but different file, we just delete this block.


#Preview {
    LandingView()
}
