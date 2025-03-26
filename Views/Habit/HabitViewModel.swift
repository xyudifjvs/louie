/// Returns the completion status for a habit on a specific date
func getCompletionStatus(forHabit habitId: UUID, on date: Date) -> CompletionStatus {
    // If we have a direct tracker, delegate to it
    if let index = habits.firstIndex(where: { $0.id == habitId }) {
        // Check in completions dictionary
        if let habitCompletions = completions[habitId],
           let status = habitCompletions[date] {
            return status
        }
        
        return CompletionStatus.noData
    }
    
    return CompletionStatus.noData
} 