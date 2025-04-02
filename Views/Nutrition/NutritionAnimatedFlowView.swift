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
    
    // Initialize with detected labels
    init(viewModel: NutritionViewModel2, showView: Binding<Bool>, foodImage: UIImage, detectedLabels: [FoodLabelAnnotation]) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._showView = Binding(projectedValue: showView)
        self.foodImage = foodImage
        
        // Pre-populate with detected labels
        self._detectedLabels = State(initialValue: detectedLabels)
        
        // Set initial state for detected foods
        self._detectedFoods = State(initialValue: [])
        
        // Create image picker model with the provided image
        let imageModel = ImagePickerModel(image: foodImage)
        self._imageModel = StateObject(wrappedValue: imageModel)
    }
    
    // Convert detected labels to food items
    private func processFoodLabels() {
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
        
        self.detectedFoods = items
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
            if showFoods {
                VStack {
                    // Use our stub CameraPreviewHeaderView for the header
                    CameraPreviewHeaderView(closeAction: {
                        // Clean up the draft meal session when closing
                        viewModel.cancelMealLoggingSession()
                        showView = false
                    })
                    
                    Spacer()
                    
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
            
            // Loading overlay
            if showActivitySheet {
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
            showActivitySheet = true
            
            // Process food labels if we have none
            if detectedFoods.isEmpty {
                processFoodLabels()
                // Hide the activity sheet once processing is done
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showActivitySheet = false
                    // Show the food detection view
                    showFoods = true
                }
            } else {
                showActivitySheet = false
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
                // User has logged the meal, dismiss this view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Dismiss the view after a short delay to allow animation to complete
                    showView = false
                }
            }
        }
        .onDisappear {
            // Ensure we clean up if view disappears unexpectedly
            if viewModel.getCurrentDraftMeal() != nil {
                viewModel.cancelMealLoggingSession()
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


