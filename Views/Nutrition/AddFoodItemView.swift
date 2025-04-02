//
//  AddFoodItemView.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI

struct AddFoodItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var foodItems: [FoodItem]
    
    @State private var foodName: String = ""
    @State private var selectedServingIndex = 0
    private let servingOptions = ["1 serving", "2 servings", "3 servings"]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                              startPoint: .top,
                              endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Food name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Food Name")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Enter food name", text: $foodName)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    // Serving size picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Serving Size")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Picker("Serving Size", selection: $selectedServingIndex) {
                            ForEach(0..<servingOptions.count, id: \.self) { index in
                                Text(servingOptions[index]).foregroundColor(.white)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    
                    Spacer()
                    
                    Button(action: addFood) {
                        Text("Add Item")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hexCode: "2a6041"), Color(hexCode: "1a1a2e")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(foodName.isEmpty)
                    .opacity(foodName.isEmpty ? 0.6 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func addFood() {
        // Calculate calories based on serving size
        let baseCalories = 100
        let caloriesMultiplier = selectedServingIndex + 1 // 1, 2, or 3
        let calculatedCalories = baseCalories * caloriesMultiplier
        
        // Create new food item
        let newItem = FoodItem(
            name: foodName,
            amount: servingOptions[selectedServingIndex],
            servingAmount: Double(100 * caloriesMultiplier),
            calories: calculatedCalories,
            category: determineFoodCategory(name: foodName),
            macros: MacroData(
                protein: 5.0 * Double(caloriesMultiplier),
                carbs: 10.0 * Double(caloriesMultiplier),
                fat: 5.0 * Double(caloriesMultiplier),
                fiber: 1.0 * Double(caloriesMultiplier),
                sugar: 2.0 * Double(caloriesMultiplier)
            ),
            micros: MicroData()
        )
        
        // Add to the list and dismiss
        foodItems.append(newItem)
        presentationMode.wrappedValue.dismiss()
    }
    
    // Helper to determine food category from name
    private func determineFoodCategory(name: String) -> FoodCategory {
        let lowercaseName = name.lowercased()
        
        if lowercaseName.contains("chicken") || lowercaseName.contains("beef") || 
           lowercaseName.contains("fish") || lowercaseName.contains("meat") || 
           lowercaseName.contains("egg") || lowercaseName.contains("protein") ||
           lowercaseName.contains("tofu") {
            return .proteins
        }
        
        if lowercaseName.contains("vegetable") || lowercaseName.contains("salad") || 
           lowercaseName.contains("lettuce") || lowercaseName.contains("spinach") || 
           lowercaseName.contains("broccoli") || lowercaseName.contains("carrot") ||
           lowercaseName.contains("tomato") {
            return .vegetables
        }
        
        if lowercaseName.contains("bread") || lowercaseName.contains("rice") || 
           lowercaseName.contains("pasta") || lowercaseName.contains("potato") || 
           lowercaseName.contains("fries") || lowercaseName.contains("bun") ||
           lowercaseName.contains("cereal") {
            return .carbs
        }
        
        return .others
    }
}

