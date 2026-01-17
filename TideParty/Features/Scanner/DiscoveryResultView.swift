//
//  DiscoveryResultView.swift
//  TideParty
//
//  Result page shown after capturing a sea creature - slides up as overlay
//

import SwiftUI

// Color constants extracted from mockup
extension Color {
    static let discoveryBlue = Color(red: 0.0, green: 0.4, blue: 1.0) // #0066FF - bright blue background
    static let cardPurple = Color(red: 0.29, green: 0.33, blue: 0.88) // #4A54E1 - purple/indigo cards
    static let buttonPurple = Color(red: 0.35, green: 0.40, blue: 0.95) // #5966F2 - lighter purple buttons
}

// MARK: - Crackling Fire Animation
struct CracklingFire: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var offsetX: CGFloat = 0
    
    var body: some View {
        Text("🔥")
            .font(.system(size: 32))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: offsetX)
            .onAppear {
                // Fast crackling scale
                withAnimation(.easeInOut(duration: 0.08).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
                // More intense wobble
                withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                    rotation = 5
                }
                // Horizontal shake
                withAnimation(.easeInOut(duration: 0.06).repeatForever(autoreverses: true)) {
                    offsetX = 2
                }
            }
    }
}

// MARK: - Trembling Progress Bar
struct TremblingProgressBar: View {
    let progress: CGFloat
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Gray background (smaller than red bar)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 16)
                
                // Red fill with highlight + tremble
                ZStack(alignment: .top) {
                    // Base red
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color.red)
                        .frame(width: geo.size.width * progress, height: 26)
                    
                    // Top highlight
                    RoundedRectangle(cornerRadius: 13)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 26)
                }
                .offset(x: offsetX, y: offsetY)
                
                // Animated crackling fire
                CracklingFire()
                    .offset(x: geo.size.width * progress - 16, y: 0)
            }
        }
        .frame(height: 34)
        .onAppear {
            // Subtle horizontal tremble
            withAnimation(.easeInOut(duration: 0.05).repeatForever(autoreverses: true)) {
                offsetX = 1
            }
            // Subtle vertical tremble
            withAnimation(.easeInOut(duration: 0.07).repeatForever(autoreverses: true)) {
                offsetY = 0.5
            }
        }
    }
}
struct DiscoveryResultView: View {
    let image: UIImage
    let capturedLabel: String // Label captured at button press time
    var onDismiss: () -> Void = {}
    
    @State private var waveOffset: Double = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let imageSize: CGFloat = 200
            let imageTop: CGFloat = 100
            let waveTop: CGFloat = imageTop + (imageSize * 0.25)
            
            ZStack(alignment: .top) {
                // Blue background + Waves
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: waveTop)
                    
                    // Animated waves
                    ZStack(alignment: .bottom) {
                        WaveShape(offset: waveOffset + 0.3, amplitude: 12)
                            .fill(Color.discoveryBlue.opacity(0.4))
                            .frame(height: 120)
                        
                        WaveShape(offset: waveOffset + 0.6, amplitude: 10)
                            .fill(Color.discoveryBlue.opacity(0.7))
                            .frame(height: 90)
                        
                        WaveShape(offset: waveOffset, amplitude: 14)
                            .fill(Color.discoveryBlue)
                            .frame(height: 70)
                    }
                    .frame(height: 120)
                    
                    // Solid blue fill
                    Color.discoveryBlue
                }
                
                // Content layer
                VStack(spacing: 0) {
                    // Drag indicator
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 60, height: 6)
                        .padding(.top, 16)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Captured Image
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: imageSize, height: imageSize)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                                .padding(.top, imageTop - 30)
                            
                            // Title - uses captured label
                            Text("You Found a \(capturedLabel)!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.top, 20)
                            
                            // Progress Card
                            ProgressStreakCard()
                                .padding(.horizontal, 24)
                            
                            // Learn Button
                            Button(action: {}) {
                                Text("Lets learn!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .background(Color.cardPurple)
                                    .cornerRadius(28)
                            }
                            .padding(.horizontal, 24)
                            
                            // Quiz Card
                            QuizCard(creatureName: capturedLabel)
                                .padding(.horizontal, 24)
                            
                            Spacer(minLength: 60)
                        }
                    }
                }
            }
            .offset(y: dragOffset)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        let shouldDismiss = value.translation.height > 50 || 
                                           value.predictedEndTranslation.height > 100
                        
                        if shouldDismiss {
                            withAnimation(.easeOut(duration: 0.25)) {
                                dragOffset = geometry.size.height
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onDismiss()
                            }
                        } else {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    waveOffset = 1.0
                }
            }
        }
    }
}

// MARK: - Progress Streak Card
struct ProgressStreakCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("You're on a roll!!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                // Sea anemone image placeholder
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.pink)
                    )
            }
            
            Text("1 tide creature away from Sea Anemone")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
            
            // Progress bar matching mockup
            TremblingProgressBar(progress: 0.78)
        }
        .padding(20)
        .background(Color.cardPurple)
        .cornerRadius(20)
    }
}

// MARK: - Quiz Card
struct QuizCard: View {
    let creatureName: String
    @State private var selectedAnswer: String?
    let answers = ["Fire", "Global Warming", "Apex Predators", "Clownfish"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Question: What is the number one cause of habitat loss for \(creatureName.lowercased())?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Answer grid - 2x2
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(answers.prefix(2), id: \.self) { answer in
                        answerButton(answer)
                    }
                }
                HStack(spacing: 12) {
                    ForEach(answers.suffix(2), id: \.self) { answer in
                        answerButton(answer)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.cardPurple)
        .cornerRadius(20)
    }
    
    private func answerButton(_ answer: String) -> some View {
        Button(action: { selectedAnswer = answer }) {
            Text(answer)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    selectedAnswer == answer 
                        ? Color.blue 
                        : Color.buttonPurple
                )
                .cornerRadius(24)
        }
    }
}

#Preview {
    DiscoveryResultView(
        image: UIImage(systemName: "star.fill")!,
        capturedLabel: "Starfish"
    )
}
