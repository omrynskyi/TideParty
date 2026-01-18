//
//  PlayerProgressBar.swift
//  TideParty
//
//  Animated progress bar for displaying player scores in party race
//

import SwiftUI

struct PlayerProgressBar: View {
    let player: PartyPlayer
    let progress: Double // 0.0 to 1.0
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name row
            HStack {
                Text(isCurrentUser ? "You" : player.name)
                    .font(.system(size: 16, weight: isCurrentUser ? .bold : .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Finish flag at end
                Text("🏁")
                    .font(.system(size: 14))
                
                Text("\(player.xp)xp")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Progress bar with otter
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 28)
                    
                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.3),
                                    Color(red: 1.0, green: 0.65, blue: 0.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geometry.size.width * progress, 40), height: 28)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                    
                    // Otter avatar on the progress bar
                    Text("🦦")
                        .font(.system(size: 20))
                        .offset(x: max(geometry.size.width * progress - 28, 8))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 28)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        PlayerProgressBar(
            player: PartyPlayer(id: "1", name: "You", avatar: "🦦", xp: 36, catches: [:]),
            progress: 0.45,
            isCurrentUser: true
        )
        
        PlayerProgressBar(
            player: PartyPlayer(id: "2", name: "Anthony", avatar: "🦦", xp: 43, catches: [:]),
            progress: 0.55,
            isCurrentUser: false
        )
    }
    .padding()
}
