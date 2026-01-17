import Foundation
import SwiftUI
import CoreLocation
import FirebaseFirestore
import Combine

class SpotsViewModel: ObservableObject {
    @Published var spots: [TideSpot] = []
    @Published var currentCity: String = "Santa Cruz"
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let locationManager = LocationManager.shared
    
    init() {
        Task {
            await fetchCurrentCity()
            await fetchSpots()
        }
    }
    
    @MainActor
    func fetchCurrentCity() async {
        guard let location = locationManager.userLocation else { return }
        
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let city = placemarks.first?.locality {
                currentCity = city
            }
        } catch {
            print("Geocoding error: \(error)")
        }
    }
    
    @MainActor
    func fetchSpots() async {
        isLoading = true
        error = nil
        
        do {
            let snapshot = try await db.collection("spots").getDocuments()
            print("📦 Fetched \(snapshot.documents.count) documents")
            
            var fetchedSpots: [TideSpot] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let rating = data["rating"] as? Int,
                      let location = data["location"] as? GeoPoint else {
                    print("⚠️ Skipping \(document.documentID)")
                    print("   name type: \(type(of: data["name"]))")
                    print("   rating type: \(type(of: data["rating"]))")
                    print("   location type: \(type(of: data["location"]))")
                    print("   polygon type: \(type(of: data["polygon"]))")
                    continue
                }
                
                // Polygon can be [GeoPoint] or missing
                let polygonData = data["polygon"] as? [GeoPoint] ?? []
                
                var spot = TideSpot(
                    id: document.documentID,
                    name: name,
                    rating: rating,
                    location: location,
                    polygon: polygonData,
                    imageName: data["imageName"] as? String
                )
                
                if let userLocation = locationManager.userLocation {
                    let spotLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    spot.distanceInMiles = userLocation.distance(from: spotLocation) / 1609.34
                }
                
                fetchedSpots.append(spot)
                print("✅ \(name)")
            }
            
            // Sort: favorites first, then by distance
            spots = fetchedSpots.sorted { 
                if $0.isLocalsFavorite != $1.isLocalsFavorite {
                    return $0.isLocalsFavorite
                }
                return ($0.distanceInMiles ?? 999) < ($1.distanceInMiles ?? 999)
            }
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Firestore error: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func refresh() async {
        await fetchCurrentCity()
        await fetchSpots()
    }
}
