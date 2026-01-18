//
//  PartyModels.swift
//  TideParty
//
//  Data models for multiplayer Tide Party feature
//

import Foundation
import FirebaseFirestore

// MARK: - Enums

enum GameMode: String, Codable {
    case timeTrial = "time_trial"
    case scoreRace = "score_race"
    
    var displayName: String {
        switch self {
        case .timeTrial: return "Time Trial"
        case .scoreRace: return "Score Race"
        }
    }
}

enum PartyStatus: String, Codable {
    case waiting = "waiting"
    case active = "active"
    case finished = "finished"
}

// MARK: - Player Model

struct PartyPlayer: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let avatar: String // Placeholder for now (e.g., "🦦")
    var xp: Int
    var catches: [String: Int] // creatureId -> count
    
    init(id: String, name: String, avatar: String = "🦦", xp: Int = 0, catches: [String: Int] = [:]) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.xp = xp
        self.catches = catches
    }
    
    /// Get catch count for a specific creature
    func getCatchCount(for creatureId: String) -> Int {
        catches[creatureId] ?? 0
    }
    
    /// Check if this is a first catch
    func isFirstCatch(of creatureId: String) -> Bool {
        catches[creatureId] == nil || catches[creatureId] == 0
    }
}

// MARK: - Party Model

struct Party: Codable, Identifiable {
    let id: String // Same as code
    let code: String
    let hostId: String
    let locationId: String? // Optional TideSpot reference
    let locationName: String? // Cached for display
    var status: PartyStatus
    let gameMode: GameMode
    let targetValue: Int // Seconds for timeTrial, XP for scoreRace
    var startTime: Date?
    var endTime: Date?
    var players: [PartyPlayer]
    
    // MARK: - Initialization
    
    init(code: String, hostId: String, locationId: String? = nil, locationName: String? = nil,
         gameMode: GameMode, targetValue: Int, players: [PartyPlayer] = []) {
        self.id = code
        self.code = code
        self.hostId = hostId
        self.locationId = locationId
        self.locationName = locationName
        self.status = .waiting
        self.gameMode = gameMode
        self.targetValue = targetValue
        self.startTime = nil
        self.endTime = nil
        self.players = players
    }
    
    // MARK: - Computed Properties
    
    /// Get player by user ID
    func getPlayer(by userId: String) -> PartyPlayer? {
        players.first { $0.id == userId }
    }
    
    /// Get player index in sorted list (by XP, descending)
    func getPlayerRank(userId: String) -> Int? {
        let sorted = players.sorted { $0.xp > $1.xp }
        return sorted.firstIndex { $0.id == userId }.map { $0 + 1 }
    }
    
    /// Check if user is the host
    func isHost(userId: String) -> Bool {
        hostId == userId
    }
    
    /// Get leading player
    var leader: PartyPlayer? {
        players.max { $0.xp < $1.xp }
    }
    
    /// Time remaining (for time trials)
    var timeRemaining: TimeInterval? {
        guard gameMode == .timeTrial,
              let start = startTime,
              status == .active else { return nil }
        
        let elapsed = Date().timeIntervalSince(start)
        let total = TimeInterval(targetValue)
        return max(0, total - elapsed)
    }
    
    /// Formatted time remaining string
    var timeRemainingFormatted: String? {
        guard let remaining = timeRemaining else { return nil }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Progress towards goal (0.0 - 1.0)
    func progress(for userId: String) -> Double {
        guard let player = getPlayer(by: userId) else { return 0.0 }
        
        switch gameMode {
        case .scoreRace:
            return min(1.0, Double(player.xp) / Double(targetValue))
        case .timeTrial:
            // For time trials, progress is based on XP relative to leader
            guard let maxXP = players.map(\.xp).max(), maxXP > 0 else { return 0.0 }
            return Double(player.xp) / Double(maxXP)
        }
    }
    
    /// Check if party has reached completion
    var isComplete: Bool {
        switch gameMode {
        case .scoreRace:
            return players.contains { $0.xp >= targetValue }
        case .timeTrial:
            guard let start = startTime else { return false }
            return Date().timeIntervalSince(start) >= TimeInterval(targetValue)
        }
    }
    
    /// Players sorted by XP (descending)
    var sortedPlayers: [PartyPlayer] {
        players.sorted { $0.xp > $1.xp }
    }
}
