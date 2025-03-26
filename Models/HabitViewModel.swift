import Foundation
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
    func getStatus(for habit: Habit, on date: Date) -> CompletionStatus {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Check in completions dictionary
        if let habitCompletions = completions[habit.id] {
            return habitCompletions[startOfDay] ?? CompletionStatus.noData
        }
        
        return CompletionStatus.noData
    }
    
    /// Returns the completion status for a habit ID on a specific date
    func getCompletionStatus(forHabit habitId: UUID, on date: Date) -> CompletionStatus {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Check in completions dictionary
        if let habitCompletions = completions[habitId] {
            return habitCompletions[startOfDay] ?? CompletionStatus.noData
        }
        
        return CompletionStatus.noData
    }
    
    /// Updates the completion status for a habit
    func updateHabitCompletion(habitId: UUID, status: CompletionStatus) {
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Update the habit's progress
        if status == .completed {
            habits[index].completed = true
        } else {
            habits[index].completed = false
        }
        
        // Update completions dictionary
        if completions[habitId] == nil {
            completions[habitId] = [:]
        }
        
        completions[habitId]?[today] = status
        
        // Save the updated completions
        saveCompletions()
    }
    
    /// Toggles the completion status for a habit on a specific date
    func toggleCompletionStatus(for habit: Habit, on date: Date) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let currentStatus = getStatus(for: habit, on: date)
        
        // Update the completions dictionary
        if completions[habit.id] == nil {
            completions[habit.id] = [:]
        }
        
        completions[habit.id]?[date] = currentStatus.next
        
        // Update the habit's progress (old format, for compatibility)
        let day = Calendar.current.component(.day, from: date)
        let isCompleted = currentStatus.next == CompletionStatus.completed
        habits[index].progress[day] = isCompleted
        
        // If today, update completed flag
        if calendar.isDateInToday(date) {
            habits[index].completed = isCompleted
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
    init(tracker: HabitTrackerViewModel? = nil) {
        if let tracker = tracker {
            self.habits = tracker.habits
            self.completions = tracker.completions
        }
    }
} 