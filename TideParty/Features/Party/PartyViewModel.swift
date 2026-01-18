//
//  PartyViewModel.swift
//  TideParty
//
//  View model for managing party state and real-time updates
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class PartyViewModel: ObservableObject {
    static let shared = PartyViewModel()
    
    // MARK: - Published Properties
    
    @Published var currentParty: Party?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var partyCode: String = ""
    @Published var showSuccessMessage: Bool = false
    @Published var lastXPGain: Int = 0
    
    // Win screen state
    @Published var showWinScreen: Bool = false
    @Published var raceResults: [PartyPlayer] = [] // Top 3 players sorted by XP
    
    // MARK: - Private Properties
    
    private let partyService = PartyService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Computed Properties
    
    var isInParty: Bool {
        currentParty != nil
    }
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isHost: Bool {
        guard let userId = currentUserId, let party = currentParty else { return false }
        return party.isHost(userId: userId)
    }
    
    /// Get current user's player data
    var currentPlayer: PartyPlayer? {
        guard let userId = currentUserId else { return nil }
        return currentParty?.getPlayer(by: userId)
    }
    
    /// Get current user's rank (1-based)
    var currentRank: Int? {
        guard let userId = currentUserId else { return nil }
        return currentParty?.getPlayerRank(userId: userId)
    }
    
    /// Calculate progress for a specific player (0.0 - 1.0)
    func playerProgress(userId: String) -> Double {
        currentParty?.progress(for: userId) ?? 0.0
    }
    
    // MARK: - Party Creation
    
    /// Creates a new party
    func createNewParty(mode: GameMode, target: Int, locationId: String? = nil, locationName: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let code = try await partyService.createParty(
                mode: mode,
                target: target,
                locationId: locationId,
                locationName: locationName
            )
            
            partyCode = code
            await startListening(to: code)
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Join Party
    
    /// Joins an existing party by code
    func joinExistingParty() async {
        guard !partyCode.isEmpty, partyCode.count == 4 else {
            errorMessage = "Please enter a 4-digit code"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await partyService.joinParty(code: partyCode)
            await startListening(to: partyCode)
            
            isLoading = false
            showSuccessMessage = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Real-time Listening
    
    /// Starts listening to party updates
    func startListening(to code: String) async {
        partyService.listenToParty(code: code) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let party):
                    self.currentParty = party
                    
                    // Check if party is complete
                    if party.isComplete && party.status == .active {
                        await self.finishParty()
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Stops listening to party updates
    func stopListening() {
        partyService.stopListening()
        currentParty = nil
        partyCode = ""
    }
    
    // MARK: - Score Updates
    
    /// Records a creature catch and updates score
    func recordCatch(creatureId: String) async {
        guard let code = currentParty?.code else {
            print("⚠️ No active party to record catch")
            return
        }
        
        do {
            let xpGained = try await partyService.updateScore(code: code, creatureId: creatureId)
            
            // Show XP gain feedback
            lastXPGain = xpGained
            showSuccessMessage = true
            
            // Auto-hide after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showSuccessMessage = false
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Calculate XP that would be gained for catching a creature
    func calculateXP(for creatureId: String) -> Int {
        guard let player = currentPlayer else { return 100 }
        return player.isFirstCatch(of: creatureId) ? 100 : 20
    }
    
    // MARK: - Party Control
    
    /// Starts the party (host only)
    func startParty() async {
        guard isHost, let code = currentParty?.code else { return }
        
        do {
            try await partyService.startParty(code: code)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Finishes the party and shows win screen
    private func finishParty() async {
        guard let party = currentParty else { return }
        
        // Get top 3 players sorted by XP (descending)
        let sortedPlayers = party.sortedPlayers
        raceResults = Array(sortedPlayers.prefix(3))
        
        // Show win screen
        showWinScreen = true
        
        print("🏁 Party completed! Winner: \(raceResults.first?.name ?? "Unknown")")
    }
    
    /// Dismisses win screen and leaves party
    func dismissWinScreen() async {
        showWinScreen = false
        raceResults = []
        await leaveParty()
    }
    
    /// Leaves the current party
    func leaveParty() async {
        guard let code = currentParty?.code else { return }
        
        do {
            try await partyService.leaveParty(code: code)
            stopListening()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Quick Start Helpers
    
    /// Quick create: 10-minute time trial
    func createQuickTimeTrial() async {
        await createNewParty(mode: .timeTrial, target: 600) // 10 minutes
    }
    
    /// Quick create: First to 500 XP
    func createQuickScoreRace() async {
        await createNewParty(mode: .scoreRace, target: 500)
    }
    
    // MARK: - Validation
    
    var isValidCode: Bool {
        partyCode.count == 4 && partyCode.allSatisfy { $0.isNumber }
    }
    
    nonisolated deinit {
        Task { @MainActor in
            PartyService.shared.stopListening()
        }
    }
}
