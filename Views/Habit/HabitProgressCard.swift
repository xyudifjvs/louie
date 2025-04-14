import SwiftUI

// Add missing HabitProgressCard component
struct HabitProgressCard: View {
    let habit: Habit
    let selectedMonth: Date
    @EnvironmentObject var habitTrackerViewModel: HabitTrackerViewModel
    
    var body: some View {
        NavigationLink(destination: 
            HabitStatsView(habit: habit, viewModel: habitTrackerViewModel)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut, value: true)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                cardHeader
                
                if !habit.description.isEmpty {
                    descriptionText
                }
                
                // Use the HabitGridView instead
                HabitGridView(
                    viewModel: habitTrackerViewModel,
                    habit: habit,
                    month: selectedMonth
                )
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Card header with title and frequency badge
    private var cardHeader: some View {
        HStack {
            Text(habit.emoji)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            Text(habit.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            frequencyBadge
        }
    }
    
    // Description text
    private var descriptionText: some View {
        Text(habit.description)
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
    }
    
    // Frequency badge
    private var frequencyBadge: some View {
        Text(habit.frequency.rawValue)
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.3))
            .cornerRadius(8)
    }
} 