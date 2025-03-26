import Foundation
import SwiftUI
import Combine

// MARK: - Habit Tracker Module (Dark UI Example)
class HabitTrackerViewModel: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits()
        }
    }
    
    // Add completions dictionary for habit status tracking
    @Published var completions: [UUID: [Date: CompletionStatus]] = [:]
    
    // Storage for mood data: habitId -> date -> mood emoji
    private var moodData: [UUID: [Date: String]] = [:]
    
    // Storage for notes data: habitId -> date -> notes text
    private var notesData: [UUID: [Date: String]] = [:]
    
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
} 
