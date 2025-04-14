import SwiftUI

// MARK: - Habit Data Model
// Make struct conform to Equatable
public struct Habit: Identifiable, Codable, Equatable {
    public let id: UUID
    var title: String
    var description: String = ""
    var reminderTime: Date
    var completed: Bool = false
    var frequency: HabitFrequency = .daily
    var customDays: [Int] = [] // 1 = Monday, 2 = Tuesday, etc.
    var emoji: String = "📝" // Default emoji
    var streak: Int = 0 // Current streak count
    
    // Mood tracking
    var moodEntries: [Date: MoodEntry] = [:]

    // Add Equatable conformance
    public static func == (lhs: Habit, rhs: Habit) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.reminderTime == rhs.reminderTime && // Might need tolerance for Date comparison
               lhs.frequency == rhs.frequency &&
               lhs.customDays == rhs.customDays &&
               lhs.emoji == rhs.emoji &&
               lhs.streak == rhs.streak &&
               lhs.completed == rhs.completed &&
               lhs.moodEntries == rhs.moodEntries // Dictionary comparison works if MoodEntry is Equatable
    }
}

// Enum for tracking user mood
enum Mood: String, Codable {
    case happy = "😊"
    case neutral = "😐"
    case angry = "😠"
    case sad = "😢"
    
    var description: String {
        switch self {
        case .happy: return "Happy"
        case .neutral: return "Indifferent"
        case .angry: return "Angry"
        case .sad: return "Sad"
        }
    }
}

// Structure to store mood and reflection
public struct MoodEntry: Identifiable, Codable, Equatable {
    public let id = UUID()
    var mood: Mood
    var reflection: String
    var date: Date

    // Add Equatable conformance
    public static func == (lhs: MoodEntry, rhs: MoodEntry) -> Bool {
        return lhs.mood == rhs.mood &&
               lhs.reflection == rhs.reflection &&
               lhs.date == rhs.date
    }
}

enum HabitFrequency: String, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
} 