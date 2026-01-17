//
//  UserStatsService.swift
//  TideParty
//
//  Service for managing user statistics in Firebase Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class UserStatsService: ObservableObject {
    static let shared = UserStatsService()
    
    private let db = Firestore.firestore()
    
    @Published var displayName: String = ""
    @Published var uniqueCreatures: Set<String> = []
    @Published var locationsVisited: Int = 0
    @Published var quizCorrect: Int = 0
    
    private init() {
        // Load from UserDefaults on init
        displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
        if let creatures = UserDefaults.standard.array(forKey: "uniqueCreatures") as? [String] {
            uniqueCreatures = Set(creatures)
        }
    }
    
    // MARK: - User ID Helper
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Create User Stats Document
    /// Called after successful onboarding to create initial stats document
    func createUserStats(displayName: String) async throws {
        guard let userId = userId else {
            throw NSError(domain: "UserStatsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Save locally
        self.displayName = displayName
        UserDefaults.standard.set(displayName, forKey: "displayName")
        
        // Create Firestore document
        let data: [String: Any] = [
            "displayName": displayName,
            "uniqueCreatures": [],
            "locationsVisited": 0,
            "quizCorrect": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(userId).setData(data, merge: true)
        print("✅ Created user stats document for \(userId)")
    }
    
    // MARK: - Fetch User Stats
    func fetchStats() async throws {
        guard let userId = userId else { return }
        
        let doc = try await db.collection("users").document(userId).getDocument()
        
        if let data = doc.data() {
            self.displayName = data["displayName"] as? String ?? ""
            if let creatures = data["uniqueCreatures"] as? [String] {
                self.uniqueCreatures = Set(creatures)
            }
            self.locationsVisited = data["locationsVisited"] as? Int ?? 0
            self.quizCorrect = data["quizCorrect"] as? Int ?? 0
            
            // Cache locally
            UserDefaults.standard.set(displayName, forKey: "displayName")
            UserDefaults.standard.set(Array(uniqueCreatures), forKey: "uniqueCreatures")
        }
    }
    
    // MARK: - Increment Creature (only if unique)
    /// Returns true if creature was new and added, false if already captured
    @discardableResult
    func incrementCreature(name: String) async throws -> Bool {
        guard let userId = userId else { return false }
        
        // Check if already captured locally first (fast check)
        if uniqueCreatures.contains(name) {
            print("🔄 \(name) already captured, not incrementing")
            return false
        }
        
        // Add to local set
        uniqueCreatures.insert(name)
        UserDefaults.standard.set(Array(uniqueCreatures), forKey: "uniqueCreatures")
        
        // Update Firestore with array union (atomic, prevents duplicates)
        try await db.collection("users").document(userId).updateData([
            "uniqueCreatures": FieldValue.arrayUnion([name])
        ])
        
        print("✅ Added new creature: \(name) (total: \(uniqueCreatures.count))")
        return true
    }
    
    // MARK: - Creature Count
    var creatureCount: Int {
        uniqueCreatures.count
    }
    
    // MARK: - Check if Creature Already Captured
    func isCreatureCaptured(_ name: String) -> Bool {
        uniqueCreatures.contains(name)
    }
}
