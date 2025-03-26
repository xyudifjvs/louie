import SwiftUI
import Combine

// Add HabitViewModel class
class HabitViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Published property to trigger view updates
    @Published var habits: [Habit] = []
    
    /// Dictionary to store completion status for each habit and date
    @Published var completions: [UUID: [Date: CompletionStatus]] = [:]
    
    // MARK: - Methods
    
    /// Returns the completion status for a habit on a specific date
    func getCompletionStatus(for habit: Habit, on date: Date) -> CompletionStatus {
        guard let habitCompletions = completions[habit.id] else {
            return .noData
        }
        
        return habitCompletions[date] ?? .noData
    }
    
    /// Toggles the completion status for a habit on a specific date
    func toggleCompletionStatus(for habit: Habit, on date: Date) {
        // Ensure we have a dictionary for this habit
        if completions[habit.id] == nil {
            completions[habit.id] = [:]
        }
        
        // Get the current status and toggle to the next one
        let currentStatus = getCompletionStatus(for: habit, on: date)
        completions[habit.id]?[date] = currentStatus.next
        
        // Also update the habit's progress dictionary for compatibility with existing code
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let day = Calendar.current.component(.day, from: date)
            let isCompleted = currentStatus.next == .completed
            habits[index].progress[day] = isCompleted
        }
        
        // Save the updated completions
        saveCompletions()
    }
    
    /// Saves the completions dictionary to UserDefaults
    private func saveCompletions() {
        // Implementation would go here - convert completions to Data and save to UserDefaults
    }
    
    /// Loads the completions dictionary from UserDefaults
    private func loadCompletions() {
        // Implementation would go here - load Data from UserDefaults and convert to completions dictionary
    }
    
    /// Initializer to convert from HabitTrackerViewModel
    init(from tracker: HabitTrackerViewModel) {
        self.habits = tracker.habits
        self.completions = tracker.completions
    }
}

// MARK: - Habit Tracker Module (Dark UI Example)
class HabitTrackerViewModel: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits()
        }
    }
    
    // Add completions dictionary for habit status tracking
    @Published var completions: [UUID: [Date: CompletionStatus]] = [:]
    
    init() {
        loadHabits()
    }
    
    func addHabit(title: String, description: String, reminderTime: Date, frequency: HabitFrequency, customDays: [Int] = [], emoji: String = "📝") {
        guard !title.isEmpty else { return }
        let newHabit = Habit(
            title: title,
            description: description,
            reminderTime: reminderTime,
            frequency: frequency,
            customDays: frequency == .custom ? customDays : [],
            emoji: emoji
        )
        // Insert the new habit at the top of the list
        habits.insert(newHabit, at: 0)
    }
    
    func toggleCompletion(for habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].completed.toggle()
            let day = Calendar.current.component(.day, from: Date())
            habits[index].progress[day] = habits[index].completed
            
            // Update completions dictionary for HabitGridView compatibility
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if completions[habit.id] == nil {
                completions[habit.id] = [:]
            }
            
            let status: CompletionStatus = habits[index].completed ? .completed : .notCompleted
            completions[habit.id]?[today] = status
        }
    }
    
    // Function to get completion status for a habit on a specific date
    func getCompletionStatus(for habit: Habit, on date: Date) -> CompletionStatus {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Check in completions dictionary first
        if let habitCompletions = completions[habit.id],
           let status = habitCompletions[startOfDay] {
            return status
        }
        
        // Check in old progress format as fallback
        let day = calendar.component(.day, from: date)
        if let isCompleted = habit.progress[day] {
            return isCompleted ? .completed : .notCompleted
        }
        
        return .noData
    }
    
    func reorderHabits(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex && fromIndex >= 0 && fromIndex < habits.count && toIndex >= 0 && toIndex < habits.count else { return }
        
        let habit = habits.remove(at: fromIndex)
        habits.insert(habit, at: toIndex)
    }
    
    func deleteHabit(at indexSet: IndexSet) {
        habits.remove(atOffsets: indexSet)
    }
    
    // MARK: - Persistence
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "habits")
        }
    }
    
    private func loadHabits() {
        if let savedHabits = UserDefaults.standard.data(forKey: "habits") {
            if let decodedHabits = try? JSONDecoder().decode([Habit].self, from: savedHabits) {
                habits = decodedHabits
            }
        }
    }
    
    func addMoodEntry(for habit: Habit, mood: Mood, reflection: String = "") {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let today = Date()
            let moodEntry = MoodEntry(mood: mood, reflection: reflection, date: today)
            habits[index].moodEntries[today] = moodEntry
            saveHabits()
        }
    }
    
    func updateHabit(habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        }
    }
    
    // Function to calculate streak for a habit
    func calculateStreak(for habit: Habit) -> Int {
        // Simple placeholder implementation - in a real app, this would be more sophisticated
        // and would account for habit frequency settings
        var streak = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentDate = today
        var dayOffset = 0
        
        while true {
            let status = getCompletionStatus(for: habit, on: currentDate)
            
            if status == .completed {
                streak += 1
            } else {
                break // Break on first non-completed day
            }
            
            // Go back one day
            dayOffset -= 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDate
            
            // Limit to reasonable streak length for performance
            if streak >= 365 {
                break
            }
        }
        
        return streak
    }
} 