import SwiftUI

// Weekday progress view (single day cell)
struct WeekdayProgressView: View {
    let dayOffset: Int
    let status: CompletionStatus
    
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
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private var dayColor: Color {
        return status.color
    }
} 