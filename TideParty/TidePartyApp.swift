import SwiftUI
import FirebaseCore

enum Route {
    case spots
    case scanner
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
                LandingView(
                    onFindSpots: {
                        navigationPath.append(Route.spots)
                    },
                    onOpenCamera: {
                        navigationPath.append(Route.scanner)
                    }
                )
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .spots:
                        SpotsContainerView(onOpenCamera: {
                            navigationPath.append(Route.scanner)
                        })
                    case .scanner:
                        ScannerView()
                            .navigationBarBackButtonHidden(true)
                    }
                }
            }
        }
    }
}
