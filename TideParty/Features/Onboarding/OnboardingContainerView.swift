import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            Color("MainBlue")
                .ignoresSafeArea()
                .onTapGesture {
                    // Tap background to dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            ScrollView {
                VStack {
                    // Custom TabView
                    TabView(selection: $viewModel.currentStep) {
                        OnboardingNameView(viewModel: viewModel)
                            .tag(0)
                        
                        OnboardingEmailView(viewModel: viewModel)
                            .tag(1)
                        
                        OnboardingPasswordView(viewModel: viewModel)
                            .tag(2)
                        
                        OnboardingSafetyView(viewModel: viewModel)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // Hide default dots
                    // Use highPriorityGesture to ensure we capture touches before the TabView
                    .highPriorityGesture(
                        DragGesture()
                            .onEnded { value in
                                // Detect Swipe Right (Back)
                                // Threshold of 50 points avoids accidental triggers
                                if value.translation.width > 50 {
                                    if viewModel.currentStep > 0 {
                                        withAnimation {
                                            viewModel.currentStep -= 1
                                        }
                                    }
                                }
                                // Swipe Left (Forward) is ignored / consumed by this gesture, 
                                // preventing the TabView from paging forward.
                            }
                    )
                    .frame(minHeight: UIScreen.main.bounds.height - 100)
                    
                    // Custom Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(Color.white.opacity(viewModel.currentStep == index ? 1.0 : 0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(viewModel.currentStep == index ? 1.2 : 1.0)
                                .animation(.spring(), value: viewModel.currentStep)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    OnboardingContainerView()
}
