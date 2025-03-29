//
//  FoodLogConfirmationView.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//

import SwiftUI

struct FoodLogConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: NutritionViewModel
    
    let mealEntry: MealEntry
    @State private var userNotes: String = ""
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Header
                    Text("Confirm Your Meal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Meal image
                    if let imageData = mealEntry.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                    }
                    
                    // Nutrition score
                    HStack(spacing: 15) {
                        VStack {
                            Text("Nutrition Score")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(mealEntry.nutritionScore)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(nutritionScoreColor)
                        }
                        .frame(minWidth: 120, minHeight: 120)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.top, 5)
                    
                    // Food items group
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Food Items")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(mealEntry.foods) { food in
                                foodItemRow(food)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Macronutrients group
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Macronutrients")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        macronutrientsCard
                    }
                    .padding(.top, 10)
                    
                    // Notes section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add Notes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        TextEditor(text: $userNotes)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .frame(height: 100)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    
                    // Button row
                    HStack(spacing: 15) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        }
                        
                        Button(action: saveMeal) {
                            Text("Save")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color(hexCode: "2a6041"))
                                .cornerRadius(10)
                        }
                        .disabled(isSaving)
                        .opacity(isSaving ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            
            // Loading overlay
            if isSaving {
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            Text("Saving your meal...")
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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
            Text("Back")
                .foregroundColor(.white)
        })
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // Save the meal with user notes
    private func saveMeal() {
        isSaving = true
        
        // Create a copy of the meal entry with the user notes
        var updatedMeal = mealEntry
        updatedMeal.userNotes = userNotes.isEmpty ? nil : userNotes
        
        // Save to CloudKit via the view model
        viewModel.saveMeal(updatedMeal)
        
        // Wait a moment for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            
            // Dismiss this view - the previous views will auto-dismiss through the onDismiss handler
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // Food item row
    private func foodItemRow(_ food: FoodItem) -> some View {
        HStack {
            Text(food.name.capitalized)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(food.amount)
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
            
            Text("\(food.calories) cal")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
    
    // Macronutrients card
    private var macronutrientsCard: some View {
        HStack(spacing: 15) {
            macronutrientCircle(
                value: mealEntry.macronutrients.protein,
                label: "Protein",
                color: Color.blue,
                unit: "g"
            )
            
            macronutrientCircle(
                value: mealEntry.macronutrients.carbs,
                label: "Carbs",
                color: Color.green,
                unit: "g"
            )
            
            macronutrientCircle(
                value: mealEntry.macronutrients.fat,
                label: "Fat",
                color: Color.orange,
                unit: "g"
            )
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Macronutrient circle
    private func macronutrientCircle(value: Double, label: String, color: Color, unit: String) -> some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 5)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(color, lineWidth: 5)
                    .frame(width: 70, height: 70)
                    .rotationEffect(Angle(degrees: -90))
                
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 5)
        }
    }
    
    // Color for nutrition score
    private var nutritionScoreColor: Color {
        if mealEntry.nutritionScore >= 80 {
            return Color.green
        } else if mealEntry.nutritionScore >= 60 {
            return Color.yellow
        } else if mealEntry.nutritionScore >= 40 {
            return Color.orange
        } else {
            return Color.red
        }
    }
}

// Preview provider
struct FoodLogConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFoods = [
            FoodItem(
                name: "Cheeseburger",
                amount: "1 serving",
                calories: 450,
                macros: MacroData(protein: 25, carbs: 40, fat: 22, fiber: 2, sugar: 8),
                micros: MicroData()
            ),
            FoodItem(
                name: "French Fries",
                amount: "Medium",
                calories: 320,
                macros: MacroData(protein: 4, carbs: 45, fat: 15, fiber: 4, sugar: 1),
                micros: MicroData()
            )
        ]
        
        let mockMeal = MealEntry(
            id: UUID(),
            timestamp: Date(),
            imageData: nil,
            imageURL: nil,
            foods: mockFoods,
            nutritionScore: 65,
            macronutrients: MacroData(protein: 29, carbs: 85, fat: 37, fiber: 6, sugar: 9),
            micronutrients: MicroData(),
            userNotes: nil,
            isManuallyAdjusted: true
        )
        
        return FoodLogConfirmationView(
            viewModel: NutritionViewModel(),
            mealEntry: mockMeal
        )
        .preferredColorScheme(.dark)
    }
}

