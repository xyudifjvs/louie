//
//  ThisWeeksMealsView.swift
//  Louie
//
//  Created by Carson on 4/4/25.
//

import SwiftUI

struct ThisWeeksMealsView: View {
    let weeklyMeals: [MealEntry]
    @ObservedObject var viewModel: NutritionViewModel2 // Use ObservedObject since VM is passed in
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("This Week's Meals")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.bottom, 5)
            
            // Extracted conditional content view
            mealsListOrEmptyView
        }
        .padding(.vertical) // Padding around the whole section
    }
    
    // MARK: - Subviews
    
    // Computed property for the main content (list or empty state)
    private var mealsListOrEmptyView: some View {
        Group { // Use Group to return conditional content
            if weeklyMeals.isEmpty {
                Text("No meals logged this week yet.")
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    // Apply height constraint to empty view too for consistency
                    .frame(maxHeight: 300) 
            } else {
                // Reverting to ScrollView + LazyVStack for reliable rendering
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) { // LazyVStack for performance
                        ForEach(weeklyMeals) { meal in
                            VStack(alignment: .leading, spacing: 0) {
                                MealCardView(meal: meal, dateDisplayMode: DateDisplayMode.dayOfWeek)
                                    .environmentObject(viewModel) // Pass VM to MealCardView
                                    .onTapGesture {
                                        viewModel.toggleMealExpansion(mealId: meal.id)
                                    }
                                
                                // Conditionally show Macro Detail View
                                if viewModel.expandedMealId == meal.id {
                                    MealMacroDataView(macros: meal.macronutrients)
                                        .padding(.top, 8)
                                        .padding(.horizontal) // Add horizontal padding back
                                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                                        .zIndex(-1)
                                }
                            }
                            // Removed non-functional swipeActions for ScrollView context
                            /*
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteMeal(meal)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            */
                            .padding(.bottom, 8) // Space between meal cards
                        }
                    }
                    .padding(.horizontal) // Padding for the overall stack
                }
                 // Re-apply height limit to the ScrollView
                .frame(maxHeight: 300)
            }
        }
    }
}

// Preview Provider
struct ThisWeeksMealsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NutritionViewModel2()
        // Add some sample meals for preview
        // (Need to create MealEntry instances)
        
        ScrollView { // Wrap in ScrollView for realistic preview
            ThisWeeksMealsView(weeklyMeals: [], viewModel: viewModel)
        }
        .background(Color.black) // Use dark background for preview
    }
}

