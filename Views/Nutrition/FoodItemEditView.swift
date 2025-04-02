//
//  FoodItemEditView.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//

import SwiftUI

struct FoodItemEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel = NutritionViewModel2()
    @State private var foodItems: [FoodItem]
    @State private var showAddFoodPopup = false
    let meal: MealEntry?
    let image: UIImage
    var onSave: (([FoodItem]) -> Void)?
    
    init(viewModel: NutritionViewModel2, foodItems: [FoodItem], meal: MealEntry? = nil, image: UIImage, onSave: (([FoodItem]) -> Void)? = nil) {
        self.viewModel = viewModel
        self._foodItems = State(initialValue: foodItems)
        self.meal = meal
        self.image = image
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Edit Items")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showAddFoodPopup = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Meal image thumbnail
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
                    .padding(.vertical)
                
                // Content area
                ScrollView {
                    VStack(spacing: 12) {
                        // Food items list with swipeable cards
                        if foodItems.isEmpty {
                            // Empty state
                            VStack(spacing: 20) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("No food items detected")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Tap + to add food items")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                        } else {
                            ForEach(foodItems.indices, id: \.self) { index in
                                FoodItemCard(
                                    id: foodItems[index].id,
                                    item: foodItems[index],
                                    onDelete: {
                                        foodItems.remove(at: index)
                                    },
                                    onUpdate: { newSize, servingMultiplier in
                                        // Update the serving size text
                                        foodItems[index].amount = newSize
                                        
                                        // Calculate the current multiplier from the existing serving text
                                        let currentMultiplier: Int
                                        if foodItems[index].amount.contains("2") {
                                            currentMultiplier = 2
                                        } else if foodItems[index].amount.contains("3") {
                                            currentMultiplier = 3
                                        } else {
                                            currentMultiplier = 1
                                        }
                                        
                                        // Only update nutrition values if the multiplier changed
                                        if currentMultiplier != servingMultiplier {
                                            // Calculate base values for a single serving
                                            let baseCalories = foodItems[index].calories / currentMultiplier
                                            let baseProtein = foodItems[index].macros.protein / Double(currentMultiplier)
                                            let baseCarbs = foodItems[index].macros.carbs / Double(currentMultiplier)
                                            let baseFat = foodItems[index].macros.fat / Double(currentMultiplier)
                                            
                                            // Now update with the new multiplier
                                            foodItems[index].calories = baseCalories * servingMultiplier
                                            foodItems[index].macros.protein = baseProtein * Double(servingMultiplier)
                                            foodItems[index].macros.carbs = baseCarbs * Double(servingMultiplier)
                                            foodItems[index].macros.fat = baseFat * Double(servingMultiplier)
                                            foodItems[index].servingAmount = 100.0 * Double(servingMultiplier)
                                        }
                                    }
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Confirm button
                Button(action: {
                    // Save changes and return to previous screen
                    saveMeal()
                }) {
                    Text("Confirm")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hexCode: "2a6041"), Color(hexCode: "1a1a2e")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
        }
        .sheet(isPresented: $showAddFoodPopup) {
            AddFoodItemView(foodItems: $foodItems)
        }
    }
    
    private func saveMeal() {
        // Pass updated food items back to parent view
        onSave?(foodItems)
        
        // Calculate nutrition score
        let nutritionScore = viewModel.calculateNutritionScore(foods: foodItems)
        
        // Calculate total macros
        let totalMacros = foodItems.reduce(MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)) { result, food in
            return MacroData(
                protein: result.protein + food.macros.protein,
                carbs: result.carbs + food.macros.carbs,
                fat: result.fat + food.macros.fat,
                fiber: result.fiber + food.macros.fiber,
                sugar: result.sugar + food.macros.sugar
            )
        }
        
        // Create image data
        let imageData = image.jpegData(compressionQuality: 0.7)
        
        // Create or update meal entry
        if var existingMeal = meal {
            // Update existing meal
            existingMeal.foods = foodItems
            existingMeal.nutritionScore = nutritionScore
            existingMeal.macronutrients = totalMacros
            existingMeal.isManuallyAdjusted = true
            viewModel.saveMeal(existingMeal)
        } else {
            // Create new meal
            let newMeal = MealEntry(
                timestamp: Date(),
                imageData: imageData,
                imageURL: nil,
                foods: foodItems,
                nutritionScore: nutritionScore,
                macronutrients: totalMacros,
                micronutrients: MicroData(),
                userNotes: nil,
                isManuallyAdjusted: true
            )
            viewModel.saveMeal(newMeal)
        }
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Food Item Card with Swipe to Delete
struct FoodItemCard: View {
    let id: UUID
    let item: FoodItem
    let onDelete: () -> Void
    let onUpdate: (String, Int) -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    @State private var isExpanded = false
    @State private var selectedServingIndex = 0
    
    private let servingOptions = ["1 serving", "2 servings", "3 servings"]
    
    init(id: UUID, item: FoodItem, onDelete: @escaping () -> Void, onUpdate: @escaping (String, Int) -> Void) {
        self.id = id
        self.item = item
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        
        // Set initial serving index based on item's current amount
        let initialIndex = servingOptions.firstIndex(of: item.amount) ?? 0
        _selectedServingIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Delete background
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .frame(width: 60, height: 40)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .opacity(0.9)
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
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hexCode: "2a6041").opacity(0.95), Color(hexCode: "1a1a2e").opacity(0.95)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isExpanded && value.translation.width < 0 {
                                self.offset = value.translation.width
                                self.isSwiping = true
                            }
                        }
                        .onEnded { value in
                            if !isExpanded && value.translation.width < -50 {
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
                .onTapGesture {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }
            }
            
            // Expanded serving size selector
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Serving Size")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 10)
                    
                    Picker("Serving Size", selection: $selectedServingIndex) {
                        ForEach(0..<servingOptions.count, id: \.self) { index in
                            Text(servingOptions[index]).foregroundColor(.white)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedServingIndex) { newValue in
                        // Update item's amount when selection changes
                        updateItemServingSize(to: servingOptions[newValue])
                    }
                    .padding(.bottom, 15)
                }
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hexCode: "2a6041").opacity(0.6), Color(hexCode: "1a1a2e").opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func updateItemServingSize(to newSize: String) {
        // Calculate serving multiplier (1, 2, or 3)
        let servingMultiplier = selectedServingIndex + 1
        
        // Call the onUpdate callback with both the new size text and multiplier
        onUpdate(newSize, servingMultiplier)
    }
}

// Preview provider
struct FoodItemEditView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample food items for preview
        let sampleItems: [FoodItem] = [
            FoodItem(
                name: "Chicken Breast",
                amount: "1 serving",
                servingAmount: 100,
                calories: 165,
                category: .proteins,
                macros: MacroData(protein: 31, carbs: 0, fat: 3.6)
            ),
            FoodItem(
                name: "Brown Rice",
                amount: "1 serving",
                servingAmount: 100,
                calories: 112,
                category: .carbs,
                macros: MacroData(protein: 2.6, carbs: 23, fat: 0.9)
            )
        ]
        
        return FoodItemEditView(
            viewModel: NutritionViewModel2(),
            foodItems: sampleItems,
            meal: nil,
            image: UIImage(systemName: "photo")!,
            onSave: { _ in }
        )
        .preferredColorScheme(.dark)
    }
}

