import SwiftUI
import FirebaseFirestore

enum ViewMode {
    case list
    case map
}

struct SpotsContainerView: View {
    @StateObject private var viewModel: SpotsViewModel
    @State private var viewMode: ViewMode = .list
    
    var onOpenCamera: () -> Void = {}
    
    // Allow injection for previews/tests
    init(viewModel: SpotsViewModel = SpotsViewModel(), onOpenCamera: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onOpenCamera = onOpenCamera
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Content View Swapper
            ZStack {
                if viewMode == .map {
                    SpotsMapView(viewModel: viewModel)
                        .ignoresSafeArea(edges: [.top, .horizontal])
                        .zIndex(0)
                        .transition(.opacity)
                }
                
                if viewMode == .list {
                    // Background for List
                    ZStack(alignment: .bottom) {
                        Color.white
                        Color("MainBlue")
                            .frame(height: 100)
                    }
                    .ignoresSafeArea()
                    .zIndex(0)
                }

                VStack(spacing: 0) {
                    // Header Area
                    VStack(spacing: 16) {
                       
                        // Title & Toggle
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Showing places in")
                                .font(.system(size: 28, weight: .bold))
                                .shadow(color: viewMode == .map ? .white : .clear, radius: 2)
                            Text(viewModel.currentCity)
                                .font(.system(size: 36, weight: .bold))
                                .layoutPriority(1)
                                .shadow(color: viewMode == .map ? .white : .clear, radius: 2)
                            
                            // View Toggle Button - Centered
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewMode = (viewMode == .list) ? .map : .list
                                    }
                                }) {
                                    HStack {
                                        Text(viewMode == .list ? "View as Map" : "View as List")
                                            .font(.system(size: 16, weight: .semibold))
                                        Image(systemName: viewMode == .list ? "map" : "list.bullet")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color("MainBlue"))
                                    .cornerRadius(25)
                                    .shadow(radius: 4)
                                }
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                    .background(
                        viewMode == .list 
                            ? Color.white 
                            : Color.white.opacity(0.0) // Transparent header for map
                    )
                    .background(
                        viewMode == .map ? 
                            LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.0)], startPoint: .top, endPoint: .bottom) 
                            : LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom)
                    )
                    
                    if viewMode == .list {
                        // Add bottom padding to keep cards above waves
                        SpotsListView(viewModel: viewModel)
                            .padding(.bottom, 40)
                            .transition(.opacity)
                    } else {
                        Spacer()
                    }
                }
                .zIndex(1)
            }
            
            // Bottom Wave Section (Overlay)
            VStack {
                Spacer()
                Button(action: {
                    onOpenCamera()
                }) {
                    AnimatedWaveView {
                        VStack(spacing: 6) {
                            Image(systemName: "camera")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Get out there!")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(StaticButtonStyle())
            }
            .ignoresSafeArea(edges: .bottom)
            .zIndex(20)
        }
    }
}

#Preview {
    // Build a mock view model to avoid Firebase/Location in previews
    let vm = SpotsViewModel()
    // Prevent background work in preview by short-circuiting its data
    vm.spots = [
        TideSpot(
            id: "1",
            name: "Natural Bridges",
            rating: 5,
            location: GeoPoint(latitude: 36.9515, longitude: -122.0573),
            polygon: [],
            imageName: nil
        ),
        TideSpot(
            id: "2",
            name: "Pleasure Point",
            rating: 4,
            location: GeoPoint(latitude: 36.9644, longitude: -121.9653),
            polygon: [],
            imageName: nil
        )
    ]
    vm.currentCity = "Santa Cruz"
    return SpotsContainerView(viewModel: vm)
}
