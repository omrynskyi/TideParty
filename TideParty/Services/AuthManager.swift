import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isLoading: Bool = true
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isLoading = false
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
