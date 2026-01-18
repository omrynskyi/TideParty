//
//  PartyJoinView.swift
//  TideParty
//
//  View for creating or joining a Tide Party
//

import SwiftUI

struct PartyJoinView: View {
    @StateObject private var viewModel = PartyViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCreateOptions = false
    
    var body: some View {
        ZStack {
            // Background
            Color("MainBlue")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Spacer()
                
                // Main content
                contentSection
                
                Spacer()
                
                // Footer with waves
                footerSection
            }
        }
        .sheet(isPresented: $showCreateOptions) {
            CreatePartySheet()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onChange(of: viewModel.isInParty) { oldValue, newValue in
            if newValue {
                // Navigate to race view instead of dismissing
            }
        }
        .background(
            NavigationLink(
                destination: PartyRaceView(),
                isActive: .constant(viewModel.isInParty),
                label: { EmptyView() }
            )
            .hidden()
        )
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Tide Party")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Race to catch the most creatures!")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.top, 60)
    }
    
    // MARK: - Content
    
    private var contentSection: some View {
        VStack(spacing: 24) {
            // Start Party Button
            Button(action: {
                showCreateOptions = true
            }) {
                Text("Start Party")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("MainBlue"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            
            // Enter Code Section
            VStack(spacing: 16) {
                Text("Enter Code")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                // Code input boxes
                CodeInputView(code: $viewModel.partyCode)
                
                // Join button
                Button(action: {
                    Task {
                        await viewModel.joinExistingParty()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Join Party")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("MainBlue"))
                    }
                }
                .frame(width: 200, height: 48)
                .background(Color.white.opacity(viewModel.isValidCode ? 1.0 : 0.5))
                .cornerRadius(12)
                .disabled(!viewModel.isValidCode || viewModel.isLoading)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("MainBlue").opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Ocean waves (reuse from existing design)
            WaveShape(offset: 0)
                .fill(Color("MainBlue").opacity(0.3))
                .frame(height: 30)
            WaveShape(offset: 20)
                .fill(Color("MainBlue").opacity(0.5))
                .frame(height: 30)
            WaveShape(offset: 40)
                .fill(Color("MainBlue"))
                .frame(height: 40)
            
            // Bottom section
            Color("MainBlue")
                .frame(height: 80)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("See anything cool?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                )
        }
    }
}

// MARK: - Create Party Sheet

struct CreatePartySheet: View {
    @StateObject private var viewModel = PartyViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMode: GameMode = .timeTrial
    @State private var targetValue: Int = 600 // Default: 10 minutes
    
    var body: some View {
        NavigationView {
            Form {
                Section("Game Mode") {
                    Picker("Mode", selection: $selectedMode) {
                        Text("Time Trial").tag(GameMode.timeTrial)
                        Text("Score Race").tag(GameMode.scoreRace)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(selectedMode == .timeTrial ? "Duration (seconds)" : "Target XP") {
                    if selectedMode == .timeTrial {
                        Picker("Time", selection: $targetValue) {
                            Text("5 min").tag(300)
                            Text("10 min").tag(600)
                            Text("15 min").tag(900)
                            Text("20 min").tag(1200)
                        }
                        .pickerStyle(.wheel)
                    } else {
                        Picker("XP", selection: $targetValue) {
                            Text("300 XP").tag(300)
                            Text("500 XP").tag(500)
                            Text("750 XP").tag(750)
                            Text("1000 XP").tag(1000)
                        }
                        .pickerStyle(.wheel)
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.createNewParty(mode: selectedMode, target: targetValue)
                            dismiss()
                        }
                    }) {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Create Party")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Create Party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#Preview {
    PartyJoinView()
}
