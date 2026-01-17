import SwiftUI
import MapKit
import FirebaseFirestore
struct SpotsListView: View {
    @ObservedObject var viewModel: SpotsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
                                    openInMaps(spot: spot)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Bottom padding for wave section (180 approx height of wave + bottom safe area)
                Spacer().frame(height: 180)
            }
            .padding(.top, 16) // Spacing from sticky header
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private func openInMaps(spot: TideSpot) {
        let coordinate = CLLocationCoordinate2D(
            latitude: spot.location.latitude,
            longitude: spot.location.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spot.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    SpotsListView(viewModel: SpotsViewModel())
}
