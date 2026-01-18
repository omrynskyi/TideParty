//
//  RaceWinView.swift
//  TideParty
//
//  Win screen overlay showing 1st, 2nd, 3rd place results
//

import SwiftUI

struct RaceWinView: View {
    let results: [PartyPlayer] // Top 3 players sorted by XP
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("MainBlue").opacity(0.9), Color("MainBlue")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Trophy header
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Race Complete!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Podium section
                VStack(spacing: 20) {
                    // 1st Place (large, centered)
                    if let first = results.first {
                        PlaceCard(player: first, place: 1, size: .large)
                    }
                    
                    // 2nd and 3rd Place (side by side)
                    HStack(spacing: 16) {
                        if results.count > 1 {
                            PlaceCard(player: results[1], place: 2, size: .small)
                        }
                        if results.count > 2 {
                            PlaceCard(player: results[2], place: 3, size: .small)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Done button
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("MainBlue"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Place Card Component

struct PlaceCard: View {
    let player: PartyPlayer
    let place: Int
    let size: PlaceCardSize
    
    enum PlaceCardSize {
        case large, small
        
        var avatarSize: CGFloat {
            switch self {
            case .large: return 100
            case .small: return 70
            }
        }
        
        var nameFont: Font {
            switch self {
            case .large: return .system(size: 24, weight: .bold)
            case .small: return .system(size: 16, weight: .semibold)
            }
        }
        
        var xpFont: Font {
            switch self {
            case .large: return .system(size: 18, weight: .medium)
            case .small: return .system(size: 14, weight: .medium)
            }
        }
    }
    
    private var placeColor: Color {
        switch place {
        case 1: return .yellow
        case 2: return Color(white: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .gray
        }
    }
    
    private var placeEmoji: String {
        switch place {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Place indicator
            Text(placeEmoji)
                .font(.system(size: size == .large ? 40 : 28))
            
            // Avatar (badge image)
            if let badge = Badge.badge(for: player.avatar) {
                Image(badge.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.avatarSize, height: size.avatarSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(placeColor, lineWidth: size == .large ? 4 : 3)
                    )
            } else {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size.avatarSize, height: size.avatarSize)
                    .overlay(Text("🦦").font(.system(size: size == .large ? 50 : 35)))
            }
            
            // Player name
            Text(player.name)
                .font(size.nameFont)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // XP score
            Text("\(player.xp) XP")
                .font(size.xpFont)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(size == .large ? 24 : 16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(20)
    }
}

#Preview {
    RaceWinView(
        results: [
            PartyPlayer(id: "1", name: "Anthony", avatar: 3, xp: 520),
            PartyPlayer(id: "2", name: "Sarah", avatar: 1, xp: 380),
            PartyPlayer(id: "3", name: "Mike", avatar: 6, xp: 250)
        ],
        onDismiss: {}
    )
}
