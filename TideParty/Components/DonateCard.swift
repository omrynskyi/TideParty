//
//  DonateCard.swift
//  TideParty
//
//  Card encouraging donations to ocean conservation charities
//

import SwiftUI

struct DonateCard: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header with wave-like gradient
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [Color("MainBlue"), Color("MainBlue").opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protect Our Oceans")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Support Marine Conservation")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "water.waves")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(16)
            }
            .frame(height: 76)
            
            // Charity buttons section
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    CharityButton(
                        name: "Ocean Conservancy",
                        url: "https://oceanconservancy.org/donate/"
                    )
                    
                    CharityButton(
                        name: "Surfrider",
                        url: "https://www.surfrider.org/donate"
                    )
                }
                
                HStack(spacing: 10) {
                    CharityButton(
                        name: "Marine Conservation",
                        url: "https://marine-conservation.org/donate/"
                    )
                    
                    CharityButton(
                        name: "Sea Shepherd",
                        url: "https://www.seashepherd.org/donate/"
                    )
                }
            }
            .padding(12)
            .background(Color("MainBlue").opacity(0.05))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("MainBlue").opacity(0.15), lineWidth: 1)
        )
    }
}

struct CharityButton: View {
    let name: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("MainBlue"))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color("MainBlue").opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    DonateCard()
        .padding()
}
