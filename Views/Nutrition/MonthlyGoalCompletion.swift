//
//  MonthlyGoalCompletion.swift
//  Louie
//
//  Created by Carson on 4/4/25.
//

import SwiftUI

struct MonthlyGoalCompletionView: View {
    @ObservedObject var viewModel: NutritionViewModel2
    
    // State to track the currently displayed month
    @State private var displayedDate = Date()
    
    // Generate a range of dates for past/future months for TabView
    private var monthRange: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        // Example: Go back 12 months and forward 1 month from today
        for i in stride(from: -12, through: 1, by: 1) {
            if let date = calendar.date(byAdding: .month, value: i, to: Date()) {
                dates.append(startOfMonth(date))
            }
        }
        return dates.sorted()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Goal Completion")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding([.horizontal, .bottom])
            
            TabView(selection: $displayedDate) {
                ForEach(monthRange, id: \.self) { monthStartDate in
                    MonthDetailView(monthDate: monthStartDate, viewModel: viewModel)
                        .frame(height: 300) // Give content view a defined height
                        .tag(monthStartDate) // Tag for TabView selection
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 310) // Re-add height to TabView, ensuring it fits content
            
            // Set initial displayed month to the start of the current month
            .onAppear {
                 self.displayedDate = startOfMonth(Date())
            }
        }
        .padding(.vertical)
    }
    
    // Helper to get the start of the month for consistent tagging/selection
    private func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

// Subview to display rings for a single month
struct MonthDetailView: View {
    let monthDate: Date
    @ObservedObject var viewModel: NutritionViewModel2
    
    // Get the weekly goals (needed for monthly target)
    private var goals: NutritionGoals {
        viewModel.nutritionGoals
    }
    
    // Calculate consumed totals for the month
    private var consumedTotals: MonthlyConsumedMacros {
        viewModel.getMonthlyConsumedTotals(for: monthDate)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text(monthDate, formatter: viewModel.monthYearFormatter)
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                // Pass consumed totals and goals down
                GoalRingColumn(label: "Calories", 
                               consumed: Double(consumedTotals.totalCalories), 
                               goal: Double(goals.caloriesGoal * 4), 
                               color: .red, 
                               unit: "cal",
                               icon: "🔥")
                               
                GoalRingColumn(label: "Protein", 
                               consumed: consumedTotals.totalProtein, 
                               goal: goals.proteinGoal * 4, 
                               color: .blue, 
                               unit: "g", 
                               icon: "💪")
                               
                GoalRingColumn(label: "Carbs", 
                               consumed: consumedTotals.totalCarbs, 
                               goal: goals.carbsGoal * 4, 
                               color: .green, 
                               unit: "g", 
                               icon: "🍞")
                               
                GoalRingColumn(label: "Fat", 
                               consumed: consumedTotals.totalFat, 
                               goal: goals.fatGoal * 4, 
                               color: Color(hexCode: "FF9500"), // Orange 
                               unit: "g", 
                               icon: "🥑")
            }
            .padding(.horizontal)
        }
        // Apply the frame height here to the content VStack
        .frame(height: 300) 
    }
}

// Subview for a single ring and its label
struct GoalRingColumn: View {
    let label: String
    let consumed: Double
    let goal: Double
    let color: Color
    let unit: String
    let icon: String // Keep icon for potential future use or overlay
    
    // Calculate progress safely
    private var progress: Double {
        guard goal > 0 else { return 0 } // Avoid division by zero
        return min(consumed / goal, 1.0) // Cap progress at 1.0 (100%)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Use MacroRingView for continuous progress
            MacroRingView(value: consumed, 
                          maxValue: goal, 
                          title: label, // Pass label to MacroRingView's title
                          color: color, 
                          unitText: unit) // Pass unit
                .frame(width: 100, height: 100) // Increase size slightly more
            
            // Remove label below, as it's shown inside MacroRingView now
            /*
             Text(label)
                 .font(.caption)
                 .foregroundColor(.white.opacity(0.8))
            */
        }
    }
}

// Preview Provider
struct MonthlyGoalCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyGoalCompletionView(viewModel: NutritionViewModel2())
            .background(Color.black)
    }
}

