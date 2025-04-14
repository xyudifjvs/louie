import SwiftUI

struct HabitCalendarView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var selectedMonth = Date()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hexCode: "121212"), Color(hexCode: "1e1e1e")]),
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
                            // Directly create HabitProgressCard. It gets the viewModel via @EnvironmentObject
                            HabitProgressCard(
                                habit: habit,
                                selectedMonth: selectedMonth
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Habit Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Habit Calendar")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .environmentObject(viewModel)
    }
} 