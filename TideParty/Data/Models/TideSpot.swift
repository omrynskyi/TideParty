import Foundation
import CoreLocation
import FirebaseFirestore

struct TideSpot: Identifiable, Codable {
    let id: String
    let name: String
    let rating: Int
    let location: GeoPoint
    let polygon: [GeoPoint]
    var imageName: String?
    
    // Distance from user (calculated at runtime, not stored in Firestore)
    var distanceInMiles: Double?
    
    var isLocalsFavorite: Bool {
        return rating == 5
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
    
    var polygonCoordinates: [CLLocationCoordinate2D] {
        polygon.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, rating, location, polygon, imageName
    }
}
