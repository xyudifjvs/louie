import SwiftUI

// MARK: - Nutrition Module (Dark Placeholder)
struct NutritionView: View {
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "1a1a2e"), Color(hex: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Nutrition")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                Button(action: {
                    showAlert = true
                }) {
                    Text("Log Meal")
                        .font(.headline)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Meal Logged"),
                          message: Text("Meal analyzed: 500 calories, macros: ..."),
                          dismissButton: .default(Text("OK")))
                }
            }
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
    }
} 