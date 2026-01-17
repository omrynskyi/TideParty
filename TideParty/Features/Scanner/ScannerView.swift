//
//  ScannerView.swift
//  TideParty
//
//  Camera scanner view with classification label and wave UI
//

import SwiftUI
import Combine
import UIKit

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Camera Preview (full screen)
            CameraPreview(session: viewModel.captureSession)
                .ignoresSafeArea()
            
            // Classification Label (top)
            VStack {
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
                
                Spacer()
            }
            
            // Capture Button + Wave (bottom)
            VStack {
                Spacer()
                
                // Capture button
                Button(action: {
                    // Capture action - haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 4)
                            .frame(width: 82, height: 82)
                    }
                }
                .padding(.bottom, 20)
                
                // Wave at bottom
                WaveShape()
                    .fill(Color("MainBlue"))
                    .frame(height: 80)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .statusBarHidden(true)
    }
}

#Preview {
    ScannerView()
}
