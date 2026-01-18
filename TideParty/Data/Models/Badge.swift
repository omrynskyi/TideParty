//
//  Badge.swift
//  TideParty
//
//  Model representing achievement badges with unlock logic
//

import Foundation

enum BadgeCategory: String, CaseIterable {
    case creatures = "Creatures Found"
    case places = "Places Visited"
    case quizzes = "Quiz Correct"
}

struct Badge: Identifiable {
    let id: Int
    let name: String
    let imageName: String
    let category: BadgeCategory
    let threshold: Int
    
    /// Check if badge is unlocked based on user stats
    func isUnlocked(creatures: Int, places: Int, quizzes: Int) -> Bool {
        switch category {
        case .creatures:
            return creatures >= threshold
        case .places:
            return places >= threshold
        case .quizzes:
            return quizzes >= threshold
        }
    }
    
    /// All badges defined in order
    static let allBadges: [Badge] = [
        // Creatures Found
        Badge(id: 0, name: "Sardine", imageName: "SardineBadge", category: .creatures, threshold: 0),
        Badge(id: 1, name: "Sea Anemone", imageName: "SeaAnenomeBadge", category: .creatures, threshold: 1),
        Badge(id: 2, name: "Clownfish", imageName: "ClownfishBadge", category: .creatures, threshold: 5),
        Badge(id: 3, name: "Seahorse", imageName: "SeahorseBadge", category: .creatures, threshold: 10),
        Badge(id: 4, name: "Turtle", imageName: "TurtleBadge", category: .creatures, threshold: 20),
        Badge(id: 5, name: "Otter", imageName: "OtterBadge", category: .creatures, threshold: 40),
        
        // Places Visited
        Badge(id: 6, name: "Crab", imageName: "CrabBadge", category: .places, threshold: 1),
        Badge(id: 7, name: "Eel", imageName: "EelBadge", category: .places, threshold: 5),
        Badge(id: 8, name: "Whale", imageName: "WhaleBadge", category: .places, threshold: 10),
        Badge(id: 9, name: "Shark", imageName: "SharkBadge", category: .places, threshold: 20),
        
        // Quiz Correct
        Badge(id: 10, name: "Mussels", imageName: "MusselsBadge", category: .quizzes, threshold: 1),
        Badge(id: 11, name: "Starfish", imageName: "StarfishBadge", category: .quizzes, threshold: 5),
        Badge(id: 12, name: "Sponge", imageName: "SpongeBadge", category: .quizzes, threshold: 10),
        Badge(id: 13, name: "Octopus", imageName: "OctopusBadge", category: .quizzes, threshold: 20),
        Badge(id: 14, name: "Jellyfish", imageName: "JellyfishBadge", category: .quizzes, threshold: 40),
    ]
    
    /// Get badge by ID
    static func badge(for id: Int) -> Badge? {
        allBadges.first { $0.id == id }
    }
    
    /// Get badges filtered by category
    static func badges(for category: BadgeCategory) -> [Badge] {
        allBadges.filter { $0.category == category }
    }
}
