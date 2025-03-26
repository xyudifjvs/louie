import SwiftUI

// This is a thin wrapper that uses the implementation from ModularContentView
struct ContentView: View {
    var body: some View {
        ModularContentView()
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

