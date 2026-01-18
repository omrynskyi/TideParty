//
//  PartyRaceView.swift
//  TideParty
//
//  Live race view showing real-time player progress
//

import SwiftUI

struct PartyRaceView: View {
    @StateObject private var viewModel = PartyViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false
    @State private var waveOffset: Double = 0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if let party = viewModel.currentParty {
                VStack(spacing: 0) {
                    // Header with leave button
                    headerSection(party: party)
                    
                    // Player list
                    playerListSection(party: party)
                    
                    Spacer()
                    
                    // Footer with camera button
                    footerSection
                }
                .ignoresSafeArea(edges: .bottom) // Let waves go to bottom
            } else {
                // Loading or error state
                VStack {
                    if viewModel.isLoading {
                        ProgressView()
                        Text("Loading party...")
                            .padding(.top)
                    } else {
                        Text("Party not found")
                        Button("Go Back") {
                            dismiss()
                        }
                        .padding(.top)
                    }
                }
            }
            
            // XP gain notification
            if viewModel.showSuccessMessage {
                xpGainNotification
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showCamera) {
            ScannerView()
        }
        .fullScreenCover(isPresented: $viewModel.showWinScreen) {
            RaceWinView(results: viewModel.raceResults) {
                Task {
                    await viewModel.dismissWinScreen()
                    dismiss()
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                waveOffset = 1.0
            }
        }
    }
    
    // ... header and player list ...

    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Camera button area with waves
            ZStack(alignment: .bottom) {
                // Computed waves - even taller
                ZStack(alignment: .bottom) {
                    WaveShape(offset: waveOffset + 0.3, amplitude: 6)
                        .fill(Color("MainBlue").opacity(0.4))
                        .frame(height: 210)
                    WaveShape(offset: waveOffset + 0.6, amplitude: 8)
                        .fill(Color("MainBlue").opacity(0.7))
                        .frame(height: 200)
                    WaveShape(offset: waveOffset, amplitude: 9)
                        .fill(Color("MainBlue"))
                        .frame(height: 180)
                }
                
                // Camera button content
                Button(action: {
                    showCamera = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                        Text("Catch & Score")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40) // Push up further
                    .padding(.top, 20)
                    .contentShape(Rectangle())
                }
            }
            .frame(height: 200) // Increased container height to move it up
        }
    }
    
    // MARK: - Header
    
    private func headerSection(party: Party) -> some View {
        VStack(spacing: 16) {
            // Top row: Leave button, Location, Avatar
            HStack {
                // Leave button
                Button(action: {
                    Task {
                        await viewModel.leaveParty()
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Leave")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color("MainBlue"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("MainBlue").opacity(0.1))
                    .cornerRadius(20)
                }
                
                // Location badge
                HStack(spacing: 4) {
                    Text("Santa Cruz")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
                
                // Otter avatar
                Circle()
                    .fill(Color("MainBlue").opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(Text("🦦").font(.system(size: 24)))
            }
            
            // Host name and location
            VStack(spacing: 4) {
                // Get host name - first player in party
                let hostName = party.players.first(where: { $0.id == party.hostId })?.name ?? "Someone"
                let locationName = party.locationName ?? "Tide Pool"
                
                Text("\(hostName)'s Party at:")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(locationName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Code and time remaining
            HStack(spacing: 16) {
                Text("#\(party.code)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("MainBlue"))
                
                // Time/XP display badge
                if party.status == .active {
                    statusBadge(party: party)
                } else if party.status == .waiting {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                        Text("Waiting")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("MainBlue"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("MainBlue").opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Start button for host in waiting state
            if party.status == .waiting && viewModel.isHost {
                Button(action: {
                    Task {
                        await viewModel.startParty()
                    }
                }) {
                    Text("Start Race")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("MainBlue"))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private func statusBadge(party: Party) -> some View {
        Group {
            switch party.gameMode {
            case .timeTrial:
                if let timeRemaining = party.timeRemainingFormatted {
                    Text("\(timeRemaining) left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("MainBlue"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("MainBlue").opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("Time Trial")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("MainBlue"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("MainBlue").opacity(0.1))
                        .cornerRadius(8)
                }
                
            case .scoreRace:
                Text("First to \(party.targetValue) XP")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("MainBlue"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("MainBlue").opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Player List
    
    private func playerListSection(party: Party) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Flag image above bars
                HStack {
                    Spacer()
                    Image("Flag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal)
                
                ForEach(party.sortedPlayers) { player in
                    let isCurrentUser = player.id == viewModel.currentUserId
                    PlayerProgressBar(
                        player: player,
                        progress: viewModel.playerProgress(userId: player.id),
                        isCurrentUser: isCurrentUser
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.top, 16)
        }
    }
    

    
    // MARK: - XP Gain Notification
    
    private var xpGainNotification: some View {
        VStack {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("+\(viewModel.lastXPGain) XP")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color("MainBlue"))
                    .shadow(radius: 8)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 100)
    }
}

#Preview {
    // Mock party data for preview
    let mockParty = Party(
        code: "5423",
        hostId: "user1",
        locationName: "Davenport Landing",
        gameMode: .timeTrial,
        targetValue: 600,
        players: [
            PartyPlayer(id: "user1", name: "Anthony", avatar: 3, xp: 450, catches: ["crab": 3]),
            PartyPlayer(id: "user2", name: "You", avatar: 1, xp: 420, catches: ["starfish": 2])
        ]
    )
    
    NavigationView {
        PartyRaceView()
            .onAppear {
                PartyViewModel.shared.currentParty = mockParty
            }
    }
}
