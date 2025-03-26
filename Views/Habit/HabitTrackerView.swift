import SwiftUI

struct HabitTrackerView: View {
    @StateObject private var viewModel = HabitTrackerViewModel()
    @State private var showingAddHabitSheet = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "1e1e1e")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            HabitDashboardView(viewModel: viewModel)
        }
    }
} 