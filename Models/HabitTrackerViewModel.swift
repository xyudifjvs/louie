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