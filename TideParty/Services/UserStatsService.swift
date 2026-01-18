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
    @Published var creatureCounts: [String: Int] = [:]  // creature name -> catch count
    @Published var locationsVisited: Int = 0
    @Published var quizCorrect: Int = 0
    @Published var selectedBadgeId: Int = 0  // ID of the badge the user selected as profile icon
    
    private init() {
        // Load from UserDefaults on init
        displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
        if let counts = UserDefaults.standard.dictionary(forKey: "creatureCounts") as? [String: Int] {
            creatureCounts = counts
        }
        selectedBadgeId = UserDefaults.standard.integer(forKey: "selectedBadgeId")
    }
    
    // MARK: - User ID Helper
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Create User Stats Document
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
            "creatureCounts": [:],
            "locationsVisited": 0,
            "quizCorrect": 0,
            "selectedBadgeId": 0,
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
            if let counts = data["creatureCounts"] as? [String: Int] {
                self.creatureCounts = counts
            }
            self.locationsVisited = data["locationsVisited"] as? Int ?? 0
            self.quizCorrect = data["quizCorrect"] as? Int ?? 0
            self.selectedBadgeId = data["selectedBadgeId"] as? Int ?? 0
            
            // Cache locally
            UserDefaults.standard.set(displayName, forKey: "displayName")
            UserDefaults.standard.set(creatureCounts, forKey: "creatureCounts")
            UserDefaults.standard.set(selectedBadgeId, forKey: "selectedBadgeId")
        }
    }
    
    // MARK: - Capture Creature
    /// Returns the new catch count for this creature (1 = first catch, 2+ = repeat)
    @discardableResult
    func captureCreature(name: String) async throws -> Int {
        guard let userId = userId else { return 0 }
        
        // Increment local count
        let newCount = (creatureCounts[name] ?? 0) + 1
        creatureCounts[name] = newCount
        UserDefaults.standard.set(creatureCounts, forKey: "creatureCounts")
        
        // Update Firestore
        try await db.collection("users").document(userId).updateData([
            "creatureCounts.\(name)": newCount
        ])
        
        if newCount == 1 {
            print("✅ First catch of \(name)! (unique creatures: \(uniqueCreatureCount))")
        } else {
            print("🔄 Caught \(name) again! (count: \(newCount))")
        }
        
        return newCount
    }
    
    // MARK: - Increment Quiz Score
    func incrementQuizCorrect() {
        guard let userId = userId else { return }
        
        quizCorrect += 1
        UserDefaults.standard.set(quizCorrect, forKey: "quizCorrect") // Update local immediately
        
        // Update Firestore
        db.collection("users").document(userId).updateData([
            "quizCorrect": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating quiz score: \(error)")
            } else {
                print("✅ Quiz score incremented!")
            }
        }
    }
    
    // MARK: - Set Selected Badge
    func setSelectedBadge(_ badgeId: Int) {
        guard let userId = userId else { return }
        
        selectedBadgeId = badgeId
        UserDefaults.standard.set(badgeId, forKey: "selectedBadgeId")
        
        // Update Firestore
        db.collection("users").document(userId).updateData([
            "selectedBadgeId": badgeId
        ]) { error in
            if let error = error {
                print("Error updating selected badge: \(error)")
            } else {
                print("✅ Selected badge updated to \(badgeId)!")
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Number of unique creatures caught
    var uniqueCreatureCount: Int {
        creatureCounts.count
    }
    
    /// Get catch count for a specific creature
    func getCatchCount(for name: String) -> Int {
        creatureCounts[name] ?? 0
    }
    
    /// Check if creature has been caught before
    func isCreatureCaptured(_ name: String) -> Bool {
        creatureCounts[name] != nil
    }
    
    // MARK: - Next Badge Logic
    
    struct NextBadge {
        let title: String // e.g., "Creature Expert Badge"
        let subtitle: String // e.g., "2 unique creatures away"
        let progress: Double // 0.0 to 1.0
        let icon: String // "tortoise.fill", "map.fill", etc.
    }
    
    /// Milestones for badges
    private let creatureMilestones = [1, 5, 10, 20, 40]
    private let quizMilestones = [1, 5, 10, 20, 40]
    private let locationMilestones = [1, 3, 5, 7, 10]
    
    /// Computes the stats for the "closest" badge
    var nextBadge: NextBadge {
        // 1. Calculate distances and progress for each category
        
        // Creatures
        let (creatureNext, creatureDist, creatureProg) = calculateMilestone(current: uniqueCreatureCount, milestones: creatureMilestones)
        // Quiz
        let (quizNext, quizDist, quizProg) = calculateMilestone(current: quizCorrect, milestones: quizMilestones)
        // Locations (distance multiplied by 5 as requested)
        let (locNext, locRawDist, locProg) = calculateMilestone(current: locationsVisited, milestones: locationMilestones)
        let locDist = locRawDist * 5
        
        // 2. Find the winner (minimum distance)
        // Default to creatures if tie
        
        if locDist < creatureDist && locDist < quizDist {
            // Locations win
            // Singular/plural logic
            let noun = locRawDist == 1 ? "location" : "locations"
            return NextBadge(
                title: "Explorer Badge",
                subtitle: "\(locRawDist) \(noun) away from Explorer Level \(locationMilestones.firstIndex(of: locNext)! + 1)",
                progress: locProg,
                icon: "map.fill"
            )
        } else if quizDist < creatureDist {
            // Quiz wins
            let noun = quizDist == 1 ? "quiz" : "quizzes"
            return NextBadge(
                title: "Brainiac Badge",
                subtitle: "\(quizDist) \(noun) away from Brainiac Level \(quizMilestones.firstIndex(of: quizNext)! + 1)",
                progress: quizProg,
                icon: "lightbulb.fill"
            )
        } else {
            // Creatures win (default)
            let noun = creatureDist == 1 ? "creature" : "creatures"
            let level = (creatureMilestones.firstIndex(of: creatureNext) ?? 0) + 1
            
            // Special case for very first badge
            if uniqueCreatureCount == 0 {
                return NextBadge(
                    title: "Novice Discoverer",
                    subtitle: "1 tide creature away from First Catch",
                    progress: 0.0,
                    icon: "tortoise.fill"
                )
            }
            
            return NextBadge(
                title: "Collector Badge",
                subtitle: "\(creatureDist) unique \(noun) away from Level \(level)",
                progress: creatureProg,
                icon: "tortoise.fill"
            )
        }
    }
    
    /// Helper to find next milestone, distance to it, and current progress towards it
    private func calculateMilestone(current: Int, milestones: [Int]) -> (next: Int, distance: Int, progress: Double) {
        // Find first milestone greater than current
        guard let next = milestones.first(where: { $0 > current }) else {
            // Maxed out? Return max values
            let max = milestones.last ?? 100
            return (max, 0, 1.0)
        }
        
        // Absolute progress: current / next threshold
        // e.g., if next is 10 and you have 5, progress is 50%
        let fraction = next > 0 ? Double(current) / Double(next) : 0.0
        let distance = next - current
        
        return (next, distance, fraction)
    }
}
