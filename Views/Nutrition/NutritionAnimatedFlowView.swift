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
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = NutritionViewModel2()
    @State private var foodItems: [FoodItem] = []
    @State private var showAddFood = false
    @State private var showFoods = false
    @State private var isProcessing = false
    
    let foodImage: UIImage
    let detectedLabels: [FoodLabelAnnotation]
    
    // Initialize and convert detected labels to FoodItems
    init(foodImage: UIImage, detectedLabels: [FoodLabelAnnotation]) {
        self.foodImage = foodImage
        self.detectedLabels = detectedLabels
        
        // Pre-populate with default empty arrays
        _foodItems = State(initialValue: [])
        
        // Convert FoodLabelAnnotation to FoodItems immediately
        processFoodLabels()
    }
    
    // Process detected labels into FoodItems
    private func processFoodLabels() {
        // Convert FoodLabelAnnotation to LabelAnnotation for the service
        let labelAnnotations = detectedLabels.map { label -> LabelAnnotation in
            return LabelAnnotation(
                description: label.description,
                score: Float(label.confidence),
                topicality: Float(label.confidence)
            )
        }
        
        // Use NutritionService to get FoodItems
        NutritionService.shared.getNutritionInfo(for: labelAnnotations) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    // Assign the food items
                    self.foodItems = items
                    print("Successfully processed \(items.count) food items")
                    
                    // Log the processed items for debugging
                    for item in items {
                        print("Food item: \(item.name), Category: \(item.category.rawValue), Calories: \(item.calories)")
                    }
                    
                case .failure(let error):
                    print("Failed to process food labels: \(error.description)")
                    
                    // Create dummy items from labels as fallback
                    createFallbackFoodItems(from: self.detectedLabels)
                }
                
                isProcessing = false
            }
        }
    }
    
    // Create fallback food items if the API fails
    private func createFallbackFoodItems(from labels: [FoodLabelAnnotation]) {
        var items: [FoodItem] = []
        
        for label in labels.prefix(4) {
            // Determine the best category based on the food name
            let category = determineFoodCategory(name: label.description)
            
            // Create a default FoodItem
            let foodItem = FoodItem(
                name: label.description,
                amount: "1 serving",
                servingAmount: 100,
                calories: Int.random(in: 100...500),  // Random calories since we don't have real data
                category: category,
                macros: MacroData(protein: Double.random(in: 5...25), carbs: Double.random(in: 10...50), fat: Double.random(in: 3...20))
            )
            
            items.append(foodItem)
        }
        
        self.foodItems = items
        print("Created \(items.count) fallback food items")
    }
    
    // Helper function to guess food category based on name
    private func determineFoodCategory(name: String) -> FoodCategory {
        let lowercaseName = name.lowercased()
        
        // Check for proteins
        if lowercaseName.contains("chicken") || lowercaseName.contains("beef") || 
           lowercaseName.contains("fish") || lowercaseName.contains("meat") || 
           lowercaseName.contains("egg") || lowercaseName.contains("protein") ||
           lowercaseName.contains("tofu") {
            return .proteins
        }
        
        // Check for vegetables
        if lowercaseName.contains("vegetable") || lowercaseName.contains("salad") || 
           lowercaseName.contains("lettuce") || lowercaseName.contains("spinach") || 
           lowercaseName.contains("broccoli") || lowercaseName.contains("carrot") ||
           lowercaseName.contains("tomato") {
            return .vegetables
        }
        
        // Check for carbs
        if lowercaseName.contains("bread") || lowercaseName.contains("rice") || 
           lowercaseName.contains("pasta") || lowercaseName.contains("potato") || 
           lowercaseName.contains("fries") || lowercaseName.contains("bun") ||
           lowercaseName.contains("cereal") {
            return .carbs
        }
        
        // Default to others
        return .others
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Main content - single view that handles both detection and summary
            SmartListDetectionView(
                foodImage: foodImage,
                detectedLabels: detectedLabels,
                foodItems: $foodItems,
                showAddFood: $showAddFood,
                showFoods: $showFoods
            )
            
            // Loading overlay
            if isProcessing {
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            Text("Processing food items...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                        }
                    )
            }
        }
        .onAppear {
            // Set processing flag when view appears
            isProcessing = true
            
            // Process food labels if we have none
            if foodItems.isEmpty {
                processFoodLabels()
            } else {
                isProcessing = false
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodItemView(foodItems: $foodItems)
        }
        .onChange(of: showFoods) { newValue in
            if newValue {
                // User has logged the meal, dismiss this view
                presentationMode.wrappedValue.dismiss()
            }
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


