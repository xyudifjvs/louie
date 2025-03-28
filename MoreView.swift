import SwiftUI

struct MoreView: View {
    var body: some View {
        ZStack {
            // Full-screen gradient
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "654ea3"), Color(hexCode: "eaafc8")]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        NavigationLink(destination: DailyCheckInView()) {
                            Text("Check-In")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
 
                        NavigationLink(destination: GamificationView()) {
                            Text("Rewards")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .background(Color.clear) // Removes default ScrollView background
                .navigationTitle("More")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar) // Force NavigationView to be transparent
            }
            .background(Color.clear) // Ensures NavigationView does not add white background
        }
    }
} 