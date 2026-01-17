import SwiftUI
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String? = nil
    // Step 0: Name, 1: Email, 2: Password, 3: Safety
    @Published var currentStep: Int = 0
    
    /// Smart auth: Try sign-in first, fallback to create if user doesn't exist
    func authenticate() async throws {
        errorMessage = nil
        
        do {
            // First, try to sign in
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Update display name if provided
            if !username.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = username
                try await changeRequest.commitChanges()
            }
            print("User signed in: \(result.user.uid)")
            
            // Save locally and fetch/create stats
            UserDefaults.standard.set(username.isEmpty ? result.user.displayName : username, forKey: "displayName")
            try? await UserStatsService.shared.fetchStats()
            
        } catch let error as NSError {
            // Check if the error is "user not found"
            if error.code == AuthErrorCode.userNotFound.rawValue {
                // User doesn't exist, so create a new account
                do {
                    let result = try await Auth.auth().createUser(withEmail: email, password: password)
                    let changeRequest = result.user.createProfileChangeRequest()
                    changeRequest.displayName = username
                    try await changeRequest.commitChanges()
                    print("User created: \(result.user.uid)")
                    
                    // Create new user stats document
                    try await UserStatsService.shared.createUserStats(displayName: username)
                } catch {
                    print("Create failed: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    throw error
                }
            } else {
                // Other errors (wrong password, etc.)
                print("Sign in failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                throw error
            }
        }
    }
    
    /// Sign in with Google
    func signInWithGoogle() async throws {
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Firebase Client ID"
            throw NSError(domain: "OnboardingViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firebase Client ID"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "No root view controller"
            throw NSError(domain: "OnboardingViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                throw NSError(domain: "OnboardingViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Google ID token"])
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Update display name if we have a username
            if !username.isEmpty {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = username
                try await changeRequest.commitChanges()
            }
            
            print("Google sign-in successful: \(authResult.user.uid)")
            
            // Save locally and fetch/create stats
            let name = username.isEmpty ? (authResult.user.displayName ?? "") : username
            UserDefaults.standard.set(name, forKey: "displayName")
            try? await UserStatsService.shared.createUserStats(displayName: name)
            
        } catch {
            print("Google sign-in failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
}
