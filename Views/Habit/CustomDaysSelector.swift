import SwiftUI

// Add missing CustomDaysSelector component
struct CustomDaysSelector: View {
    @Binding var customDays: Array<Int>
    
    // Extract day names into a computed property
    private var dayNames: Array<String> {
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Extract header into a separate view
            daySelectionHeader
            
            // Extract day buttons into a separate view
            daySelectionButtons
        }
    }
    
    // Header view
    private var daySelectionHeader: some View {
        Text("Select Days")
            .font(.caption)
            .foregroundColor(.white)
    }
    
    // Day buttons view
    private var daySelectionButtons: some View {
        HStack {
            ForEach(1...7, id: \.self) { day in
                dayButton(for: day)
            }
        }
    }
    
    // Individual day button
    private func dayButton(for day: Int) -> some View {
        let dayName = dayNames[day-1]
        let isSelected = customDays.contains(day)
        
        return Button(action: {
            toggleDay(day)
        }) {
            Text(dayName)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.purple : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }
    
    // Toggle day selection
    private func toggleDay(_ day: Int) {
        if customDays.contains(day) {
            customDays.removeAll { $0 == day }
        } else {
            customDays.append(day)
        }
    }
} 