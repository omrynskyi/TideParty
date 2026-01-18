//
//  PartyService.swift
//  TideParty
//
//  Service for managing multiplayer party operations with Firebase Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PartyService {
    static let shared = PartyService()
    
    private let db = Firestore.firestore()
    private var partyListener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - User ID Helper
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Create Party
    
    /// Creates a new party and returns the 4-digit join code
    func createParty(mode: GameMode, target: Int, locationId: String? = nil, locationName: String? = nil) async throws -> String {
        guard let userId = userId else {
            throw NSError(domain: "PartyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Generate unique code
        let code = try await generateUniqueCode()
        
        // Get current user data for first player
        let player = await getCurrentPlayerData()
        
        // Create party document
        var party = Party(
            code: code,
            hostId: userId,
            locationId: locationId,
            locationName: locationName,
            gameMode: mode,
            targetValue: target,
            players: [player]
        )
        
        // Encode to Firestore-compatible format using Firestore's encoder
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(party)
        
        try await db.collection("parties").document(code).setData(data)
        print("✅ Created party with code: \(code)")
        
        return code
    }
    
    // MARK: - Join Party
    
    /// Joins an existing party with the given code
    func joinParty(code: String) async throws {
        guard let userId = userId else {
            throw NSError(domain: "PartyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let partyRef = db.collection("parties").document(code)
        
        try await db.runTransaction { transaction, errorPointer in
            let partyDoc: DocumentSnapshot
            do {
                partyDoc = try transaction.getDocument(partyRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard partyDoc.exists else {
                let error = NSError(domain: "PartyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Party not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = partyDoc.data(),
                  let statusString = data["status"] as? String,
                  let status = PartyStatus(rawValue: statusString) else {
                let error = NSError(domain: "PartyService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid party data"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if party is joinable
            if status != .waiting && status != .active {
                let error = NSError(domain: "PartyService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Party has already finished"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if user already in party
            if let players = data["players"] as? [[String: Any]],
               players.contains(where: { ($0["id"] as? String) == userId }) {
                // Already in party - this is okay, just return
                return nil
            }
            
            // Add player to party
            let player = self.getCurrentPlayerDataSync()
            transaction.updateData([
                "players": FieldValue.arrayUnion([self.playerToDict(player)])
            ], forDocument: partyRef)
            
            return nil
        }
        
        print("✅ Joined party: \(code)")
    }
    
    // MARK: - Listen to Party
    
    /// Sets up real-time listener for party updates
    func listenToParty(code: String, completion: @escaping (Result<Party, Error>) -> Void) {
        // Remove any existing listener
        stopListening()
        
        partyListener = db.collection("parties").document(code).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                let error = NSError(domain: "PartyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Party not found"])
                completion(.failure(error))
                return
            }
            
            do {
                let party = try snapshot.data(as: Party.self)
                completion(.success(party))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Stops the active party listener
    func stopListening() {
        partyListener?.remove()
        partyListener = nil
    }
    
    /// Updates player's score when they catch a creature (with transaction safety)
    func updateScore(code: String, creatureId: String) async throws -> Int {
        guard let userId = userId else {
            throw NSError(domain: "PartyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let partyRef = db.collection("parties").document(code)
        
        let result = try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let partyDoc: DocumentSnapshot
            do {
                partyDoc = try transaction.getDocument(partyRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return 0
            }
            
            guard let data = partyDoc.data(),
                  let playersData = data["players"] as? [[String: Any]],
                  let playerIndex = playersData.firstIndex(where: { ($0["id"] as? String) == userId }) else {
                let error = NSError(domain: "PartyService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Player not in party"])
                errorPointer?.pointee = error
                return 0
            }
            
            var playerData = playersData[playerIndex]
            var catches = playerData["catches"] as? [String: Int] ?? [:]
            let currentCount = catches[creatureId] ?? 0
            
            // Calculate XP: 100 for first catch, 20 for repeats
            let xpToAdd = currentCount == 0 ? 100 : 20
            
            // Update catches and XP
            catches[creatureId] = currentCount + 1
            let newXP = (playerData["xp"] as? Int ?? 0) + xpToAdd
            
            playerData["catches"] = catches
            playerData["xp"] = newXP
            
            // Rebuild players array
            var updatedPlayers = playersData
            updatedPlayers[playerIndex] = playerData
            
            transaction.updateData([
                "players": updatedPlayers
            ], forDocument: partyRef)
            
            return xpToAdd as Any
        }
        
        let xpGained = result as? Int ?? 0
        print("✅ Updated score: +\(xpGained) XP for catching \(creatureId)")
        return xpGained
    }
    
    /// Adds bonus XP for answering a quiz question correctly
    func addQuizBonus(xp: Int) async throws {
        guard let userId = userId else {
            throw NSError(domain: "PartyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Find current party by checking active listener
        guard let partyListener = partyListener else { return }
        
        // Get current party from cache - we need to find the party code
        // We'll query for parties where this user is a player
        let partiesQuery = db.collection("parties")
            .whereField("status", isNotEqualTo: "finished")
        
        let snapshot = try await partiesQuery.getDocuments()
        
        for doc in snapshot.documents {
            guard let playersData = doc.data()["players"] as? [[String: Any]],
                  let playerIndex = playersData.firstIndex(where: { ($0["id"] as? String) == userId }) else {
                continue
            }
            
            // Found the party with this user
            var playerData = playersData[playerIndex]
            let currentXP = playerData["xp"] as? Int ?? 0
            playerData["xp"] = currentXP + xp
            
            var updatedPlayers = playersData
            updatedPlayers[playerIndex] = playerData
            
            try await doc.reference.updateData([
                "players": updatedPlayers
            ])
            
            print("✅ Added quiz bonus: +\(xp) XP")
            return
        }
    }
    
    // MARK: - Start Party
    
    /// Starts the party (changes status to active and sets start time)
    func startParty(code: String) async throws {
        guard let userId = userId else {
            throw NSError(domain: "PartyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let partyRef = db.collection("parties").document(code)
        let doc = try await partyRef.getDocument()
        
        guard let hostId = doc.data()?["hostId"] as? String, hostId == userId else {
            throw NSError(domain: "PartyService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Only host can start party"])
        }
        
        try await partyRef.updateData([
            "status": PartyStatus.active.rawValue,
            "startTime": FieldValue.serverTimestamp()
        ])
        
        print("✅ Started party: \(code)")
    }
    
    // MARK: - Leave Party
    
    /// Removes current user from party
    func leaveParty(code: String) async throws {
        guard let userId = userId else {
            throw NSError(domain: "PartyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let partyRef = db.collection("parties").document(code)
        
        try await db.runTransaction { transaction, errorPointer in
            let partyDoc: DocumentSnapshot
            do {
                partyDoc = try transaction.getDocument(partyRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = partyDoc.data(),
                  let playersData = data["players"] as? [[String: Any]] else {
                return nil
            }
            
            // Remove player from array
            let updatedPlayers = playersData.filter { ($0["id"] as? String) != userId }
            
            if updatedPlayers.isEmpty {
                // If no players left, delete the party
                transaction.deleteDocument(partyRef)
            } else {
                var updateData: [String: Any] = ["players": updatedPlayers]
                
                // If leaving player was host, promote new host
                if let hostId = data["hostId"] as? String, hostId == userId,
                   let newHostId = updatedPlayers.first?["id"] as? String {
                    updateData["hostId"] = newHostId
                }
                
                transaction.updateData(updateData, forDocument: partyRef)
            }
            
            return nil
        }
        
        print("✅ Left party: \(code)")
    }
    
    // MARK: - Helper Methods
    
    /// Generates a unique 4-digit code
    private func generateUniqueCode() async throws -> String {
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            let code = String(format: "%04d", Int.random(in: 0...9999))
            
            // Check if code already exists
            let doc = try await db.collection("parties").document(code).getDocument()
            if !doc.exists {
                return code
            }
            
            attempts += 1
        }
        
        throw NSError(domain: "PartyService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to generate unique code"])
    }
    
    /// Gets current player data from UserStatsService
    private func getCurrentPlayerData() async -> PartyPlayer {
        let stats = UserStatsService.shared
        let userId = Auth.auth().currentUser?.uid ?? "unknown"
        let name = stats.displayName.isEmpty ? "Player" : stats.displayName
        let badgeId = stats.selectedBadgeId
        
        return PartyPlayer(
            id: userId,
            name: name,
            avatar: badgeId,
            xp: 0,
            catches: [:]
        )
    }
    
    /// Synchronous version for use in transactions
    private func getCurrentPlayerDataSync() -> PartyPlayer {
        let stats = UserStatsService.shared
        let userId = Auth.auth().currentUser?.uid ?? "unknown"
        let name = stats.displayName.isEmpty ? "Player" : stats.displayName
        let badgeId = stats.selectedBadgeId
        
        return PartyPlayer(
            id: userId,
            name: name,
            avatar: badgeId,
            xp: 0,
            catches: [:]
        )
    }
    
    /// Converts PartyPlayer to dictionary for Firestore
    private func playerToDict(_ player: PartyPlayer) -> [String: Any] {
        return [
            "id": player.id,
            "name": player.name,
            "avatar": player.avatar,
            "xp": player.xp,
            "catches": player.catches
        ]
    }
    
    nonisolated deinit {
        partyListener?.remove()
    }
}
