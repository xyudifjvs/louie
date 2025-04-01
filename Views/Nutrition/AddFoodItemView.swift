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
    @State private var servingAmount: String = "1 serving"
    @State private var calories: Int = 200
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                              startPoint: .top,
                              endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    TextField("Food name", text: $foodName)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    TextField("Serving size", text: $servingAmount)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    // Calories stepper
                    HStack {
                        Text("Calories: \(calories)")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Stepper("", value: $calories, in: 0...1000, step: 50)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(action: addFood) {
                        Text("Add Food Item")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
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
        let newItem = FoodItem(
            name: foodName,
            amount: servingAmount,
            calories: calories
        )
        
        foodItems.append(newItem)
        presentationMode.wrappedValue.dismiss()
    }
}

