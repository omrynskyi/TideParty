//
//  DiscoveryResultView.swift
//  TideParty
//
//  Result page shown after capturing a sea creature - slides up as overlay
//

import SwiftUI
import Combine

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
    let initialXpGained: Int // XP gained from this catch (party mode)
    var isInParty: Bool = false // Whether user is in a party
    var onDismiss: () -> Void = {}
    
    @State private var xpGained: Int = 0 // Mutable for quiz bonus
    @State private var waveOffset: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0 // Track scroll position
    @State private var initialDragPivot: CGFloat? = nil // Tracks drag start point for smart dismissal
    @State private var showLearnMode = false // Toggle for Learn feature
    
    @StateObject private var viewModel = DiscoveryViewModel()
    
    init(image: UIImage, capturedLabel: String, catchCount: Int, xpGained: Int = 0, isInParty: Bool = false, onDismiss: @escaping () -> Void = {}) {
        self.image = image
        self.capturedLabel = capturedLabel
        self.catchCount = catchCount
        self.initialXpGained = xpGained
        self.isInParty = isInParty
        self.onDismiss = onDismiss
        self._xpGained = State(initialValue: xpGained)
    }
    
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
                            
                            // Title with XP badge when in party
                            VStack(spacing: 8) {
                                Text(catchCount == 1 ? "You Found a \(capturedLabel)!" : "Cool Catch! This is your \(ordinal(catchCount)) \(capturedLabel).")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                // XP Badge for party mode
                                if isInParty && xpGained > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("+\(xpGained) XP")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.8))
                                    )
                                }
                            }
                            .padding(.top, 20)
                            
                            // Progress Card
                            ProgressStreakCard()
                                .padding(.horizontal, 24)
                            
                            // Learn Button (Toggles Card)
                            Button(action: {
                                withAnimation {
                                    showLearnMode.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: showLearnMode ? "chevron.up" : "book.fill")
                                    Text(showLearnMode ? "Close Fact Sheet" : "Let's Learn!")
                                }
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.cardPurple)
                                .cornerRadius(28)
                            }
                            .padding(.horizontal, 24)
                            
                            // Learn Card (Collapsible)
                            if showLearnMode {
                                LearnCard(creatureName: capturedLabel, viewModel: viewModel)
                                    .padding(.horizontal, 24)
                                    .transition(.scale.combined(with: .opacity).animation(.spring()))
                            }
                            
                            // Quiz Card
                            QuizCard(creatureName: capturedLabel, viewModel: viewModel, xpGained: $xpGained, isInParty: isInParty)
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
// MARK: - Discovery ViewModel
@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var quizQuestion: QuizQuestion?
    @Published var factSheet: CreatureFactSheet?
    
    @Published var isQuizLoading = false
    @Published var isLearnLoading = false
    
    @Published var quizError: String?
    @Published var learnError: String?
    
    // Default to Cerebras for reliability
    private let aiService: AIServiceProtocol = CerebrasService()
    
    func loadQuiz(for creature: String) async {
        isQuizLoading = true
        quizError = nil
        do {
            let fetchedQuestion = try await aiService.generateQuizQuestion(creature: creature)
            self.quizQuestion = fetchedQuestion
            isQuizLoading = false
        } catch {
            print("Failed to fetch quiz: \(error)")
            // Fallback: Try to load a random question from local JSON
            if let url = Bundle.main.url(forResource: "question_ex", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let allQuestions = try? JSONDecoder().decode([QuizQuestion].self, from: data),
               let randomQuestion = allQuestions.randomElement() {
                self.quizQuestion = randomQuestion
            } else {
                // Ultimate fallback
                self.quizQuestion = QuizQuestion(
                    question: "What is the number one cause of habitat loss for \(creature.lowercased())?",
                    answer1: "Pollution",
                    answer2: "Global Warming",
                    answer3: "Overfishing",
                    answer4: "Tourism",
                    correctAnswer: 2,
                    reason: "Climate change and habitat destruction are major threats to marine life."
                )
            }
            isQuizLoading = false
        }
    }
    
    func loadFactSheet(for creature: String) async {
        isLearnLoading = true
        learnError = nil
        do {
            let sheet = try await aiService.generateFactSheet(creature: creature)
            self.factSheet = sheet
            isLearnLoading = false
        } catch {
            print("Failed to fetch fact sheet: \(error)")
            self.learnError = "Could not load educational content. Please try again later."
            isLearnLoading = false
        }
    }
}

// MARK: - Quiz Card
struct QuizCard: View {
    let creatureName: String
    @ObservedObject var viewModel: DiscoveryViewModel
    @Binding var xpGained: Int
    var isInParty: Bool = false
    
    @State private var selectedAnswer: Int? // 1-based index
    @State private var isSubmitted = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isQuizLoading {
                ProgressView("Asking the Marine Biologist...")
                    .tint(.white)
                    .foregroundColor(.white)
                    .padding()
            } else if let question = viewModel.quizQuestion {
                Text(question.question)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Answer grid
                VStack(spacing: 12) {
                    answerButton(text: question.answer1, index: 1)
                    answerButton(text: question.answer2, index: 2)
                    answerButton(text: question.answer3, index: 3)
                    answerButton(text: question.answer4, index: 4)
                }
                .disabled(isSubmitted)
                
                // Submit / Result
                if isSubmitted {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(isCorrect ? "Correct! +20 XP" : "Incorrect.")
                        }
                        .font(.headline)
                        .foregroundColor(isCorrect ? .green : .red)
                        
                        if !isCorrect {
                            Text("The Check: Answer \(ordinal(question.correctAnswer))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text(question.reason)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if selectedAnswer != nil {
                    Button(action: { submitQuiz(correctIndex: question.correctAnswer) }) {
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
            } else {
                Text("Could not load quiz.")
                    .foregroundColor(.red)
            }
        }
        .padding(24)
        .background(Color.cardPurple)
        .cornerRadius(20)
        .animation(.spring(), value: isSubmitted)
        .animation(.spring(), value: selectedAnswer)
        .onAppear {
            if viewModel.quizQuestion == nil {
                Task {
                    await viewModel.loadQuiz(for: creatureName)
                }
            }
        }
    }
    
    private func submitQuiz(correctIndex: Int) {
        guard let selected = selectedAnswer else { return }
        
        isSubmitted = true
        if selected == correctIndex {
            isCorrect = true
            UserStatsService.shared.incrementQuizCorrect()
            
            // Add +20 XP for correct answer in party mode
            if isInParty {
                xpGained += 20
                // Update score in Firestore
                Task {
                    try? await PartyService.shared.addQuizBonus(xp: 20)
                }
            }
        } else {
            isCorrect = false
        }
    }
    
    private func answerButton(text: String, index: Int) -> some View {
        let isSelected = selectedAnswer == index
        let isThisCorrect = viewModel.quizQuestion?.correctAnswer == index
        
        var bgColor: Color {
            if isSubmitted {
                if isThisCorrect { return .green.opacity(0.8) }
                if isSelected && !isCorrect { return .red.opacity(0.8) }
                return .gray.opacity(0.3)
            } else {
                return isSelected ? Color.blue : Color.buttonPurple
            }
        }
        
        return Button(action: { selectedAnswer = index }) {
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(bgColor)
                .cornerRadius(24)
                .scaleEffect(isSelected ? 1.02 : 1.0)
                .animation(.spring(), value: isSelected)
        }
    }
    
    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Learn Fact Sheet Card
struct LearnCard: View {
    let creatureName: String
    @ObservedObject var viewModel: DiscoveryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("About \(creatureName)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "book.fill")
                    .foregroundColor(.cyan)
                    .font(.title2)
            }
            
            if viewModel.isLearnLoading {
                HStack {
                    Spacer()
                    ProgressView("Consulting the library...")
                        .tint(.white)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
            } else if let factSheet = viewModel.factSheet {
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Scientific Name
                    Text(factSheet.scientificName)
                        .font(.headline.italic())
                        .foregroundColor(.white.opacity(0.7))
                    
                    Divider().overlay(Color.white.opacity(0.2))
                    
                    // About
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Description", systemImage: "eye.fill")
                            .font(.caption.bold())
                            .foregroundColor(.cyan)
                        Text(factSheet.about)
                            .font(.body)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Ecosystem Role
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Ecosystem Role", systemImage: "leaf.fill")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Text(factSheet.ecosystemRole)
                            .font(.body)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Fun Fact
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Fun Fact", systemImage: "sparkles")
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                        Text(factSheet.funFact)
                            .font(.body)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .transition(.opacity)
            } else if let error = viewModel.learnError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                // Initial state before load (shouldn't really happen if triggered on appear)
                Color.clear.frame(height: 1)
            }
        }
        .padding(24)
        .background(Color.cardPurple)
        .cornerRadius(20)
        .onAppear {
            if viewModel.factSheet == nil {
                Task {
                    await viewModel.loadFactSheet(for: creatureName)
                }
            }
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
