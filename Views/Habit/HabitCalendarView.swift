import SwiftUI

struct HabitCalendarView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var selectedMonth = Date()
    @State private var habitViewModels: [HabitViewModel] = []
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "1e1e1e")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                // Month selector at top
                MonthSelector(selectedMonth: $selectedMonth)
                
                // Scrollable list of habit cards with calendar grid
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.habits) { habit in
                            // For each habit, display a progress card with calendar
                            if let habitViewModel = habitViewModels.first(where: { $0.habits.contains(where: { $0.id == habit.id }) }) {
                                HabitProgressCard(
                                    habit: habit,
                                    selectedMonth: selectedMonth,
                                    viewModel: habitViewModel
                                )
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Habit Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .environmentObject(viewModel)
        .onAppear {
            // Create a HabitViewModel for each habit
            habitViewModels = [HabitViewModel(from: viewModel)]
        }
    }
} 