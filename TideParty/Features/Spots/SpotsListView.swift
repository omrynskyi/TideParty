import SwiftUI

struct SpotsListView: View {
    @ObservedObject var viewModel: SpotsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Spots List
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let error = viewModel.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.spots) { spot in
                            SpotCardView(
                                spot: spot,
                                tideHeight: 3.0, // Placeholder - integrate with TideService
                                onGoTidePooling: {
                                    // Navigate to spot detail
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Bottom padding for wave section (180 approx height of wave + bottom safe area)
                Spacer().frame(height: 180)
            }
            .padding(.top, 16) // Spacing from sticky header
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#Preview {
    SpotsListView(viewModel: SpotsViewModel())
}
