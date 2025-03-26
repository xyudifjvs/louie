import SwiftUI

// MARK: - Daily Check-In (Dark UI + AI Insights)
struct DailyCheckInView: View {
    @State private var checkInText: String = ""
    @State private var aiResponse: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "3c1053"), Color(hex: "ad5389")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Daily Check-In")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                TextField("How are you feeling today?", text: $checkInText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .foregroundColor(.white)
                
                Button(action: submitCheckIn) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Submit Check-In")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                if !aiResponse.isEmpty {
                    Text("Your Daily Insights:")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    Text(aiResponse)
                        .foregroundColor(.white)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationTitle("Daily Check-In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func submitCheckIn() {
        guard !checkInText.isEmpty else { return }
        isSubmitting = true
        // Simulate AI call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            aiResponse = "Based on your input, consider maintaining your exercise routine and focusing on hydration for better mood stability."
            isSubmitting = false
        }
    }
} 