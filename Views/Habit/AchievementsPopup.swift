import SwiftUI

// Achievements popup
struct AchievementsPopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            Text("Achievements")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { i in
                        AchievementRow(
                            title: "Achievement \(i)",
                            description: "Complete \(i*5) habits",
                            isUnlocked: i <= 3
                        )
                    }
                }
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
}

// Single achievement row
struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isUnlocked ? "trophy.fill" : "lock.fill")
                .font(.title2)
                .foregroundColor(isUnlocked ? .yellow : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
} 