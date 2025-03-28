import SwiftUI

// MARK: - Gamification Module (Dark)
struct GamificationView: View {
    @State private var dailyStreak: Int = 5 // Placeholder
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "654ea3"), Color(hexCode: "eaafc8")]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    Text("Gamification")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                    
                    Text("Daily Streak: \(dailyStreak) days")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Gamification")
        .navigationBarTitleDisplayMode(.inline)
    }
} 