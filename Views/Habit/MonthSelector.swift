import SwiftUI

// Add missing MonthSelector component
struct MonthSelector: View {
    @Binding var selectedMonth: Date
    
    var body: some View {
        HStack {
            previousMonthButton
            
            Spacer()
            
            monthYearText
            
            Spacer()
            
            nextMonthButton
        }
        .padding()
    }
    
    // Previous month button
    private var previousMonthButton: some View {
        Button(action: {
            changeMonth(by: -1)
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
        }
    }
    
    // Month and year text
    private var monthYearText: some View {
        Text(monthYearFormatter.string(from: selectedMonth))
            .font(.headline)
            .foregroundColor(.white)
    }
    
    // Next month button
    private var nextMonthButton: some View {
        Button(action: {
            changeMonth(by: 1)
        }) {
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
        }
    }
    
    // Helper method to change month
    private func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
} 