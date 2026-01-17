import Foundation
import MapKit
import FirebaseFirestore

struct SpotCluster: Identifiable {
    let id = UUID()
    let spots: [TideSpot]
    
    var coordinate: CLLocationCoordinate2D {
        // Calculate centroid of all spots in cluster
        let avgLat = spots.map { $0.location.latitude }.reduce(0, +) / Double(spots.count)
        let avgLon = spots.map { $0.location.longitude }.reduce(0, +) / Double(spots.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}
