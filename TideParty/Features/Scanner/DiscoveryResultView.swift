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

// MARK: - Helper to convert number to ordinal string
private func ordinal(_ n: Int) -> String {
    let suffix: String
    let ones = n % 10
    let tens = (n / 10) % 10
    
    if tens == 1 {
        suffix = "th"
    } else {
        switch ones {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
    }
    return "\(n)\(suffix)"
}

// MARK: - Crackling Fire Animation
// MARK: - Crackling Fire Animation
struct CracklingFire: View {
    var intensity: CGFloat = 1.0 // 0.0 to 1.0 multiplier
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var offsetX: CGFloat = 0
    
    var body: some View {
        Text("🔥")
            .font(.system(size: 32))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation * intensity)) // Scale rotation by intensity
            .offset(x: offsetX * intensity) // Scale shake by intensity
            .onAppear {
                // Base pulsing - always happens a bit
                withAnimation(.easeInOut(duration: 0.08).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
                // Wobble
                withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                    rotation = 5
                }
                // Shake
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
    
    // Intensity ramps up from 0.75 to 1.0
    private var isHot: Bool { progress >= 0.75 }
    private var trembleIntensity: CGFloat {
        guard progress >= 0.75 else { return 0 }
        // Map 0.75...1.0 to 0.0...1.0
        return (progress - 0.75) / 0.25
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Gray background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 16)
                
                // Fill bar
                ZStack(alignment: .top) {
                    // Base color logic: Yellow if cold, Red if hot
                    RoundedRectangle(cornerRadius: 13)
                        .fill(isHot ? Color.red : Color.yellow)
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
                // Only tremble if hot
                .offset(x: isHot ? offsetX : 0, y: isHot ? offsetY : 0)
                
                // Fire only appears if hot
                if isHot {
                    CracklingFire(intensity: trembleIntensity)
                        .offset(x: (geo.size.width * progress - 16) + offsetX, y: offsetY)
                }
            }
        }
        .frame(height: 34)
        .onAppear {
            // Horizontal tremble
            withAnimation(.easeInOut(duration: 0.05).repeatForever(autoreverses: true)) {
                offsetX = 1
            }
            // Vertical tremble
            withAnimation(.easeInOut(duration: 0.07).repeatForever(autoreverses: true)) {
                offsetY = 1
            }
        }
    }
}
struct DiscoveryResultView: View {
    let image: UIImage
    let capturedLabel: String // Label captured at button press time
    let catchCount: Int // How many times this creature has been caught
    var onDismiss: () -> Void = {}
    
    @State private var waveOffset: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0 // Track scroll position
    @State private var initialDragPivot: CGFloat? = nil // Tracks drag start point for smart dismissal
    
    var body: some View {
        GeometryReader { geometry in
            let imageSize: CGFloat = 200
            let imageTop: CGFloat = 100
            let waveTop: CGFloat = imageTop + (imageSize * 0.25)
            
            VStack(spacing: 0) {
                // Drag indicator (fixed at top of sheet)
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 60, height: 6)
                        .padding(.top, 16)
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle()) // Make entire header draggable
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            handleDragEnd(translation: value.translation.height, predicted: value.predictedEndTranslation.height)
                        }
                )
                .zIndex(10) // Always on top
                
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .top) {
                        // Background Layer (Moves with scroll)
                        VStack(spacing: 0) {
                            Color.clear.frame(height: waveTop) // Transparent top
                            
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
                            
                            // Solid blue fill - extends down
                            Color.discoveryBlue
                                .frame(height: 1000) // Arbitrary large height to cover scroll
                        }
                        
                        // Content Layer
                        VStack(spacing: 24) {
                            // Captured Image
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: imageSize, height: imageSize)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                                .padding(.top, imageTop - 30) // Offset relative to waveTop
                            
                            // Title
                            Text(catchCount == 1 ? "You Found a \(capturedLabel)!" : "Cool Catch! This is your \(ordinal(catchCount)) \(capturedLabel).")
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
                            
                            Spacer(minLength: 120)
                        }
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldValue, newValue in
                    scrollOffset = newValue
                    print("🔍 scrollOffset updated: \(newValue)")
                }
                // Smart Gesture for Content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 40)
                        .onChanged { value in
                            // Debug: Print scroll offset to understand the values
                            print("🔍 scrollOffset: \(scrollOffset), translation: \(value.translation.height)")
                            
                            // contentOffset.y is 0 at top, positive when scrolled down
                            let isAtTop = scrollOffset <= 30
                            
                            // If we are getting dragged down...
                            if value.translation.height > 0 {
                                if !isAtTop {
                                    // Not at top yet: Clear pivot
                                    print("❌ Not at top - blocking dismiss")
                                    initialDragPivot = nil
                                    dragOffset = 0
                                } else {
                                    // At top: Capture pivot if needed
                                    if initialDragPivot == nil {
                                        initialDragPivot = value.translation.height
                                        print("📍 At top - setting pivot: \(initialDragPivot!)")
                                    }
                                    
                                    // Calculate effective drag (delta from when we hit top)
                                    let pivot = initialDragPivot ?? 0
                                    let effectiveDrag = value.translation.height - pivot
                                    
                                    if effectiveDrag > 0 {
                                        dragOffset = effectiveDrag
                                        print("✅ Allowing dismiss - dragOffset: \(dragOffset)")
                                    } else {
                                        dragOffset = 0
                                    }
                                }
                            } else {
                                // Dragging up: Reset
                                dragOffset = 0
                                initialDragPivot = nil
                            }
                        }
                        .onEnded { value in
                            print("🏁 Gesture ended - translation: \(value.translation.height), pivot: \(initialDragPivot ?? 0)")
                            
                            // Calculate effective endpoint based on pivot
                            let pivot = initialDragPivot ?? 0
                            let effectiveTranslation = value.translation.height - pivot
                            let effectivePredicted = value.predictedEndTranslation.height - pivot
                            
                            handleDragEnd(translation: effectiveTranslation, predicted: effectivePredicted)
                            
                            // Reset state
                            initialDragPivot = nil
                        }
                )
            }
            .offset(y: dragOffset)
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    waveOffset = 1.0
                }
            }
        }
    }
    
    private func handleDragEnd(translation: CGFloat, predicted: CGFloat) {
        // If we haven't engaged the drag (dragOffset == 0), don't dismiss
        guard dragOffset > 0 else {
             withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                dragOffset = 0
            }
            return
        }
        
        let shouldDismiss = translation > 60 || predicted > 120
        
        if shouldDismiss {
            withAnimation(.easeOut(duration: 0.25)) {
                dragOffset = UIScreen.main.bounds.height
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
}

// MARK: - Progress Streak Card
// MARK: - Progress Streak Card
struct ProgressStreakCard: View {
    @ObservedObject var userStats = UserStatsService.shared
    
    var body: some View {
        let badge = userStats.nextBadge
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(badge.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                // Icon placeholder
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: badge.icon)
                            .font(.system(size: 30))
                            .foregroundColor(.pink)
                    )
            }
            
            Text(badge.subtitle)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
            
            // Progress bar
            TremblingProgressBar(progress: badge.progress)
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
    @State private var isSubmitted = false
    @State private var isCorrect = false
    
    // Simple correct answer mapping (Demo logic)
    // In real app, this would come from a data model or CMS
    private var correctAnswer: String {
        switch creatureName.lowercased() {
        case "starfish", "sea star": return "Global Warming"
        case "crab": return "Loss of Shells"
        default: return "Global Warming" // Default answer for now
        }
    }
    
    let answers = ["Pollution", "Global Warming", "Overfishing", "Tourism"]
    
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
            .disabled(isSubmitted) // Disable interaction after submit
            
            // Submit Button or Result Message
            if isSubmitted {
                HStack {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(isCorrect ? "Correct! +1 Quiz Score" : "Incorrect. Try again next time!")
                }
                .font(.headline)
                .foregroundColor(isCorrect ? .green : .red)
                .padding(.top, 8)
                .transition(.scale.combined(with: .opacity))
            } else if selectedAnswer != nil {
                Button(action: submitQuiz) {
                    Text("Submit Answer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(24)
        .background(Color.cardPurple)
        .cornerRadius(20)
        .animation(.spring(), value: isSubmitted)
        .animation(.spring(), value: selectedAnswer)
    }
    
    private func submitQuiz() {
        guard let selected = selectedAnswer else { return }
        
        isSubmitted = true
        if selected == correctAnswer {
            isCorrect = true
            // Increment stats
            UserStatsService.shared.incrementQuizCorrect()
        } else {
            isCorrect = false
        }
    }
    
    private func answerButton(_ answer: String) -> some View {
        let isSelected = selectedAnswer == answer
        
        // Color logic:
        // If submitted: Green if correct answer, Red if selected & wrong, gray otherwise
        // If not submitted: Blue if selected, Purple default
        var bgColor: Color {
            if isSubmitted {
                if answer == correctAnswer { return .green.opacity(0.8) }
                if isSelected && !isCorrect { return .red.opacity(0.8) }
                return .gray.opacity(0.3)
            } else {
                return isSelected ? Color.blue : Color.buttonPurple
            }
        }
        
        return Button(action: { selectedAnswer = answer }) {
            Text(answer)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(bgColor)
                .cornerRadius(24)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(), value: isSelected)
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    DiscoveryResultView(
        image: UIImage(systemName: "star.fill")!,
        capturedLabel: "Starfish",
        catchCount: 1
    )
}
