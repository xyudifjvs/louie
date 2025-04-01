//
//  NutritionAnimatedFlowView.swift
//  Louie
//
//  Created by Carson on 3/30/25.
//

import SwiftUI
import Foundation

// MARK: - Main Flow View
struct NutritionAnimatedFlowView: View {
    @StateObject private var viewModel = NutritionViewModel2()
    @State private var foodItems: [FoodItem] = []
    @State private var showAddFood = false
    @State private var showFoods = false
    @State private var selectedTab = 0
    
    let foodImage: UIImage
    let detectedLabels: [FoodLabelAnnotation]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Main content
            if selectedTab == 0 {
                // Food detection view
                SmartListDetectionView(
                    foodImage: foodImage,
                    detectedLabels: detectedLabels,
                    foodItems: $foodItems,
                    showAddFood: $showAddFood,
                    showFoods: $showFoods
                )
                .transition(.opacity)
            } else {
                // Nutrition score view
                EnhancedNutritionScoreView(
                    foodImage: foodImage,
                    foodItems: foodItems,
                    viewModel: viewModel
                )
                .transition(.opacity)
            }
        }
        .onChange(of: showFoods) { newValue in
            if newValue {
                withAnimation {
                    selectedTab = 1
                    showFoods = false
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodItemView(foodItems: $foodItems)
        }
    }
}

// MARK: - Preview
struct NutritionAnimatedFlowView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock data for preview
        let mockLabels = [
            FoodLabelAnnotation(description: "Chicken breast", confidence: 0.95),
            FoodLabelAnnotation(description: "Broccoli", confidence: 0.90),
            FoodLabelAnnotation(description: "White rice", confidence: 0.85)
        ]
        
        return NutritionAnimatedFlowView(
            foodImage: UIImage(systemName: "photo")!,
            detectedLabels: mockLabels
        )
    }
}

