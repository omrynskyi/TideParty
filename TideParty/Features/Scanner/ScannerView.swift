//
//  ScannerView.swift
//  TideParty
//
//  Camera scanner view with classification label and wave UI
//

import SwiftUI
import Combine
import UIKit
import AVFoundation

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showResult = false
    @State private var resultOffset: CGFloat = UIScreen.main.bounds.height
    @State private var capturedLabel: String = ""
    @State private var catchCount: Int = 1
    @State private var xpGained: Int = 0
    
    var body: some View {
        ZStack {
            // Camera Preview (full screen - always visible as background)
            CameraPreview(session: viewModel.captureSession)
                .ignoresSafeArea()
            
            // Scanner UI (label + back button) - hidden when showing result
            if !showResult {
                // Classification Label (top)
                VStack(spacing: 0) {
                    HStack {
                        // Back button
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Classification label
                        Text(viewModel.classificationLabel)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .animation(.easeInOut(duration: 0.2), value: viewModel.classificationLabel)
                        
                        Spacer()
                        
                        // Spacer for symmetry
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(nil, value: UUID())
                
                // Capture Button + Wave (bottom)
                VStack(spacing: 0) {
                    Button(action: {
                        captureAndTransition()
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.canCapture ? .white : .gray.opacity(0.5))
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                .frame(width: 82, height: 82)
                        }
                    }
                    .disabled(!viewModel.canCapture)
                    .padding(.bottom, 20)
                    
                    // Wave at bottom
                    ScannerWaveView()
                        .frame(height: 90)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .animation(nil, value: viewModel.classificationLabel)
                .animation(nil, value: UUID())
            }
            
            // Discovery Result (slides up as overlay)
            if showResult, let image = viewModel.capturedImage {
                DiscoveryResultView(
                    image: image,
                    capturedLabel: capturedLabel,
                    catchCount: catchCount,
                    xpGained: xpGained,
                    isInParty: PartyViewModel.shared.isInParty,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            resultOffset = UIScreen.main.bounds.height
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showResult = false
                            viewModel.capturedImage = nil
                        }
                    }
                )
                .offset(y: resultOffset)
                .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            // Only stop session if navigating away from scanner
            if !showResult {
                viewModel.stopSession()
            }
        }
        .statusBarHidden(true)
    }
    
    private func captureAndTransition() {
        guard viewModel.canCapture else { return }
        
        // Capture label at this moment (before it might change)
        capturedLabel = viewModel.classificationLabel
        
        // Capture current frame
        viewModel.captureCurrentFrame()
        
        // Track creature capture and get count
        Task {
            // If in an active party, use party catch count
            if PartyViewModel.shared.isInParty {
                // Calculate XP before the catch (100 for first, 20 for repeat)
                let currentCatches = PartyViewModel.shared.currentParty?.players
                    .first(where: { $0.id == PartyViewModel.shared.currentUserId })?
                    .catches[capturedLabel] ?? 0
                let xp = currentCatches == 0 ? 100 : 20
                
                await PartyViewModel.shared.recordCatch(creatureId: capturedLabel)
                
                // Update UI with XP and party count
                await MainActor.run {
                    xpGained = xp
                    catchCount = currentCatches + 1
                }
            } else {
                // Normal mode - use profile count
                let count = try? await UserStatsService.shared.captureCreature(name: capturedLabel)
                await MainActor.run {
                    catchCount = count ?? 1
                    xpGained = 0
                }
            }
        }
        
        // Show result and animate slide up
        showResult = true
        resultOffset = UIScreen.main.bounds.height
        
        withAnimation(.easeOut(duration: 0.5)) {
            resultOffset = 0
        }
    }
}

#Preview {
    ScannerView()
}
