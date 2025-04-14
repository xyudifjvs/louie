//
//  NutritionMonthlyDataView.swift
//  Louie
//
//  Created by Carson on 4/4/25.
//

import SwiftUI

struct NutritionMonthlyDataView: View {
    @Environment(\.dismiss) var dismiss
    
    // Initialize the ViewModel here for this view's scope
    // If it needs to share state with NutritionView beyond meals,
    // consider passing it down instead.
    @StateObject private var viewModel = NutritionViewModel2()
    
    // Calculate current week range once
    private var currentWeekRange: ClosedRange<Date>? {
        viewModel.weekDateRange(for: Date())
    }
    
    // Filter meals for the current week
    private var mealsThisWeek: [MealEntry] {
        guard let range = currentWeekRange else { return [] }
        return viewModel.meals(in: range)
    }
    
    var body: some View {
        ZStack {
            // Background gradient (matching NutritionView)
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            // Use a ScrollView to allow content to exceed screen height
            ScrollView {
                VStack(spacing: 20) {
                    // Section 1: This Week's Meals
                    if currentWeekRange != nil {
                        ThisWeeksMealsView(weeklyMeals: mealsThisWeek, viewModel: viewModel)
                            .frame(maxHeight: 300)
                    }
                    
                    // Section Separator (Optional)
                    Divider().background(Color.white.opacity(0.3)).padding(.horizontal)
                    
                    // Section 2: Monthly Goal Completion
                    MonthlyGoalCompletionView(viewModel: viewModel)
                    
                    Spacer() // Pushes content up if ScrollView is not full
                }
                .padding(.top) // Add padding at the top of the VStack
            }
            // Ensure ScrollView respects safe areas if needed, or ignore them
            // .edgesIgnoringSafeArea(.bottom) // Example if needed

            // Removed placeholder content and close button
        }
        .onAppear {
            // Fetch meals when the view appears to ensure data is loaded
            viewModel.fetchMeals()
        }
    }
}

// Preview Provider
struct NutritionMonthlyDataView_Previews: PreviewProvider {
    static var previews: some View {
        NutritionMonthlyDataView()
    }
}

// Helper extension (if not already defined elsewhere globally)
// Needed for Color(hexCode: ...)
// Consider moving this to a shared Utilities file if used widely

/* // Uncomment or ensure this exists elsewhere
extension Color {
    init(hexCode: String) {
        let scanner = Scanner(string: hexCode)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00ff00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000ff) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
*/

