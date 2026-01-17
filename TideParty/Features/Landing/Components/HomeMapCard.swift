import SwiftUI
import MapKit

struct HomeMapCard: View {
    @ObservedObject var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .frame(height: 220)
        .onReceive(locationManager.$region) { newRegion in
            cameraPosition = .region(newRegion)
        }
        .onAppear {
            if locationManager.userLocation != nil {
                cameraPosition = .region(locationManager.region)
            }
        }
    }
}

#Preview {
    HomeMapCard()
        .padding()
}
