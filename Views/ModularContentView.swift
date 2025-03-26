import SwiftUI
// ChatGPT Integration Successful


// This file holds the core UI structure (splash screen logic, tab views, etc.)
// It is displayed via `ContentView.swift`, which acts as a simple wrapper.

// MARK: - ModularContentView with Splash + TabView
struct ModularContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                DarkSplashScreen()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                MainTabView() // Show the TabView after splash
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Preview
struct ModularContentView_Previews: PreviewProvider {
    static var previews: some View {
        ModularContentView()
    }
} 