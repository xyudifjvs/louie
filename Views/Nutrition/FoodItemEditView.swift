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
    let meal: MealEntry?
    let image: UIImage
    
    init(viewModel: NutritionViewModel2, foodItems: [FoodItem], meal: MealEntry? = nil, image: UIImage) {
        self.viewModel = viewModel
        self._foodItems = State(initialValue: foodItems)
        self.meal = meal
        self.image = image
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
                    
                    Text("Edit Foods")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        saveMeal()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Meal image thumbnail
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .padding(.vertical)
                
                // Food items list
                List {
                    ForEach(0..<foodItems.count, id: \.self) { index in
                        VStack(alignment: .leading) {
                            HStack {
                                TextField("Food name", text: $foodItems[index].name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    // Update calorie value
                                    let newCalories = Int.random(in: 50...500)
                                    foodItems[index].calories = newCalories
                                }) {
                                    HStack {
                                        Text("\(foodItems[index].calories) cal")
                                        Image(systemName: "arrow.2.circlepath")
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                            
                            // Serving size
                            TextField("Serving size", text: $foodItems[index].amount)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteItem)
                    
                    Button(action: {
                        addFoodItem()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Food Item")
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    private func deleteItem(at offsets: IndexSet) {
        foodItems.remove(atOffsets: offsets)
    }
    
    private func addFoodItem() {
        // Add a new empty food item
        let newItem = FoodItem(
            name: "New Food Item",
            amount: "1 serving",
            servingAmount: 100,
            calories: 100,
            category: .others,
            macros: MacroData(
                protein: 5,
                carbs: 10,
                fat: 5,
                fiber: 1,
                sugar: 2
            ),
            micros: MicroData()
        )
        
        foodItems.append(newItem)
    }
    
    private func saveMeal() {
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

// Preview provider
struct FoodItemEditView_Previews: PreviewProvider {
    static var previews: some View {
        @State var mockLabels = [
            LabelAnnotation(description: "Cheeseburger", score: 0.95, topicality: 0.95),
            LabelAnnotation(description: "French fries", score: 0.90, topicality: 0.90),
            LabelAnnotation(description: "Soft drink", score: 0.85, topicality: 0.85)
        ]
        
        return FoodItemEditView(
            viewModel: NutritionViewModel2(),
            foodItems: [],
            meal: nil,
            image: UIImage(systemName: "photo")!
        )
        .preferredColorScheme(.dark)
    }
}

