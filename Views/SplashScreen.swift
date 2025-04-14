import SwiftUI

struct DarkSplashScreen: View {
    @State private var offset = CGSize(width: -150, height: -200)
    @State private var shouldNavigate = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hexCode: "121212"), Color(hexCode: "1e1e1e")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LouieSpriteView()
                .frame(width: 200, height: 200)
                .offset(offset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0)) {
                        offset = CGSize(width: 150, height: 250)
                    }

                    // After animation, do your actual screen switch here
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        shouldNavigate = true
                        // Replace with navigation or state change
                    }
                }

            Text("Fetching your data...")
                .foregroundColor(.white)
                .font(.headline)
                .opacity(0.8)
                .offset(y: 250)
        }
    }
}

struct LouieSpriteView: View {
    @State private var frameIndex = 0
    private let frameCount = 4
    private let columns = 2
    private let rows = 2
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    let spriteSheet = UIImage(named: "louie_sprite_sheet")!

    var body: some View {
        let frameWidth = spriteSheet.size.width / CGFloat(columns)
        let frameHeight = spriteSheet.size.height / CGFloat(rows)
        let col = frameIndex % columns
        let row = frameIndex / columns

        let croppingRect = CGRect(
            x: CGFloat(col) * frameWidth,
            y: CGFloat(row) * frameHeight,
            width: frameWidth,
            height: frameHeight
        )

        let cropped = spriteSheet.cgImage?.cropping(to: croppingRect)
            .flatMap { UIImage(cgImage: $0) }

        return Image(uiImage: cropped ?? spriteSheet)
            .resizable()
            .scaledToFit()
            .onReceive(timer) { _ in
                frameIndex = (frameIndex + 1) % frameCount
            }
    }
}


