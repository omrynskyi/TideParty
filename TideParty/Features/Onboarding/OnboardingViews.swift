import SwiftUI

// MARK: - Step 1: Name
struct OnboardingNameView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(maxHeight: 40) // Smaller spacer to position content higher
            
            Text("Hey, my name is Otto.\nWhat's yours?")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Image("OttoWaving")
                .resizable()
                .scaledToFit()
                .frame(height: 180)
            
            TextField("Enter username", text: $viewModel.username)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
            
            Button(action: {
                withAnimation {
                    viewModel.currentStep += 1
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(Color("MainBlue"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 32)
            .disabled(viewModel.username.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(viewModel.username.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
            
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Step 2: Email
struct OnboardingEmailView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(maxHeight: 40)
            
            Image("OttoWaving") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(height: 180)
            
            Text("Before we go exploring...\nWhat's your email?")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            TextField("Enter email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
            
            Button(action: {
                withAnimation {
                    viewModel.currentStep += 1
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(Color("MainBlue"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 32)
            .disabled(viewModel.email.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(viewModel.email.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
            
            // Google Sign In
            Button(action: {
                Task {
                    do {
                        try await viewModel.signInWithGoogle()
                        // Auth successful - AuthManager will update state
                    } catch {
                        // Error shown via viewModel.errorMessage
                    }
                }
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Continue with Google")
                }
                .font(.headline)
                .foregroundColor(Color("MainBlue"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(30)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Step 3: Password
struct OnboardingPasswordView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(maxHeight: 40)
            
            Image("OttoWaving") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(height: 180)
            
            Text("Let's get you in.\nEnter your password.")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .multilineTextAlignment(.center)
                    .background(Color.red.opacity(0.8).cornerRadius(8))
            }
            
            Button(action: {
                isLoading = true
                Task {
                    do {
                        try await viewModel.authenticate()
                        isLoading = false
                        withAnimation {
                            viewModel.currentStep += 1
                        }
                    } catch {
                        isLoading = false
                    }
                }
            }) {
                if isLoading {
                    ProgressView()
                        .tint(Color("MainBlue"))
                } else {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(Color("MainBlue"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(30)
                }
            }
            .padding(.horizontal, 32)
            .disabled(viewModel.password.isEmpty)
            .opacity(viewModel.password.isEmpty ? 0.6 : 1.0)
            
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Step 4: Safety Lesson
struct OnboardingSafetyView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("One last thing!")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Text("The T.I.D.E. Code")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 20) {
                TideRuleRow(emoji: "🤲", text: "Touch Gently")
                TideRuleRow(emoji: "🏠", text: "In its Home, Don't Turn Rocks")
                TideRuleRow(emoji: "👣", text: "Step Lightly and Carefully")
                TideRuleRow(emoji: "👀", text: "Eyes on Ocean")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                viewModel.completeOnboarding()
            }) {
                Text("I Pledge to Protect the Ocean")
                    .font(.headline)
                    .foregroundColor(Color("MainBlue"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .padding()
    }
}

struct TideRuleRow: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 20) {
            Text(emoji)
                .font(.system(size: 32))
            Text(text)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
