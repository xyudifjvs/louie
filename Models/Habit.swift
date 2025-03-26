import SwiftUI

struct Habit: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String = ""
    var reminderTime: Date
    var completed: Bool = false
    var progress: [Int: Bool] = [:]
    var frequency: HabitFrequency = .daily
    var customDays: [Int] = [] // 1 = Monday, 2 = Tuesday, etc.
    var emoji: String = "📝" // Default emoji
    
    // Mood tracking
    var moodEntries: [Date: MoodEntry] = [:]
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
struct MoodEntry: Codable {
    var mood: Mood
    var reflection: String
    var date: Date
}

enum HabitFrequency: String, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
} 