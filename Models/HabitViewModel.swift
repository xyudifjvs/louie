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