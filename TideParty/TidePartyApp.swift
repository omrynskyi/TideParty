import SwiftUI
import FirebaseCore

enum Route {
    case spots
    case scanner
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TidePartyApp: App {
    @StateObject private var authManager = AuthManager.shared
    @State private var navigationPath = NavigationPath()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    // Show loading while checking auth state
                    ZStack {
                        Color("MainBlue").ignoresSafeArea()
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                } else if authManager.currentUser != nil {
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
                } else {
                    OnboardingContainerView()
                }
            }
        }
    }
}
