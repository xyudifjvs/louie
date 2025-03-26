import SwiftUI

// Weekday progress view (single day cell)
struct WeekdayProgressView: View {
    let dayOffset: Int
    let habit: Habit
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dayLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Circle()
                .fill(dayColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    // Computed properties
    private var dayLabel: String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private var dayColor: Color {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
            return Color.gray.opacity(0.3)
        }
        
        let day = calendar.component(.day, from: date)
        
        // Check if habit was completed on this day
        if let isCompleted = habit.progress[day] {
            return isCompleted ? Color.green.opacity(0.9) : Color.red.opacity(0.8)
        }
        
        // No data for this day
        return Color.gray.opacity(0.3)
    }
} 