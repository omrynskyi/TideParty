//
//  TidePartySection.swift
//  TideParty
//
//  Inline party section for LandingView with expandable options
//

import SwiftUI

struct TidePartySection: View {
    @StateObject private var partyVM = PartyViewModel.shared
    @State private var isExpanded = false
    @State private var showJoinInput = false
    @State private var selectedMode: GameMode = .timeTrial
    @State private var selectedTime: Int = 600 // 10 min
    @State private var selectedXP: Int = 500
    @State private var joinCode: String = ""
    @State private var navigateToParty = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Unified Persistent Header (Otto + Text + Close Button)
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Image("OttoCheckeredFlag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Dynamic Title
                        Group {
                            if !isExpanded && !showJoinInput {
                                Text("Ready, Set, Tide!")
                            } else if showJoinInput {
                                Text("Join a Party")
                            } else {
                                Text(selectedMode == .timeTrial ? "Tide Trails" : "XP Race")
                            }
                        }
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(Color("MainBlue"))
                        .transition(.opacity) // Smooth text fade
                        
                        // Dynamic Subtitle
                        Group {
                            if !isExpanded && !showJoinInput {
                                Text("Race your friends! Create a party to tally scores & catches.")
                            } else if showJoinInput {
                                Text("Enter the 4-digit code to join your friends.")
                            } else {
                                Text(selectedMode == .timeTrial 
                                     ? "Race against the clock! Catch as many as you can." 
                                     : "First to reach the XP target wins!")
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Close Button (Only visible when expanded or joining)
                    if isExpanded || showJoinInput {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isExpanded = false
                                showJoinInput = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(width: 28, height: 28)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.top, 4)
                
                // Content Body (Buttons or Forms)
                if !isExpanded && !showJoinInput {
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Start Party Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isExpanded = true
                                showJoinInput = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 16))
                                Text("Start Party")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("MainBlue"))
                            .cornerRadius(16)
                        }
                        
                        // Join Party Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                showJoinInput = true
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16))
                                Text("Join")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color("MainBlue"))
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(Color("MainBlue").opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                } else if isExpanded {
                    createPartyOptions
                } else if showJoinInput {
                    joinPartyInput
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
        .background(
            NavigationLink(
                destination: PartyRaceView(),
                isActive: $navigateToParty,
                label: { EmptyView() }
            )
            .hidden()
        )
        .onChange(of: partyVM.isInParty) { _, newValue in
            if newValue {
                navigateToParty = true
            }
        }
    }
    
    // MARK: - Create Party Options
    
    private var createPartyOptions: some View {
        VStack(spacing: 16) {
            // Mode Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Game Mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    modeButton(mode: .timeTrial, icon: "timer", label: "Tide Trails")
                    modeButton(mode: .scoreRace, icon: "star.fill", label: "XP Race")
                }
            }
            
            // Value Selector
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedMode == .timeTrial ? "Duration" : "Target XP")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                if selectedMode == .timeTrial {
                    HStack(spacing: 8) {
                        timeButton(seconds: 300, label: "5 min")
                        timeButton(seconds: 600, label: "10 min")
                        timeButton(seconds: 900, label: "15 min")
                    }
                } else {
                    HStack(spacing: 8) {
                        xpButton(xp: 300, label: "300")
                        xpButton(xp: 500, label: "500")
                        xpButton(xp: 1000, label: "1K")
                    }
                }
            }
            
            // Start Button
            Button(action: {
                Task {
                    let target = selectedMode == .timeTrial ? selectedTime : selectedXP
                    await partyVM.createNewParty(mode: selectedMode, target: target)
                }
            }) {
                HStack {
                    if partyVM.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                        Text("Start Race")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("MainBlue"))
                .cornerRadius(16)
            }
            .disabled(partyVM.isLoading)
        }
    }

    // MARK: - Join Party Input
    
    private var joinPartyInput: some View {
        VStack(spacing: 16) {
            
            // Code Input
            ZStack {
                // Visual Digits (Background)
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        let digit = digitAt(index: index)
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("MainBlue").opacity(0.1))
                                .frame(width: 56, height: 64)
                            
                            Text(digit)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color("MainBlue"))
                        }
                    }
                }
                
                // Actual Input Field (Foreground)
                TextField("", text: Binding(
                    get: { joinCode },
                    set: { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered.count <= 4 {
                            joinCode = filtered
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .foregroundColor(.clear) // Hide text
                .accentColor(.clear) // Hide cursor
                .frame(maxWidth: .infinity, maxHeight: 64)
                .background(Color.white.opacity(0.01)) // Ensure hit testing works
            }
            
            // Join Button
            Button(action: {
                partyVM.partyCode = joinCode
                Task {
                    await partyVM.joinExistingParty()
                }
            }) {
                HStack {
                    if partyVM.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                        Text("Join")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(joinCode.count == 4 ? Color("MainBlue") : Color.gray.opacity(0.3))
                .cornerRadius(16)
            }
            .disabled(joinCode.count != 4 || partyVM.isLoading)
            
            // Error message
            if let error = partyVM.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func modeButton(mode: GameMode, icon: String, label: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                selectedMode = mode
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(selectedMode == mode ? .white : Color("MainBlue"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedMode == mode ? Color("MainBlue") : Color("MainBlue").opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func timeButton(seconds: Int, label: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                selectedTime = seconds
            }
        }) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selectedTime == seconds ? .white : Color("MainBlue"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedTime == seconds ? Color("MainBlue") : Color("MainBlue").opacity(0.1))
                .cornerRadius(10)
        }
    }
    
    private func xpButton(xp: Int, label: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                selectedXP = xp
            }
        }) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selectedXP == xp ? .white : Color("MainBlue"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedXP == xp ? Color("MainBlue") : Color("MainBlue").opacity(0.1))
                .cornerRadius(10)
        }
    }
    
    private func digitAt(index: Int) -> String {
        guard joinCode.count > index else { return "" }
        let digitIndex = joinCode.index(joinCode.startIndex, offsetBy: index)
        return String(joinCode[digitIndex])
    }
}

#Preview {
    TidePartySection()
        .padding()
}
