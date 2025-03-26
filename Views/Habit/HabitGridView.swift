import SwiftUI

/// A calendar-style grid view for displaying and updating habit completion status
struct HabitGridView: View {
    // MARK: - Properties
    
    /// The habit to display and update
    @ObservedObject var viewModel: HabitViewModel
    
    /// The habit being displayed
    let habit: Habit
    
    /// The month to display (any date within the month)
    let month: Date
    
    /// Size of each cell in the grid
    private let cellSize: CGFloat = 35
    
    // MARK: - Computed Properties
    
    /// Returns all dates to display in the grid, including days from adjacent months
    private var gridDates: [Date] {
        // Get the first day of the month
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
        
        // Find the first Sunday before or on the first day of the month
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToSubtract = weekday - 1 // Sunday is 1 in Calendar
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth) else { return [] }
        
        // Find the last day of the month
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth),
              let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else { return [] }
        
        // Find the last Saturday after or on the last day of the month
        let lastWeekday = calendar.component(.weekday, from: lastDayOfMonth)
        let daysToAdd = 7 - lastWeekday // Saturday is 7 in Calendar
        guard let endDate = calendar.date(byAdding: .day, value: daysToAdd, to: lastDayOfMonth) else { return [] }
        
        // Generate all dates from startDate to endDate
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
    
    /// Returns the weekday labels (S, M, T, W, T, F, S)
    private var weekdayLabels: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday header row
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: cellSize, height: 20)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: 7), spacing: 4) {
                ForEach(gridDates, id: \.timeIntervalSince1970) { date in
                    DayCell(
                        date: date,
                        month: month,
                        status: completionStatus(for: date),
                        cellSize: cellSize,
                        // Disable onTap interaction for calendar view
                        onTap: { /* Empty closure - disabled in calendar view */ }
                    )
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    /// Returns the completion status for a habit on a specific date
    private func completionStatus(for date: Date) -> CompletionStatus {
        // Get the start of the day (midnight) for the given date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Call the new method on the view model
        return viewModel.getCompletionStatus(forHabit: habit.id, on: startOfDay)
    }
    
    /// Toggles the completion status for a habit on a specific date
    private func toggleStatus(for date: Date) {
        // Get the start of the day (midnight) for the given date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Update the status in the view model
        if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
            let currentStatus = completionStatus(for: date)
            if currentStatus == .completed {
                viewModel.updateHabitCompletion(habitId: habit.id, status: .notCompleted)
            } else {
                viewModel.updateHabitCompletion(habitId: habit.id, status: .completed)
            }
        }
    }
}

/// A single day cell in the habit grid
struct DayCell: View {
    // MARK: - Properties
    
    /// The date this cell represents
    let date: Date
    
    /// The month being displayed
    let month: Date
    
    /// The completion status for this date
    let status: CompletionStatus
    
    /// The size of the cell
    let cellSize: CGFloat
    
    /// Callback when the cell is tapped
    let onTap: () -> Void
    
    // MARK: - Computed Properties
    
    /// Returns true if this date is in the displayed month
    private var isInCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.component(.month, from: date) == calendar.component(.month, from: month)
    }
    
    /// Returns the day number as a string
    private var dayText: String {
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: date))"
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Text(dayText)
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(isInCurrentMonth ? 1.0 : 0.5)
                
                Rectangle()
                    .fill(status.color)
                    .opacity(isInCurrentMonth ? 1.0 : 0.5)
                    .frame(width: cellSize - 8, height: cellSize - 20)
                    .cornerRadius(4)
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 