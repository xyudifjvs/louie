import Foundation
import SwiftUI
import Combine
import CloudKit

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
    
    // CloudKit manager for syncing data
    private let cloudKitManager = CloudKitManager.shared
    
    // Flag to track cloud sync state
    private var isSyncingWithCloud = false
    
    init() {
        loadHabits()

        #if !DEBUG
        syncWithCloudKit()
        #else
        // Prevent CloudKit sync when previewing in Xcode
        if !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") {
            syncWithCloudKit()
        }
        #endif
    }
    
    func addHabit(title: String, description: String, reminderTime: Date, frequency: HabitFrequency, customDays: [Int] = [], emoji: String = "📝") {
        guard !title.isEmpty else { return }
        let newHabit = Habit(
            id: UUID(),
            title: title,
            description: description,
            reminderTime: reminderTime,
            frequency: frequency,
            customDays: frequency == .custom ? customDays : [],
            emoji: emoji
        )
        // Insert the new habit at the top of the list
        habits.insert(newHabit, at: 0)
        
        // Sync with CloudKit
        saveHabitToCloud(newHabit)
    }
    
    func toggleCompletion(for habit: Habit) {
        print("🔵 toggleCompletion called for habit: \(habit.title) (ID: \(habit.id))")
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            print("🔵 Found habit at index: \(index). Current completed state: \(habits[index].completed)")
            habits[index].completed.toggle()
            print("🔵 Toggled completed state to: \(habits[index].completed)")
            
            // Update completions dictionary for HabitGridView compatibility
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if completions[habit.id] == nil {
                completions[habit.id] = [:]
            }
            
            let status: CompletionStatus = habits[index].completed ? .completed : .notCompleted
            completions[habit.id]?[today] = status
            
            // Sync completion status with CloudKit
            saveCompletionToCloud(habitID: habit.id, date: today, status: status)
        }
    }
    
    // Function to get completion status for a habit on a specific date
    func getCompletionStatusByID(forHabit habitID: UUID, on date: Date) -> CompletionStatus {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date) // Ensure we use start of day for lookup
        
        // Read from the completions dictionary using habitID
        if let habitCompletions = completions[habitID],
           let status = habitCompletions[startOfDay] {
            return status
        }
        
        // If no entry in completions, return noData
        return CompletionStatus.noData
    }
    
    // Helper function for calculateStreak which still uses index
    private func getCompletionStatusByIndex(forHabit index: Int, on date: Date) -> CompletionStatus {
        guard index >= 0 && index < habits.count else {
            return .noData
        }
        let habitID = habits[index].id
        return getCompletionStatusByID(forHabit: habitID, on: date)
    }
    
    func reorderHabits(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex && fromIndex >= 0 && fromIndex < habits.count && toIndex >= 0 && toIndex < habits.count else { return }
        
        let habit = habits.remove(at: fromIndex)
        habits.insert(habit, at: toIndex)
    }
    
    func deleteHabit(at indexSet: IndexSet) {
        // Get the habits to delete
        let habitsToDelete = indexSet.map { habits[$0] }
        
        // Delete from local storage
        habits.remove(atOffsets: indexSet)
        
        // Delete from CloudKit
        for habit in habitsToDelete {
            deleteHabitFromCloud(habitID: habit.id)
        }
    }
    
    // MARK: - Persistence
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "habits")
        }
        
        // Don't save to CloudKit if we're currently syncing from CloudKit
        // Also, avoid potential loops by not automatically syncing *all* habits on every local save.
        // Consider a more deliberate sync strategy.
        /* // Comment out automatic sync-all
        if !isSyncingWithCloud {
            syncHabitsToCloud()
        }
        */
    }
    
    private func loadHabits() {
        if let savedHabits = UserDefaults.standard.data(forKey: "habits") {
            if var decodedHabits = try? JSONDecoder().decode([Habit].self, from: savedHabits) {
                // Filter out duplicates based on ID
                var uniqueHabits: [Habit] = []
                var seenIDs = Set<UUID>()
                for habit in decodedHabits {
                    if !seenIDs.contains(habit.id) {
                        uniqueHabits.append(habit)
                        seenIDs.insert(habit.id)
                    }
                }
                
                // Assign the de-duplicated array
                habits = uniqueHabits
                print("🔵 Loaded \(habits.count) unique habits from UserDefaults.")
            }
        }
        // Add call to load mood/notes data if it exists
        // loadFromLocalStorage() // Assuming this is defined elsewhere if needed
    }
    
    func addMoodEntry(for habit: Habit, mood: Mood, reflection: String = "") {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let today = Date()
            let moodEntry = MoodEntry(mood: mood, reflection: reflection, date: today)
            habits[index].moodEntries[today] = moodEntry
            saveHabits()
            
            // Sync mood to CloudKit
            saveMoodToCloud(habitID: habit.id, date: today, mood: mood.rawValue, notes: reflection)
        }
    }
    
    func updateHabit(habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            
            // Sync updated habit to CloudKit
            saveHabitToCloud(habit)
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
        
        // Sync mood to CloudKit
        saveMoodToCloud(habitID: habitId, date: dateWithoutTime, mood: mood, notes: getNotesForHabit(habitId, forDate: dateWithoutTime) ?? "")
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
        
        // Sync notes to CloudKit
        saveMoodToCloud(habitID: habitId, date: dateWithoutTime, mood: getMoodForHabit(habitId, forDate: dateWithoutTime), notes: notes)
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
    
    // MARK: - CloudKit Integration
    
    /// Sync all data with CloudKit
    private func syncWithCloudKit() {
        isSyncingWithCloud = true
        
        // Fetch habits from CloudKit
        cloudKitManager.fetchHabits { [weak self] result in
            // Ensure UI updates happen on the main thread
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let ckHabits):
                    // Convert CKHabits to app's Habit model
                    let cloudHabits = ckHabits.compactMap { ckHabit -> Habit? in
                        guard let id = UUID(uuidString: ckHabit.id.uuidString),
                              let frequency = HabitFrequency(rawValue: ckHabit.frequency) else {
                            return nil
                        }
                        
                        var habit = Habit(
                            id: id,
                            title: ckHabit.title,
                            description: ckHabit.description,
                            reminderTime: ckHabit.reminderTime,
                            frequency: frequency,
                            customDays: ckHabit.customDays,
                            emoji: ckHabit.emoji
                        )
                        
                        // Fetch completions for this habit (might also need main thread dispatch later)
                        self.fetchCompletionsForHabit(habit: habit)
                        
                        return habit
                    }
                    
                    // Merge cloud habits with local habits
                    self.mergeHabitsFromCloud(cloudHabits)
                    
                case .failure(let error):
                    // More detailed error logging
                    print("🔴 ERROR syncing habits with CloudKit: \(error.localizedDescription)")
                    if let ckError = error as? CKError {
                        print("🔴 CloudKit Error Code: \(ckError.code.rawValue)")
                        print("🔴 CloudKit UserInfo: \(ckError.userInfo)")
                    }
                    let errorMessage = self.cloudKitManager.handleCloudKitError(error) ?? "Unknown error syncing habits"
                    print("🔴 Processed Error Message: \(errorMessage)")
                }
                
                self.isSyncingWithCloud = false // Update on main thread
            } // End DispatchQueue.main.async
        }
    }
    
    /// Fetch completions for a specific habit
    private func fetchCompletionsForHabit(habit: Habit) {
        cloudKitManager.fetchHabitCompletions(habitID: habit.id) { [weak self] result in
            // Ensure UI updates happen on the main thread
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let ckCompletions):
                    // Initialize completion dictionary for this habit if needed
                    if self.completions[habit.id] == nil {
                        self.completions[habit.id] = [:]
                    }
                    
                    // Add completions to dictionary
                    for ckCompletion in ckCompletions {
                        let status: CompletionStatus
                        switch ckCompletion.status {
                        case "completed":
                            status = .completed
                        case "notCompleted":
                            status = .notCompleted
                        default:
                            status = .noData
                        }
                        
                        let calendar = Calendar.current
                        let date = calendar.startOfDay(for: ckCompletion.date)
                        self.completions[habit.id]?[date] = status
                    }
                    
                    // Update streaks
                    self.updateStreaksForHabit(habitID: habit.id)
                    
                case .failure(let error):
                    print("Error fetching completions for habit: \(error.localizedDescription)")
                }
            } // End DispatchQueue.main.async
        }
    }
    
    /// Merge habits from CloudKit with local habits
    private func mergeHabitsFromCloud(_ cloudHabits: [Habit]) {
        // Use a dictionary for efficient local lookup by ID
        var localHabitsDict = Dictionary(uniqueKeysWithValues: self.habits.map { ($0.id, $0) })
        var habitsToAdd: [Habit] = []
        var habitsToUpdate: [Habit] = []
        
        // Process cloud habits
        for cloudHabit in cloudHabits {
            if let existingLocalHabit = localHabitsDict[cloudHabit.id] {
                // Habit exists locally. Compare timestamps (if available) or decide on merge strategy.
                // For now, let's assume cloud wins if different (simplest approach).
                // A real merge might compare updatedAt timestamps.
                if existingLocalHabit != cloudHabit { // Basic check if they differ
                    habitsToUpdate.append(cloudHabit)
                }
                // Remove from dict so we know it was matched
                localHabitsDict.removeValue(forKey: cloudHabit.id)
            } else {
                // Habit only exists in the cloud, add it.
                habitsToAdd.append(cloudHabit)
            }
        }
        
        // Process local habits that were NOT in the cloud
        // These might be new habits created offline.
        let localOnlyHabits = Array(localHabitsDict.values)
        for localHabit in localOnlyHabits {
            // Save these to the cloud
            saveHabitToCloud(localHabit)
        }
        
        // Apply updates and additions to the main habits array
        DispatchQueue.main.async { // Ensure this update is on the main thread
            var finalHabits = self.habits // Start with current local habits
            
            // Remove habits that were updated (we'll add the updated version)
            let updateIDs = Set(habitsToUpdate.map { $0.id })
            finalHabits.removeAll { updateIDs.contains($0.id) }
            
            // Add the updated and new habits
            finalHabits.append(contentsOf: habitsToUpdate)
            finalHabits.append(contentsOf: habitsToAdd)
            
            // You might want to re-sort the list here, e.g., by createdAt descending
            finalHabits.sort { (h1: Habit, h2: Habit) -> Bool in
                // Assuming Habit has createdAt property for sorting
                // If not, replace with appropriate property like title or reminderTime
                // Ensure createdAt exists and is comparable
                // return h1.createdAt > h2.createdAt 
                return h1.title < h2.title // Example: Sort alphabetically by title if createdAt is missing
            }
            
            // Update the main published property
            // Check if the array content has actually changed before assigning to avoid unnecessary UI updates
            if self.habits != finalHabits {
                self.habits = finalHabits
                print("🔵 Habits merged. Total count: \(self.habits.count)")
            }
        }
    }
    
    /// Update streaks for a habit
    private func updateStreaksForHabit(habitID: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == habitID }) else { return }
        
        let streak = calculateStreak(forHabit: index)
        habits[index].streak = streak
    }
    
    /// Save a habit to CloudKit
    private func saveHabitToCloud(_ habit: Habit) {
        cloudKitManager.saveHabit(habit) { result in
            // Dispatch UI-related logging or potential future state updates to main thread
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully saved habit to CloudKit: \(habit.title)")
                    // Potentially update some state here if needed
                case .failure(let error):
                    print("Error saving habit to CloudKit: \(error.localizedDescription)")
                    // Potentially update error state here if needed
                }
            }
        }
    }
    
    /// Save a completion status to CloudKit
    private func saveCompletionToCloud(habitID: UUID, date: Date, status: CompletionStatus) {
        cloudKitManager.saveHabitCompletion(habitID: habitID, date: date, status: status) { result in
            // Dispatch UI-related logging or potential future state updates to main thread
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully saved completion status to CloudKit")
                case .failure(let error):
                    print("Error saving completion status to CloudKit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Save mood and notes to CloudKit
    private func saveMoodToCloud(habitID: UUID, date: Date, mood: String?, notes: String) {
        cloudKitManager.saveMoodLog(habitID: habitID, date: date, mood: mood, notes: notes) { result in
            // Dispatch UI-related logging or potential future state updates to main thread
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully saved mood log to CloudKit")
                case .failure(let error):
                    print("Error saving mood log to CloudKit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Delete a habit from CloudKit
    private func deleteHabitFromCloud(habitID: UUID) {
        cloudKitManager.deleteHabit(habitID: habitID) { result in
            // Dispatch UI-related logging or potential future state updates to main thread
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully deleted habit from CloudKit")
                case .failure(let error):
                    print("Error deleting habit from CloudKit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Sync all habits to CloudKit
    private func syncHabitsToCloud() {
        for habit in habits {
            saveHabitToCloud(habit)
        }
    }
    
    // Function to calculate streak for a habit ID
    func calculateStreak(forHabit index: Int) -> Int {
        guard index >= 0 && index < habits.count else {
            return 0
        }
        
        let habit = habits[index]
        var streak = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentDate = today
        
        while true {
            // Use the helper function that takes an index
            let status = getCompletionStatusByIndex(forHabit: index, on: currentDate)
            
            if status == CompletionStatus.completed {
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
    
    // Function to calculate streak for a habit UUID
    func calculateStreak(for habitId: UUID) -> Int {
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else {
            return 0
        }
        
        return calculateStreak(forHabit: index)
    }
    
    // Log habit completion status for a specific day
    func logHabitCompletion(_ habitId: UUID, day: Int, isCompleted: Bool) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            // Update the habit's progress
            // habits[index].progress[day] = isCompleted
            
            // Update completions dictionary for consistency
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if completions[habitId] == nil {
                completions[habitId] = [:]
            }
            
            completions[habitId]?[today] = isCompleted ? CompletionStatus.completed : CompletionStatus.notCompleted
            
            // Save changes
            saveHabits()
        }
    }
    
    func updateHabitCompletion(habitId: UUID, status: CompletionStatus) {
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Update the habit's progress
        if status == CompletionStatus.completed {
            habits[index].completed = true
            
            // Update streak
            habits[index].streak = calculateStreak(forHabit: index)
        } else {
            habits[index].completed = false
        }
        
        // Update completions dictionary for consistency
        if completions[habitId] == nil {
            completions[habitId] = [:]
        }
        
        completions[habitId]?[today] = status
        
        // Save changes
        saveHabits()
    }
    
    func updateHabit(at index: Int, isCompleted: Bool) {
        guard index >= 0 && index < habits.count else { return }
        
        habits[index].completed.toggle()
        
        // Update completions dictionary for consistency
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let status: CompletionStatus = habits[index].completed ? CompletionStatus.completed : CompletionStatus.notCompleted
        
        // Ensure there's a dictionary for this habit
        if completions[habits[index].id] == nil {
            completions[habits[index].id] = [:]
        }
        
        // Update the status for today
        completions[habits[index].id]?[today] = status
        
        // Update the streak
        habits[index].streak = calculateStreak(forHabit: index)
        
        // Save changes
        saveHabits()
    }
} 
