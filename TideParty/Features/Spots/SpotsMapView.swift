import SwiftUI
import MapKit
internal import FirebaseFirestoreInternal

struct SpotsMapView: View {
    @ObservedObject var viewModel: SpotsViewModel
    @State private var selectedSpot: TideSpot?
    @State private var position: MapCameraPosition = .automatic
    @State private var currentSpotIndex: Int = 0
    
    var body: some View {
        ZStack {
            Map(position: $position, selection: $selectedSpot) {
                UserAnnotation()
                
                ForEach(viewModel.spots) { spot in
                    if !spot.polygon.isEmpty {
                        MapPolygon(coordinates: spot.polygon.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                            .foregroundStyle(Color.blue.opacity(0.3))
                            .stroke(Color.blue, lineWidth: 2)
                            .tag(spot)
                    }
                    
                    Annotation(spot.name, coordinate: CLLocationCoordinate2D(latitude: spot.location.latitude, longitude: spot.location.longitude)) {
                        VStack(spacing: 4) {
                            Text(spot.name)
                                .font(.system(size: 14, weight: .bold))
                            
                            if let distance = spot.distanceInMiles {
                                Text(String(format: "%.1f mi away", distance))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .scaleEffect(selectedSpot?.id == spot.id ? 1.1 : 1.0)
                        .animation(.spring(), value: selectedSpot)
                    }
                    .tag(spot)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(maxHeight: .infinity)
            
            // Carousel Overlay
            if !viewModel.spots.isEmpty {
                VStack {
                    Spacer()
                    CarouselView(items: viewModel.spots, index: $currentSpotIndex) { spot, isSelected in
                        SpotCardView(
                            spot: spot,
                            tideHeight: 3.0, // Placeholder
                            onGoTidePooling: {
                                // Action
                            }
                        )
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .frame(height: 200) // Adjust height as needed
                    .padding(.bottom, 100) // Space above waves
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onAppear {
            if let index = viewModel.spots.firstIndex(where: { $0.isLocalsFavorite }) {
                currentSpotIndex = index
            }
        }
        .onChange(of: viewModel.spots) { spots in
             if let index = spots.firstIndex(where: { $0.isLocalsFavorite }) {
                 currentSpotIndex = index
             }
        }
        .onChange(of: currentSpotIndex) { index in
            guard viewModel.spots.indices.contains(index) else { return }
            let spot = viewModel.spots[index]
            selectedSpot = spot
            
            withAnimation(.easeInOut(duration: 0.5)) {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: spot.location.latitude, longitude: spot.location.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
        // Sync map selection (tap) to carousel
        .onChange(of: selectedSpot) { spot in
            if let spot = spot,
               let index = viewModel.spots.firstIndex(where: { $0.id == spot.id }),
               index != currentSpotIndex {
                withAnimation {
                    currentSpotIndex = index
                }
            }
        }
    }
    

}

#Preview {
    let viewModel = SpotsViewModel()
    // Inject mock data for preview
    viewModel.spots = [
        TideSpot(
            id: "1",
            name: "Natural Bridges",
            rating: 5,
            location: GeoPoint(latitude: 36.9515, longitude: -122.0573),
            polygon: [
                GeoPoint(latitude: 36.9520, longitude: -122.0580),
                GeoPoint(latitude: 36.9510, longitude: -122.0580),
                GeoPoint(latitude: 36.9510, longitude: -122.0560),
                GeoPoint(latitude: 36.9520, longitude: -122.0560)
            ],
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
    
    return SpotsMapView(viewModel: viewModel)
}
