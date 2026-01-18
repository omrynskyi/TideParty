//
//  SafetyPledgeView.swift
//  TideParty
//
//  Safety pledge confirmation shown on every app launch
//

import SwiftUI

struct SafetyPledgeView: View {
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color("MainBlue")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("Before You Explore")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("The T.I.D.E. Code")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    TideRuleRow(emoji: "🤲", text: "Touch Gently")
                    TideRuleRow(emoji: "🏠", text: "In its Home")
                    TideRuleRow(emoji: "👣", text: "Don't Step")
                    TideRuleRow(emoji: "👀", text: "Eyes on Ocean")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    onConfirm()
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
}

#Preview {
    SafetyPledgeView(onConfirm: {})
}
