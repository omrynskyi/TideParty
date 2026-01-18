import SwiftUI

/// AI Insights card with Otto mascot, collapsible, and inviting design
struct AIInsightView: View {
    let insightText: String
    let isLoading: Bool
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar (fully tappable to collapse)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Otto mascot
                    Image("OttoMonacle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.purple.opacity(0.2), radius: 6, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Otto's Insights")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Powered by AI ✨")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Collapse indicator
                    ZStack {
                        Circle()
                            .fill(Color("MainBlue").opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("MainBlue"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color("MainBlue").opacity(0.08),
                            Color.purple.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    // Glowing gradient divider
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.4), Color("MainBlue").opacity(0.5), Color.purple.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                            .blur(radius: 2)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.6), Color("MainBlue").opacity(0.7), Color.purple.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                    
                    if isLoading {
                        // Loading state
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("MainBlue")))
                            Text("Otto is thinking...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                    } else {
                        // Insight text - larger and more readable
                        Text(insightText.isEmpty ? "Tap to refresh for a new insight!" : insightText)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.primary.opacity(0.9))
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                    }
                }
                .background(
                    ZStack {
                        Color(.systemBackground)
                        
                        // Subtle inner glow at top
                        VStack {
                            LinearGradient(
                                colors: [Color.purple.opacity(0.05), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                            Spacer()
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                
                // Gradient border glow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.4),
                                Color("MainBlue").opacity(0.4),
                                Color.purple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.purple.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Font Extension for Fallback
extension Font {
    func fallbackFont(_ fallback: Font) -> Font {
        return self
    }
}

extension View {
    func fallbackFont(_ fallback: Font) -> some View {
        return self
    }
}

#Preview {
    VStack(spacing: 20) {
        AIInsightView(
            insightText: "Look for purple sea urchins in the exposed tide pools at 1.8ft. Hermit crabs are scurrying between rocks in the warm 68°F sun!",
            isLoading: false
        )
        .padding()
        
        AIInsightView(
            insightText: "",
            isLoading: true
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
