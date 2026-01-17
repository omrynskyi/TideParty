import SwiftUI
import FirebaseCore

@main
struct TidePartyApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ScannerView()
            // SpotsListView()
            // LandingView()
        }
    }
}

