// Storage for mood data: habitId -> date -> mood emoji
private var moodData: [UUID: [Date: String]] = [:]

// Storage for notes data: habitId -> date -> notes text
private var notesData: [UUID: [Date: String]] = [:]

// Save mood for a habit on a specific date
func saveMoodForHabit(_ habitId: UUID, mood: String?, forDate date: Date) {
    let calendar = Calendar.current
    let dateWithoutTime = calendar.startOfDay(for: date)
    
    if moodData[habitId] == nil {
        moodData[habitId] = [:]
    }
    
    moodData[habitId]?[dateWithoutTime] = mood
    saveToLocalStorage()
}

// Get mood for a habit on a specific date
func getMoodForHabit(_ habitId: UUID, forDate date: Date) -> String? {
    let calendar = Calendar.current
    let dateWithoutTime = calendar.startOfDay(for: date)
    return moodData[habitId]?[dateWithoutTime]
}

// Save notes for a habit on a specific date
func saveNotesForHabit(_ habitId: UUID, notes: String, forDate date: Date) {
    let calendar = Calendar.current
    let dateWithoutTime = calendar.startOfDay(for: date)
    
    if notesData[habitId] == nil {
        notesData[habitId] = [:]
    }
    
    notesData[habitId]?[dateWithoutTime] = notes
    saveToLocalStorage()
}

// Get notes for a habit on a specific date
func getNotesForHabit(_ habitId: UUID, forDate date: Date) -> String? {
    let calendar = Calendar.current
    let dateWithoutTime = calendar.startOfDay(for: date)
    return notesData[habitId]?[dateWithoutTime]
}

// Update saveToLocalStorage to include mood and notes data
private func saveToLocalStorage() {
    // Save existing habit data
    if let encodedHabits = try? JSONEncoder().encode(habits) {
        UserDefaults.standard.set(encodedHabits, forKey: "habits")
    }
    
    // Save mood data
    if let encodedMoodData = try? JSONEncoder().encode(moodData) {
        UserDefaults.standard.set(encodedMoodData, forKey: "habitMoodData")
    }
    
    // Save notes data
    if let encodedNotesData = try? JSONEncoder().encode(notesData) {
        UserDefaults.standard.set(encodedNotesData, forKey: "habitNotesData")
    }
}

// Update loadFromLocalStorage to include mood and notes data
private func loadFromLocalStorage() {
    // Load existing habit data
    if let savedHabits = UserDefaults.standard.data(forKey: "habits"),
       let decodedHabits = try? JSONDecoder().decode([Habit].self, from: savedHabits) {
        habits = decodedHabits
    }
    
    // Load mood data
    if let savedMoodData = UserDefaults.standard.data(forKey: "habitMoodData"),
       let decodedMoodData = try? JSONDecoder().decode([UUID: [Date: String]].self, from: savedMoodData) {
        moodData = decodedMoodData
    }
    
    // Load notes data
    if let savedNotesData = UserDefaults.standard.data(forKey: "habitNotesData"),
       let decodedNotesData = try? JSONDecoder().decode([UUID: [Date: String]].self, from: savedNotesData) {
        notesData = decodedNotesData
    }
}

// Function to calculate streak for a habit ID
func calculateStreak(for habitId: UUID) -> Int {
    guard let habit = habits.first(where: { $0.id == habitId }) else {
        return 0
    }
    
    // Simple placeholder implementation - in a real app, this would be more sophisticated
    // and would account for habit frequency settings
    var streak = 0
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    var currentDate = today
    
    while true {
        let status = getCompletionStatus(for: habit, on: currentDate)
        
        if status == .completed {
            streak += 1
        } else {
            break // Break on first non-completed day
        }
        
        // Go back one day
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
        currentDate = previousDate
        
        // Limit to reasonable streak length for performance
        if streak >= 365 {
            break
        }
    }
    
    return streak
}

// Log habit completion status for a specific day
func logHabitCompletion(_ habitId: UUID, day: Int, isCompleted: Bool) {
    if let index = habits.firstIndex(where: { $0.id == habitId }) {
        // Update the habit's progress
        habits[index].progress[day] = isCompleted
        
        // Update completions dictionary for consistency
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if completions[habitId] == nil {
            completions[habitId] = [:]
        }
        
        completions[habitId]?[today] = isCompleted ? .completed : .notCompleted
        
        // Save changes
        saveHabits()
    }
} 