import SwiftUI

// Background blur view
struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 