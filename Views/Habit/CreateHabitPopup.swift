import SwiftUI

// Create habit popup
struct CreateHabitPopup: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var description = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var customDays: [Int] = []
    @State private var selectedEmoji: String = "📝"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("New Habit")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .foregroundColor(.white)
                
                TextField("📝", text: $selectedEmoji)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onChange(of: selectedEmoji) { newValue in
                        if newValue.count > 1 {
                            selectedEmoji = String(newValue.prefix(1))
                        }
                    }
                
                Text("Title")
                    .foregroundColor(.white)
                
                TextField("", text: $title)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                Text("Description (Optional)")
                    .foregroundColor(.white)
                
                TextField("", text: $description)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                Text("Frequency")
                    .foregroundColor(.white)
                
                Picker("Frequency", selection: $frequency) {
                    ForEach([HabitFrequency.daily, .weekly, .monthly, .custom], id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if frequency == .custom {
                    CustomDaysSelector(customDays: $customDays)
                }
            }
            
            Button(action: {
                addHabit()
                isPresented = false
            }) {
                Text("Create Habit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .disabled(title.isEmpty)
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    private func addHabit() {
        viewModel.addHabit(
            title: title,
            description: description,
            reminderTime: Date(), // Default value, as field was removed
            frequency: frequency,
            customDays: customDays,
            emoji: selectedEmoji.isEmpty ? "📝" : selectedEmoji
        )
    }
} 