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
    private var cancellables = Set<AnyCancellable>()
    
    // Geocoding control
    private let geocoder = CLGeocoder()
    private var geocodeTask: Task<Void, Never>?
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodeAt: Date = .distantPast
    private let minDistanceMeters: CLLocationDistance = 250        // only geocode if moved > 250m
    private let minInterval: TimeInterval = 1.0                    // at most 1 request per second
    
    init() {
        setupSubscriptions()
        Task {
            await fetchCurrentCity()   // initial best-effort if we already have a location
            await fetchSpots()
        }
    }
    
    private func setupSubscriptions() {
        // Debounce user location updates so we don't geocode on every tiny change
        locationManager.$userLocation
            .compactMap { $0 }                // ignore nils
            .removeDuplicates(by: { lhs, rhs in
                // Consider duplicates if within a very small distance to avoid churn
                lhs.distance(from: rhs) < 5
            })
            .debounce(for: .milliseconds(600), scheduler: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                Task {
                    await self.fetchCurrentCityIfNeeded(for: location)
                    self.updateSpotDistances(userLocation: location)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func fetchCurrentCityIfNeeded(for location: CLLocation) async {
        // 1) Distance threshold
        if let last = lastGeocodedLocation, location.distance(from: last) < minDistanceMeters {
            return
        }
        // 2) Rate limit
        if Date().timeIntervalSince(lastGeocodeAt) < minInterval {
            return
        }
        await fetchCurrentCity(for: location)
    }
    
    @MainActor
    func fetchCurrentCity() async {
        guard let location = locationManager.userLocation else { return }
        await fetchCurrentCity(for: location)
    }
    
    @MainActor
    private func fetchCurrentCity(for location: CLLocation) async {
        // Cancel any in-flight geocode
        geocodeTask?.cancel()
        
        geocodeTask = Task { [weak self] in
            guard let self = self else { return }
            self.lastGeocodeAt = Date()
            
            do {
                // If CLGeocoder has a running request, cancel it
                if self.geocoder.isGeocoding {
                    self.geocoder.cancelGeocode()
                }
                
                let placemarks = try await self.geocoder.reverseGeocodeLocation(location)
                if Task.isCancelled { return }
                
                if let city = placemarks.first?.locality, !city.isEmpty {
                    await MainActor.run {
                        self.currentCity = city
                        self.lastGeocodedLocation = location
                    }
                }
            } catch {
                // Handle throttling/network errors with a small backoff
                // GEOErrorDomain -3 or kCLErrorDomain Code=2 often indicate throttling/network
                // Respect the system throttle window; back off briefly.
                // You could parse timeUntilReset from the error if available; here we use 2s.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
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
    
    private func updateSpotDistances(userLocation: CLLocation) {
        var updatedSpots = spots
        for i in 0..<updatedSpots.count {
            let spotLocation = CLLocation(
                latitude: updatedSpots[i].location.latitude,
                longitude: updatedSpots[i].location.longitude
            )
            updatedSpots[i].distanceInMiles = userLocation.distance(from: spotLocation) / 1609.34
        }
        
        spots = updatedSpots.sorted {
            if $0.isLocalsFavorite != $1.isLocalsFavorite {
                return $0.isLocalsFavorite
            }
            return ($0.distanceInMiles ?? 999) < ($1.distanceInMiles ?? 999)
        }
    }
    
    @MainActor
    func refresh() async {
        await fetchCurrentCity()
        await fetchSpots()
    }
}
