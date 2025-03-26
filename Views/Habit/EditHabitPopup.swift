import SwiftUI

// Edit habit popup
struct EditHabitPopup: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isPresented: Bool
    @State private var title: String
    @State private var description: String
    @State private var frequency: HabitFrequency
    @State private var reminderTime: Date // Keep for data model compatibility
    @State private var customDays: [Int]
    @State private var selectedEmoji: String
    
    init(habit: Habit, viewModel: HabitTrackerViewModel, isPresented: Binding<Bool>) {
        self.habit = habit
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._title = State(initialValue: habit.title)
        self._description = State(initialValue: habit.description)
        self._frequency = State(initialValue: habit.frequency)
        self._reminderTime = State(initialValue: habit.reminderTime)
        self._customDays = State(initialValue: habit.customDays)
        self._selectedEmoji = State(initialValue: habit.emoji)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Edit Habit")
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
                
                Text("Description")
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
            
            HStack {
                Button(action: {
                    deleteHabit()
                    isPresented = false
                }) {
                    Text("Delete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    updateHabit()
                    isPresented = false
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                }
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    private func updateHabit() {
        if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
            viewModel.habits[index].title = title
            viewModel.habits[index].description = description
            viewModel.habits[index].frequency = frequency
            viewModel.habits[index].reminderTime = reminderTime // Keep for data model compatibility
            viewModel.habits[index].customDays = customDays
            viewModel.habits[index].emoji = selectedEmoji.isEmpty ? "📝" : selectedEmoji
        }
    }
    
    private func deleteHabit() {
        if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
            viewModel.habits.remove(at: index)
        }
    }
} 