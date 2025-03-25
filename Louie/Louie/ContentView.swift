struct HabitTrackerView: View {
    @StateObject private var viewModel = HabitTrackerViewModel()
    @State private var showingAddHabitSheet = false
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            HabitDashboardView(viewModel: viewModel)
        }
    }
}

// Habit Card View with updated layout - ellipsis button below emoji
struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isReordering: Bool
    @State private var showMoodTagPopup = false
    @State private var showEditHabit = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left section - emoji and edit button (reordered)
            VStack(alignment: .center) {
                Spacer()
                
                Text(habitEmoji)
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                Button(action: {
                    showEditHabit = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .frame(width: 60)
            .padding(.vertical, 10)
            
            // Center section - habit name and weekly progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let moodEntry = viewModel.getMoodEntry(for: habit) {
                        Text(moodEntry.mood.rawValue)
                            .font(.caption2)
                    }
                }
                
                if !habit.description.isEmpty {
                    Text(habit.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    ForEach(-6...0, id: \.self) { dayOffset in
                        WeekdayProgressView(
                            dayOffset: dayOffset,
                            habit: habit
                        )
                    }
                }
            }
            .padding(.horizontal, 10)
            
            // Right section - completion checkmark
            VStack {
                Button(action: {
                    viewModel.toggleCompletion(for: habit)
                    
                    // Fixed: Check if habit is marked as completed after toggling
                    let isNowCompleted = habit.completed || 
                        (viewModel.completions[habit.id]?[Calendar.current.startOfDay(for: Date())] == .completed)
                    
                    if isNowCompleted {
                        showMoodTagPopup = true
                    }
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 30))
                        .foregroundColor(isCompleted ? .green : .white.opacity(0.7))
                }
                
                if showStreakCounter {
                    Text("🔥 \(calculateStreak)")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .frame(width: 60)
            .padding(.trailing, 10)
        }
        .frame(height: 100)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showMoodTagPopup) {
            MoodTagPopup(habit: habit, viewModel: viewModel, isPresented: $showMoodTagPopup)
                .background(BackgroundBlurView())
        }
        .sheet(isPresented: $showEditHabit) {
            EditHabitPopup(habit: habit, viewModel: viewModel, isPresented: $showEditHabit)
                .background(BackgroundBlurView())
        }
    }
    
    // Use emoji from habit or first letter as fallback
    private var habitEmoji: String {
        if !habit.emoji.isEmpty {
            return habit.emoji
        }
        return String(habit.title.prefix(1))
    }
    
    // Computed properties
    private var isCompleted: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let habitCompletions = viewModel.completions[habit.id],
           let status = habitCompletions[today] {
            return status == .completed
        }
        return habit.completed
    }
    
    private var showStreakCounter: Bool {
        // Placeholder logic - would depend on user settings
        return true
    }
    
    private var calculateStreak: Int {
        return viewModel.calculateStreak(for: habit)
    }
}

// Update HabitCalendarView to use a solid black background
struct HabitCalendarView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Month selector
                MonthSelector(selectedMonth: $selectedMonth)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.habits) { habit in
                            HabitProgressCard(
                                habit: habit,
                                selectedMonth: selectedMonth,
                                viewModel: HabitViewModel(from: viewModel)
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Habit Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
} 