import Foundation
import SwiftUI
import Combine

// Add HabitViewModel class
// This ViewModel might be unnecessary if HabitGridView can use HabitTrackerViewModel directly
// Or it should be refactored to only hold data relevant to a SINGLE habit.
class HabitViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Dictionary to store completion status for each habit and date
    // Keep completions if this ViewModel manages state for a single habit view
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
    
    /// Saves the completions dictionary to UserDefaults
    private func saveCompletions() {
        // Implementation would go here - convert completions to Data and save to UserDefaults
    }
    
    /// Loads the completions dictionary from UserDefaults
    private func loadCompletions() {
        // Implementation would go here - load Data from UserDefaults and convert to completions dictionary
    }
} 