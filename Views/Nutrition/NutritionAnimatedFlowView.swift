//
//  NutritionAnimatedFlowView.swift
//  Louie
//
//  Created by Carson on 3/30/25.
//

import SwiftUI
import Foundation

// MARK: - Stub Implementations to Fix Missing Types

// Simple image picker model that just stores an image
fileprivate class ImagePickerModel: ObservableObject {
    @Published var selectedImage: UIImage?
    
    init(image: UIImage? = nil) {
        self.selectedImage = image
    }
}

// Stub implementation of vision service
fileprivate class GoogleCloudVisionService {}

// Stub implementation of nutrition service
fileprivate class NutritionixService {}

// Simple header view with close button
fileprivate struct CameraPreviewHeaderView: View {
    let closeAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: closeAction) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
            Spacer()
        }
    }
}

// MARK: - Main Flow View
struct NutritionAnimatedFlowView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var imageModel = ImagePickerModel()
    @ObservedObject var viewModel: NutritionViewModel2
    
    @Binding var showView: Bool
    
    @State private var showAddFood = false
    @State private var showFoods = false
    @State private var showActivitySheet = false
    @State private var detectedLabels: [FoodLabelAnnotation] = []
    @State private var detectedFoods: [FoodItem] = []
    
    let foodImage: UIImage
    let mealEntry: MealEntry? // Add optional MealEntry parameter
    
    // Initialize with detected labels and optional MealEntry
    init(viewModel: NutritionViewModel2, showView: Binding<Bool>, foodImage: UIImage, detectedLabels: [FoodLabelAnnotation], mealEntry: MealEntry? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._showView = Binding(projectedValue: showView)
        self.foodImage = foodImage
        self.mealEntry = mealEntry
        
        // Debug: Print whether mealEntry was received
        print("INITIALIZER DEBUG:")
        print("  - MealEntry is \(mealEntry != nil ? "received" : "NIL")")
        if let entry = mealEntry {
            print("  - MealEntry ID: \(entry.id)")
            print("  - MealEntry has \(entry.foods.count) foods")
            for (index, food) in entry.foods.enumerated() {
                print("    \(index+1). \(food.name) (Category: \(food.category.rawValue))")
            }
        }
        
        // Pre-populate with detected labels
        self._detectedLabels = State(initialValue: detectedLabels)
        
        // Debug: Print whether mealEntry was received
        print("NutritionAnimatedFlowView init: mealEntry is \(mealEntry != nil ? "received with \(mealEntry!.foods.count) foods" : "NIL")")
        
        // Set initial state for detected foods
        // If we have a meal entry with foods, use those directly
        if let entry = mealEntry, !entry.foods.isEmpty {
            print("NutritionAnimatedFlowView init: Using \(entry.foods.count) foods from MealEntry")
            for food in entry.foods {
                print("   - \(food.name) (Category: \(food.category.rawValue))")
            }
            self._detectedFoods = State(initialValue: entry.foods)
            print("AFTER INIT: detectedFoods initialized with \(entry.foods.count) items")
        } else {
            self._detectedFoods = State(initialValue: [])
            print("AFTER INIT: detectedFoods initialized with 0 items (empty array)")
        }
        
        // Create image picker model with the provided image
        let imageModel = ImagePickerModel(image: foodImage)
        self._imageModel = StateObject(wrappedValue: imageModel)
    }
    
    // Convert detected labels to food items
    private func processFoodLabels() {
        // If we already have food items from a MealEntry, don't create fallbacks
        if !detectedFoods.isEmpty {
            print("Using \(detectedFoods.count) foods from MealEntry")
            return
        }
        
        // Create fallback food items
        createFallbackFoodItems(from: self.detectedLabels)
    }
    
    // Create fallback food items from the labels
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
        
        print("BEFORE setting detectedFoods: \(self.detectedFoods.count) items")
        self.detectedFoods = items
        print("AFTER setting detectedFoods: \(self.detectedFoods.count) items")
        print("Food items created:")
        for item in items {
            print("- \(item.name) (Category: \(item.category.rawValue), Calories: \(item.calories))")
        }
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
            
            // Main content - always show detection view without conditional
            VStack {
                // Use our stub CameraPreviewHeaderView for the header
                CameraPreviewHeaderView(closeAction: {
                    showView = false
                })
                
                Spacer()
                
                // Debug: Print food count before passing to SmartListDetectionView
                Text("DEBUG: \(detectedFoods.count) foods available")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.top, -20)
                
                // Main detection view
                SmartListDetectionView(
                    viewModel: viewModel,
                    foodImage: imageModel.selectedImage ?? foodImage,
                    detectedLabels: detectedLabels,
                    foodItems: $detectedFoods,
                    showAddFood: $showAddFood,
                    showFoods: $showFoods
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Debug: Print food count on appearance
            print("NutritionAnimatedFlowView onAppear: detectedFoods count = \(detectedFoods.count)")
            if let entry = mealEntry {
                print("NutritionAnimatedFlowView onAppear: mealEntry has \(entry.foods.count) foods")
            }
            
            // Process food labels immediately without showing loading
            if detectedFoods.isEmpty {
                print("NutritionAnimatedFlowView onAppear: No food items, creating fallbacks")
                processFoodLabels()
                // Set showFoods to true immediately
                showFoods = true
            } else {
                print("NutritionAnimatedFlowView onAppear: Using existing \(detectedFoods.count) foods")
                showFoods = true
            }
        }
        .sheet(isPresented: $showAddFood) {
            FoodItemEditView(
                viewModel: viewModel,
                foodItems: Array(detectedFoods),
                meal: nil,
                image: foodImage,
                onSave: { updatedFoods in
                    // Update detectedFoods with the edited food items
                    detectedFoods = updatedFoods
                }
            )
        }
        .onChange(of: showFoods) { newValue in
            if !newValue {
                // User has logged the meal, dismiss this view immediately
                presentationMode.wrappedValue.dismiss()
                showView = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DismissAllMealViews"))) { _ in
            // First, update all state variables to prevent view reappearance
            showFoods = false
            showView = false
            
            // Then dismiss with a slight delay to ensure state updates are processed
            DispatchQueue.main.async {
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
            viewModel: NutritionViewModel2(),
            showView: .constant(true),
            foodImage: UIImage(systemName: "photo")!,
            detectedLabels: mockLabels
        )
    }
}


