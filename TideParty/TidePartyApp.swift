import SwiftUI
import FirebaseCore

enum Route {
    case spots
}

@main
struct TidePartyApp: App {
    @State private var navigationPath = NavigationPath()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationPath) {
                LandingView(onFindSpots: {
                    navigationPath.append(Route.spots)
                })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .spots:
                        SpotsListView()
                    }
                }
            }
        }
    }
}
