import SwiftUI

// A darker, modern splash screen
struct DarkSplashScreen: View {
    var body: some View {
        ZStack {
            // Use the same gradient as HabitTrackerView for consistency
            LinearGradient(
                gradient: Gradient(colors: [Color(hexCode: "121212"), Color(hexCode: "1e1e1e")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Show the Louie mascot image centered on screen
            Image("SplashImage")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
        }
    }
} 