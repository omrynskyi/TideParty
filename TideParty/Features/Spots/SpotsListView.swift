import SwiftUI

struct SpotsListView: View {
    @StateObject private var viewModel = SpotsViewModel()
    @State private var waveOffset: Double = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            ZStack(alignment: .bottom) {
                Color.white
                Color("MainBlue")
                    .frame(height: 100)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        HStack {
                            Text(viewModel.currentCity)
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
                    
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Showing places in")
                            .font(.system(size: 28, weight: .bold))
                        Text(viewModel.currentCity)
                            .font(.system(size: 36, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // View as Map Button
                    Button(action: {
                        // Navigate to map view
                    }) {
                        HStack {
                            Text("View as Map")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "map")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color("MainBlue"))
                        .cornerRadius(25)
                    }
                    .padding(.top, 8)
                    
                    // Spots List
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if let error = viewModel.error {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.spots) { spot in
                                SpotCardView(
                                    spot: spot,
                                    tideHeight: 3.0, // Placeholder - integrate with TideService
                                    onGoTidePooling: {
                                        // Navigate to spot detail
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Bottom padding for wave section
                    Spacer().frame(height: 180)
                }
            }
            .padding(.bottom, 100)
            .clipped()
            
            // Bottom Wave Section (animated)
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    WaveShape(offset: waveOffset + 0.3, amplitude: 8)
                        .fill(Color("MainBlue").opacity(0.3))
                        .frame(height: 80)
                    
                    WaveShape(offset: waveOffset + 0.6, amplitude: 6)
                        .fill(Color("MainBlue").opacity(0.5))
                        .frame(height: 65)
                    
                    WaveShape(offset: waveOffset, amplitude: 10)
                        .fill(Color("MainBlue"))
                        .frame(height: 50)
                }
                
                Color("MainBlue")
                    .frame(height: 80)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "camera")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Get out there!")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(y: -8)
                    )
            }
            .ignoresSafeArea(edges: .bottom)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .zIndex(10)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                waveOffset = 1.0
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#Preview {
    SpotsListView()
}
