import SwiftUI
import FirebaseFirestore

struct SpotCardView: View {
    let spot: TideSpot
    let tideHeight: Double
    let onGoTidePooling: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Locals Favorite Badge
            if spot.isLocalsFavorite {
                Text("Locals Favorite ✨")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("MainBlue"))
            }
            
            // Name and Rating Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    // Stats Row
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            Text(String(format: "%.0f'", tideHeight))
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        
                        if let distance = spot.distanceInMiles {
                            Text("•")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.1f mi", distance))
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Star Rating
                HStack(spacing: 2) {
                    ForEach(0..<spot.rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Go Tide Pooling Button - fit to content, centered
            HStack {
                Spacer()
                Button(action: onGoTidePooling) {
                    Text("Go Tide Pooling")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(spot.isLocalsFavorite ? .white : Color("MainBlue"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(
                            spot.isLocalsFavorite
                                ? Color("MainBlue")
                                : Color.gray.opacity(0.1)
                        )
                        .cornerRadius(30)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            spot.isLocalsFavorite 
                ? Color("MainBlue").opacity(0.1) 
                : Color.white
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        SpotCardView(
            spot: TideSpot(
                id: "test",
                name: "Davenport Landing",
                rating: 5,
                location: GeoPoint(latitude: 36.97, longitude: -122.03),
                polygon: [],
                imageName: nil
            ),
            tideHeight: 3.0,
            onGoTidePooling: {}
        )
        
        SpotCardView(
            spot: TideSpot(
                id: "test2",
                name: "Natural Bridges",
                rating: 3,
                location: GeoPoint(latitude: 36.95, longitude: -122.05),
                polygon: [],
                imageName: nil
            ),
            tideHeight: 3.0,
            onGoTidePooling: {}
        )
    }
    .padding()
}
