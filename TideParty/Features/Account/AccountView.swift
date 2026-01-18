//
//  AccountView.swift
//  TideParty
//
//  Profile page showing user badges, profile selection, and account management
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountView: View {
    @ObservedObject var userStats = UserStatsService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Profile Badge Display
                    profileSection
                    
                    // Progress Card
                    progressCard
                    
                    // Badge Grid
                    badgeGrid
                    
                    // Account Actions
                    accountActions
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
            }
            
            // Bottom Wave
            animatedWaveFooter
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            // Centered location pill
            HStack {
                Text("Santa Cruz")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
            
            // Left: Back button, Right: Profile badge
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Home")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Color("MainBlue"))
                }
                
                Spacer()
                
                // Current Profile Badge (small)
                if let badge = Badge.badge(for: userStats.selectedBadgeId) {
                    Image(badge.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color("MainBlue").opacity(0.3), lineWidth: 2))
                }
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Large Profile Badge
            if let badge = Badge.badge(for: userStats.selectedBadgeId) {
                Image(badge.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color("MainBlue").opacity(0.2), lineWidth: 4))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            
            // User Name
            Text("\(userStats.displayName)'s Tidelog")
                .font(.system(size: 28, weight: .bold))
        }
    }
    
    // MARK: - Progress Card
    private var progressCard: some View {
        let badge = userStats.nextBadge
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your on a roll!!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(badge.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Next badge preview
                if let nextBadge = getNextUnlockedBadge() {
                    Image(nextBadge.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow)
                        .frame(width: geo.size.width * badge.progress, height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(Color("MainBlue"))
        .cornerRadius(20)
    }
    
    // MARK: - Badge Grid
    private var badgeGrid: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(BadgeCategory.allCases, id: \.self) { category in
                VStack(alignment: .leading, spacing: 12) {
                    // Category Header with Progress
                    categoryHeader(for: category)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Badge.badges(for: category)) { badge in
                            badgeItem(badge)
                        }
                    }
                }
            }
        }
    }
    
    private func categoryHeader(for category: BadgeCategory) -> some View {
        let (current, nextThreshold, progress) = categoryProgress(for: category)
        let categoryBadges = Badge.badges(for: category)
        let unlockedCount = categoryBadges.filter { badge in
            badge.isUnlocked(
                creatures: userStats.uniqueCreatureCount,
                places: userStats.locationsVisited,
                quizzes: userStats.quizCorrect
            )
        }.count
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(unlockedCount)/\(categoryBadges.count) Badges")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("MainBlue"))
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                
                if nextThreshold > 0 {
                    Text("\(current) / \(nextThreshold) to next badge")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                } else {
                    Text("All badges unlocked! 🎉")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private func categoryProgress(for category: BadgeCategory) -> (current: Int, nextThreshold: Int, progress: Double) {
        let currentValue: Int
        switch category {
        case .creatures:
            currentValue = userStats.uniqueCreatureCount
        case .places:
            currentValue = userStats.locationsVisited
        case .quizzes:
            currentValue = userStats.quizCorrect
        }
        
        let thresholds = Badge.badges(for: category).map { $0.threshold }.sorted()
        
        // Find next threshold
        guard let nextThreshold = thresholds.first(where: { $0 > currentValue }) else {
            // All unlocked
            return (currentValue, 0, 1.0)
        }
        
        // Absolute progress: current / nextThreshold
        // e.g., if next is 10 and you have 5, progress is 50%
        let progress = nextThreshold > 0 ? Double(currentValue) / Double(nextThreshold) : 0.0
        
        return (currentValue, nextThreshold, progress)
    }
    
    private func badgeItem(_ badge: Badge) -> some View {
        let isUnlocked = badge.isUnlocked(
            creatures: userStats.uniqueCreatureCount,
            places: userStats.locationsVisited,
            quizzes: userStats.quizCorrect
        )
        let isSelected = userStats.selectedBadgeId == badge.id
        
        return Button(action: {
            if isUnlocked {
                userStats.setSelectedBadge(badge.id)
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color("MainBlue").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    // Always show badge image
                    Image(badge.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .saturation(isUnlocked ? 1.0 : 0.0) // Greyscale when locked
                        .opacity(isUnlocked ? 1.0 : 0.5) // Dim when locked
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color("MainBlue") : Color.clear, lineWidth: 3)
                        )
                    
                    // Locked overlay
                    if !isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 70, height: 70)
                    }
                }
                
                Text(badgeLabel(for: badge))
                    .font(.system(size: 11))
                    .foregroundColor(isUnlocked ? .black : .gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .disabled(!isUnlocked)
    }
    
    private func badgeLabel(for badge: Badge) -> String {
        switch badge.category {
        case .creatures:
            return badge.threshold == 0 ? "First Steps" : "Caught \(badge.threshold) Creatures"
        case .places:
            return "Visited \(badge.threshold) \(badge.threshold == 1 ? "Place" : "Places")"
        case .quizzes:
            return "\(badge.threshold) Correct \(badge.threshold == 1 ? "Answer" : "Answers")"
        }
    }
    
    // MARK: - Account Actions
    private var accountActions: some View {
        VStack(spacing: 12) {
            Button(action: {
                try? AuthManager.shared.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Animated Wave Footer
    private var animatedWaveFooter: some View {
        VStack(spacing: 0) {
            Spacer()
            AnimatedWaveView {
                VStack(spacing: 6) {
                    Image(systemName: "camera")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Add some badges!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Helpers
    private func getNextUnlockedBadge() -> Badge? {
        // Find first locked badge in creatures category
        let creatures = userStats.uniqueCreatureCount
        let places = userStats.locationsVisited
        let quizzes = userStats.quizCorrect
        
        return Badge.allBadges.first { badge in
            !badge.isUnlocked(creatures: creatures, places: places, quizzes: quizzes)
        }
    }
    
    private func deleteAccount() async {
        isDeleting = true
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Delete Firestore document
            try await Firestore.firestore().collection("users").document(userId).delete()
            
            // Delete Firebase Auth user
            try await Auth.auth().currentUser?.delete()
            
            // Clear local data
            UserDefaults.standard.removeObject(forKey: "displayName")
            UserDefaults.standard.removeObject(forKey: "creatureCounts")
            UserDefaults.standard.removeObject(forKey: "selectedBadgeId")
            
            print("✅ Account deleted successfully")
        } catch {
            print("Error deleting account: \(error)")
        }
        
        isDeleting = false
    }
}

#Preview {
    AccountView()
}
