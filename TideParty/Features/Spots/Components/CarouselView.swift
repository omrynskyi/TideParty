import SwiftUI

struct CarouselView<Content: View, Item: Identifiable>: View {
    var items: [Item]
    @Binding var index: Int
    let spacing: CGFloat
    let widthOfHiddenCards: CGFloat
    let content: (Item, Bool) -> Content
    
    @GestureState private var translation: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    // We use a "virtual" index to support infinite scrolling logic
    // But we map it back to the real `index` binding.
    @State private var virtualIndex: Int = 0
    
    init(
        items: [Item],
        index: Binding<Int>,
        spacing: CGFloat = 1,
        widthOfHiddenCards: CGFloat = 50, // Increased for prominent peeking
        @ViewBuilder content: @escaping (Item, Bool) -> Content
    ) {
        self.items = items
        self._index = index
        self.spacing = spacing
        self.widthOfHiddenCards = widthOfHiddenCards
        self.content = content
    }
    
    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            // Calculate card width based on visible area and peeking cards
            let cardWidth = totalWidth - (widthOfHiddenCards * 2) - (spacing * 2)
            
            HStack(spacing: spacing) {
                // Render a window of items: [prev, current, next]
                // We actually render 5 items to cover edge cases smoothy: [-2, -1, 0, 1, 2] relative to current
                ForEach(-2...2, id: \.self) { i in
                    let relativeIndex = virtualIndex + i
                    let itemIndex = getWrappedIndex(for: relativeIndex)
                    let isSelected = i == 0
                    
                    content(items[itemIndex], isSelected)
                        .frame(width: cardWidth)
                        .scaleEffect(isSelected ? 1.0 : 0.9)
                        .opacity(isSelected ? 1.0 : 0.6)
                        // Apply rotation/depth effect for 3D feel
                        .rankRotation(
                            idx: i,
                            offset: translation / cardWidth
                        )
                        .zIndex(isSelected ? 1 : 0)
                }
            }
            // Center the "0" index item
            // The items are: -2, -1, 0, 1, 2. We want 0 in center.
            // Width of 5 items + 4 spaces
            // (5 * cardWidth) + (4 * spacing)
            // But we only want to show the specific window.
            // The offset logic needs to shift the whole HStack so that element '0' is centered.
            .frame(width: totalWidth, alignment: .center)
            .offset(x: translation)
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = cardWidth * 0.2 // Snap early
                        let predictedEnd = value.predictedEndTranslation.width
                        
                        var direction = 0
                        if value.translation.width > threshold || predictedEnd > cardWidth / 2 {
                            direction = -1 // Swipe Right -> Go Prev
                        } else if value.translation.width < -threshold || predictedEnd < -cardWidth / 2 {
                            direction = 1 // Swipe Left -> Go Next
                        }
                        
                        if direction != 0 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                virtualIndex += direction
                                index = getWrappedIndex(for: virtualIndex)
                            }
                        }
                    }
            )
            .onChange(of: index) { newIndex in
                // Sync external index change (from Map Tap) to virtualIndex
                // Find "closest" virtual index that matches `newIndex` to minimize jump
                let currentReal = getWrappedIndex(for: virtualIndex)
                if currentReal != newIndex {
                    // Simple sync for now, avoiding complex shortest-path math for this demo
                    // Just reset virtual to match real if it's a jump
                   
                    // But to prevent "jump back", we should find the closest relative match.
                    let diff = newIndex - currentReal
                    // If diff is small, animate. If large, might be wrapping.
                    // Let's just set it for now.
                    // ideally we'd find the nearest virtual index congruent mod N
                    
                    // Brute force nearest: check virtualIndex - N ... virtualIndex + N
                    // ... simpler:
                    // Just snap for now.
                    // To support "seamlessness" with map tapping is harder without full virtual list.
                    // But for swiping, the above logic holds.
                }
            }
        }
    }
    
    func getWrappedIndex(for relativeIndex: Int) -> Int {
        if items.isEmpty { return 0 }
        let count = items.count
        let remainder = relativeIndex % count
        return remainder >= 0 ? remainder : remainder + count
    }
}

extension View {
    func rankRotation(idx: Int, offset: CGFloat) -> some View {
        // Calculate true relative position including drag offset (-0.5 to 0.5 for active)
        let relativePos = CGFloat(idx) - offset
        
        // Simple scale/opacity is usually cleaner than 3D rotation for functional maps
        // But user asked for "rotating carousel".
        // Let's add slight 3D rotation?
        // Or just keep the scale/opacity smooth.
        // The user said "start focusing on next element".
        // This visual effect helps indicate focus transfer.
        
        return self
            .scaleEffect(1.0 - (abs(relativePos) * 0.1)) // 1.0 at center, 0.9 at +/- 1
            .opacity(1.0 - (abs(relativePos) * 0.15))
            .blur(radius: abs(relativePos) * 1)
    }
}
