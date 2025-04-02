//
//  SmartListDetectionView.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI
import Foundation

// MARK: - Supporting Views for SmartListDetectionView

struct SmartListDetectionView: View {
    @ObservedObject var viewModel: NutritionViewModel2
    let foodImage: UIImage
    let detectedLabels: [FoodLabelAnnotation]
    @Binding var foodItems: [FoodItem]
    @Binding var showAddFood: Bool
    @Binding var showFoods: Bool
    
    // New state variables for the transformation
    @State private var showNutritionSummary = false
    @State private var nutritionScore: Int = 0
    @State private var totalMacros = MacroData()
    @State private var totalCalories: Int = 0
    
    // Improved animation system
    @State private var cardAnimationValues: [Double] = [0, 0, 0, 0]
    @State private var isContentSwapped: [Bool] = [false, false, false, false]
    
    // Macro type definition
    private enum MacroType {
        case calories, protein, carbs, fat
        
        var title: String {
            switch self {
            case .calories: return "Calories"
            case .protein: return "Protein"
            case .carbs: return "Carbs"
            case .fat: return "Fat"
            }
        }
        
        var icon: String {
            switch self {
            case .calories: return "flame.fill"
            case .protein: return "fish.fill"
            case .carbs: return "rectangle.grid.2x2.fill"
            case .fat: return "drop.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .calories: return Color(hexCode: "e63946")
            case .protein: return Color(hexCode: "2a6c8e")
            case .carbs: return Color(hexCode: "8e612a")
            case .fat: return Color(hexCode: "8e2a6c")
            }
        }
        
        var unit: String {
            switch self {
            case .calories: return "kcal"
            default: return "g"
            }
        }
    }
    
    // GeometryReader to get screen dimensions
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Top 50% - Image Card with optional score stamp
                    imageCard(height: geometry.size.height * 0.45)
                    
                    // Bottom 50% - Category Cards or Macro Cards in 2x2 Grid
                    categoryOrMacroGridSection(width: geometry.size.width)
                    
                    // Bottom Buttons - Action Buttons or Log Meal Button
                    bottomButtons
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Calculate totals on appear just in case
            calculateTotals()
        }
    }
    
    // MARK: - Image Card Section
    private func imageCard(height: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                // Image title
                Text("Your Meal")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                
                // Food image 
                Image(uiImage: foodImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height - 40) // Account for title and padding
                    .clipped()
                    .cornerRadius(16)
            }
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.2))
            )
            
            // Nutrition score stamp (conditionally shown)
            if showNutritionSummary {
                nutritionScoreStamp()
                    .offset(x: -16, y: 16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // Nutrition score stamp
    private func nutritionScoreStamp() -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hexCode: "2a6041"), Color(hexCode: "1a1a2e")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
            
            VStack(spacing: 0) {
                Text("\(nutritionScore)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Category/Macro Grid Section
    private func categoryOrMacroGridSection(width: CGFloat) -> some View {
        VStack(spacing: 12) {
            // First row
            HStack(spacing: 12) {
                if showNutritionSummary {
                    // Show macro cards when in summary mode
                    macroCard(type: .calories, value: Double(totalCalories), index: 0, width: width * 0.44)
                    macroCard(type: .protein, value: totalMacros.protein, index: 1, width: width * 0.44)
                } else {
                    // Show category cards in detection mode
                    categoryCard(for: .proteins, index: 0, width: width * 0.44)
                    categoryCard(for: .carbs, index: 1, width: width * 0.44)
                }
            }
            
            // Second row
            HStack(spacing: 12) {
                if showNutritionSummary {
                    // Show macro cards when in summary mode
                    macroCard(type: .carbs, value: totalMacros.carbs, index: 2, width: width * 0.44)
                    macroCard(type: .fat, value: totalMacros.fat, index: 3, width: width * 0.44)
                } else {
                    // Show category cards in detection mode
                    categoryCard(for: .vegetables, index: 2, width: width * 0.44)
                    categoryCard(for: .others, index: 3, width: width * 0.44)
                }
            }
        }
    }
    
    // MARK: - Individual Category Card
    private func categoryCard(for category: FoodCategory, index: Int, width: CGFloat) -> some View {
        let categoryItems = foodItems.filter { $0.category == category }
        let categoryInfo = getCategoryInfo(category)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Card header
            HStack {
                Image(systemName: categoryInfo.icon)
                    .foregroundColor(categoryInfo.color)
                
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Show items if available, otherwise a placeholder
            if categoryItems.isEmpty {
                Text("No items detected")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption)
                    .padding(.top, 4)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(categoryItems) { item in
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(Int(item.calories)) cal")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .frame(maxHeight: 80)
            }
        }
        .padding(12)
        .frame(width: width, height: width * 0.8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    categoryInfo.color.opacity(0.8),
                    categoryInfo.color.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .rotation3DEffect(
            .degrees(cardAnimationValues[index]),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.3
        )
    }
    
    // MARK: - Macro Nutrition Card
    private func macroCard(type: MacroType, value: Double, index: Int, width: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 8) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 28))
                .foregroundColor(type.color)
                .padding(.top, 4)
            
            // Title
            Text(type.title)
                .font(.headline)
                .foregroundColor(.white)
            
            // Value
            Text("\(type == .calories ? Int(value) : Int(value))")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // Unit
            Text(type.unit)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .frame(width: width, height: width * 0.8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    type.color.opacity(0.8),
                    type.color.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .rotation3DEffect(
            .degrees(cardAnimationValues[index]),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.3
        )
    }
    
    // Helper to get category UI info
    private func getCategoryInfo(_ category: FoodCategory) -> (icon: String, color: Color) {
        switch category {
        case .proteins:
            return ("fish", Color(hexCode: "2a6c8e"))
        case .carbs:
            return ("rectangle.grid.2x2", Color(hexCode: "8e612a"))
        case .vegetables:
            return ("leaf.fill", Color(hexCode: "2a8e38"))
        case .others:
            return ("drop.fill", Color(hexCode: "8e2a6c"))
        }
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        Group {
            if showNutritionSummary {
                logMealButton
            } else {
                actionButtons
            }
        }
        .transition(.opacity)
    }
    
    // Action buttons (Edit and Confirm)
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Edit button
            Button(action: {
                showAddFood = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Confirm button
            Button(action: {
                // Calculate nutrition data
                calculateTotals()
                
                // Start the card flip animations with improved timing
                animateCardsWithCoordinatedTiming()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Confirm")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hexCode: "2a6041"), Color(hexCode: "1a1a2e")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(foodItems.isEmpty)
            .opacity(foodItems.isEmpty ? 0.5 : 1.0)
        }
        .padding(.top, 10)
    }
    
    // Log meal button
    private var logMealButton: some View {
        Button(action: {
            // Here we save the meal to the database and dismiss
            logMealAndDismiss()
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Log Meal")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hexCode: "2a6041"), Color(hexCode: "1a1a2e")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Helper Methods
    
    // Calculate total macros and nutrition score
    private func calculateTotals() {
        // Initialize with zeros
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var calories: Int = 0
        
        // Sum up all food items
        for item in foodItems {
            protein += item.macros.protein
            carbs += item.macros.carbs
            fat += item.macros.fat
            calories += item.calories
        }
        
        // Store the results
        totalMacros = MacroData(protein: protein, carbs: carbs, fat: fat)
        totalCalories = calories
        
        // Calculate nutrition score
        calculateNutritionScore()
    }
    
    // Calculate the nutrition score
    private func calculateNutritionScore() {
        // Baseline score
        var score = 70
        
        // If we have no food items, default to 0
        if foodItems.isEmpty {
            nutritionScore = 0
            return
        }
        
        // Check for balance of food groups
        let hasProteins = foodItems.contains { $0.category == .proteins }
        let hasVegetables = foodItems.contains { $0.category == .vegetables }
        let hasCarbs = foodItems.contains { $0.category == .carbs }
        
        // Add points for balanced meal
        if hasProteins { score += 10 }
        if hasVegetables { score += 15 }
        if hasCarbs { score += 5 }
        
        // Check macro balance (40/30/30 protein/carbs/fat is ideal)
        if totalCalories > 0 {
            let totalGrams = totalMacros.protein + totalMacros.carbs + totalMacros.fat
            if totalGrams > 0 {
                let proteinRatio = totalMacros.protein / totalGrams
                let carbsRatio = totalMacros.carbs / totalGrams
                let fatRatio = totalMacros.fat / totalGrams
                
                // Ideal ratios
                let idealProtein = 0.3
                let idealCarbs = 0.4
                let idealFat = 0.3
                
                // Calculate deviation from ideal (0 is perfect)
                let proteinDev = abs(proteinRatio - idealProtein)
                let carbsDev = abs(carbsRatio - idealCarbs)
                let fatDev = abs(fatRatio - idealFat)
                
                // Average deviation (0 to 1 scale)
                let avgDev = (proteinDev + carbsDev + fatDev) / 3
                
                // Adjust score based on deviation (0 deviation adds 15 points)
                score -= Int(avgDev * 30)
            }
        }
        
        // Ensure score is in valid range
        nutritionScore = max(0, min(100, score))
    }
    
    // Improved animation with coordinated timing
    private func animateCardsWithCoordinatedTiming() {
        // Reset animation values
        cardAnimationValues = [0, 0, 0, 0]
        
        // Set showNutritionSummary to false initially if needed
        if showNutritionSummary {
            showNutritionSummary = false
        }
        
        // Define base duration and delay
        let baseDuration: Double = 0.3
        let baseDelay: Double = 0.15
        
        // First update the state to swap content
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDuration) {
            withAnimation(.easeInOut(duration: 0.1)) {
                // Flip to nutrition summary mode
                showNutritionSummary = true
            }
        }
        
        // Animate first row of cards (0 and 1)
        withAnimation(Animation.easeInOut(duration: baseDuration)) {
            // Only rotate to 90 degrees for the first half of the animation
            cardAnimationValues[0] = 90
            cardAnimationValues[1] = 90
        }
        
        // Complete first row rotation after state change
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDuration + 0.15) {
            withAnimation(Animation.easeInOut(duration: baseDuration)) {
                // Rotate back to 0 to avoid mirror effect
                cardAnimationValues[0] = 0
                cardAnimationValues[1] = 0
            }
        }
        
        // Animate second row with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay) {
            withAnimation(Animation.easeInOut(duration: baseDuration)) {
                cardAnimationValues[2] = 90
                cardAnimationValues[3] = 90
            }
            
            // Complete second row rotation after state change
            DispatchQueue.main.asyncAfter(deadline: .now() + baseDuration + 0.15) {
                withAnimation(Animation.easeInOut(duration: baseDuration)) {
                    // Rotate back to 0 to avoid mirror effect
                    cardAnimationValues[2] = 0
                    cardAnimationValues[3] = 0
                }
            }
        }
    }
    
    // Log the meal and dismiss
    private func logMealAndDismiss() {
        // Update the draft meal with the currently selected food items
        viewModel.updateDraftMeal(foods: foodItems)
        
        // Get the updated draft meal for confirmation
        if let draftMeal = viewModel.getCurrentDraftMeal() {
            // Finalize and save the meal
            viewModel.finalizeDraftMeal()
            
            // Signal to parent view that we're done by setting showFoods to false
            showFoods = false
        } else {
            print("⚠️ No draft meal found to log")
        }
    }
}

// MARK: - Supporting Views

struct FoodCategoryView: View {
    let category: FoodCategory
    let items: [FoodItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(items) { item in
                HStack {
                    Text(item.name)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(item.servingAmount))g")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
}

// MARK: - Supporting Views

// Category Section
struct CategorySection: View {
    let categoryName: String
    let foodItems: [FoodItem]
    let onDelete: (FoodItem) -> Void
    
    private var categoryIcon: String {
        switch categoryName {
        case "Proteins":
            return "drumstick.fill"
        case "Vegetables":
            return "leaf.fill"
        case "Carbs":
            return "rectangle.grid.2x2.fill"
        default:
            return "circle.hexagongrid.fill"
        }
    }
    
    private var categoryColor: Color {
        switch categoryName {
        case "Proteins":
            return .blue
        case "Vegetables":
            return .green
        case "Carbs":
            return .orange
        default:
            return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category header
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                
                Text(categoryName)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)
            
            // Food items
            ForEach(foodItems) { item in
                FoodItemRow(item: item, onDelete: onDelete)
                    .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

// Food Item Row
struct FoodItemRow: View {
    let item: FoodItem
    let onDelete: (FoodItem) -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    var body: some View {
        ZStack {
            // Delete background
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        self.onDelete(item)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .frame(width: 60, height: 40)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            
            // Food item
            HStack {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(item.amount)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(item.calories) cal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hexCode: "1a1a2e").opacity(0.8), Color(hexCode: "2a6041").opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(8)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            self.offset = value.translation.width
                            self.isSwiping = true
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -50 {
                            // Delete threshold reached
                            withAnimation {
                                self.offset = -60
                            }
                        } else {
                            // Reset position
                            withAnimation {
                                self.offset = 0
                                self.isSwiping = false
                            }
                        }
                    }
            )
        }
    }
}

