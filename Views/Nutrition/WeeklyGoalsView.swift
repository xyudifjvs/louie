//
//  WeeklyGoalsView.swift
//  Louie
//
//  Created by Carson on 4/2/25.
//

import SwiftUI

struct WeeklyGoalsView: View {
    @Binding var goals: NutritionGoals
    @State private var showGoalsEditor = false
    @State private var viewKey = UUID() // For forcing view refresh
    @ObservedObject var viewModel: NutritionViewModel2
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title and edit button
            HStack {
                Text("Weekly Goals")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showGoalsEditor = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Progress rings
            VStack(spacing: 20) {
                // Top row: Calories and Protein
                HStack(spacing: 30) {
                    // Calories ring
                    MacroRingView(
                        value: Double(goals.caloriesProgress),
                        maxValue: Double(goals.caloriesGoal),
                        ringWidth: 10,
                        title: "Calories",
                        color: .red,
                        unitText: "kcal"
                    )
                    .frame(width: 100, height: 100)
                    .id("calories-\(viewKey)")
                    
                    // Protein ring
                    MacroRingView(
                        value: goals.proteinProgress,
                        maxValue: goals.proteinGoal,
                        ringWidth: 10,
                        title: "Protein",
                        color: .blue,
                        unitText: "g"
                    )
                    .frame(width: 100, height: 100)
                    .id("protein-\(viewKey)")
                }
                
                // Bottom row: Carbs and Fat
                HStack(spacing: 30) {
                    // Carbs ring
                    MacroRingView(
                        value: goals.carbsProgress,
                        maxValue: goals.carbsGoal,
                        ringWidth: 10,
                        title: "Carbs",
                        color: .green,
                        unitText: "g"
                    )
                    .frame(width: 100, height: 100)
                    .id("carbs-\(viewKey)")
                    
                    // Fat ring
                    MacroRingView(
                        value: goals.fatProgress,
                        maxValue: goals.fatGoal,
                        ringWidth: 10,
                        title: "Fat",
                        color: Color(hexCode: "FF9500"), // Orange
                        unitText: "g"
                    )
                    .frame(width: 100, height: 100)
                    .id("fat-\(viewKey)")
                }
                
                // Add more spacing at the bottom for padding
                Spacer()
                    .frame(height: 10)
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
        .padding(.horizontal)
        .sheet(isPresented: $showGoalsEditor, onDismiss: {
            // Force view to refresh when sheet is dismissed
            viewKey = UUID()
        }) {
            GoalsEditorView(goals: $goals, isPresented: $showGoalsEditor, viewModel: viewModel)
        }
    }
}

struct WeeklyGoalsView_Previews: PreviewProvider {
    @State static var previewGoals = NutritionGoals(
        caloriesGoal: 2200,
        proteinGoal: 160,
        carbsGoal: 220,
        fatGoal: 70,
        caloriesProgress: 1540,
        proteinProgress: 90,
        carbsProgress: 120,
        fatProgress: 55
    )
    
    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            
            WeeklyGoalsView(goals: $previewGoals, viewModel: NutritionViewModel2())
        }
    }
}

