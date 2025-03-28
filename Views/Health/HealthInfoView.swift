import SwiftUI

// MARK: - Health Info Module (Dark Placeholder)
struct HealthInfoView: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "2b5876"), Color(hexCode: "4e4376")]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 10) {
                Text("Health Info")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                // Placeholder for HealthKit integration
                Text("Steps: 0").foregroundColor(.white)
                Text("Sleep: 0h").foregroundColor(.white)
                Text("Heart Rate: 0 bpm").foregroundColor(.white)
            }
        }
        .navigationTitle("Health Info")
        .navigationBarTitleDisplayMode(.inline)
    }
} 