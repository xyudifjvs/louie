//
//  GoalsEditorView.swift
//  Louie
//
//  Created by Carson on 4/2/25.
//

import SwiftUI

struct GoalsEditorView: View {
    @Binding var goals: NutritionGoals
    @Binding var isPresented: Bool
    
    // Temporary state for editing
    @State private var caloriesInput: String = ""
    @State private var proteinInput: String = ""
    @State private var carbsInput: String = ""
    @State private var fatInput: String = ""
    
    // Validation state
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    // Initialize input fields from goals
    private func initializeInputs() {
        caloriesInput = "\(goals.caloriesGoal)"
        proteinInput = "\(Int(goals.proteinGoal))"
        carbsInput = "\(Int(goals.carbsGoal))"
        fatInput = "\(Int(goals.fatGoal))"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                              startPoint: .top,
                              endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Set Weekly Nutrition Goals")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Goals input form
                    VStack(spacing: 16) {
                        goalsFormRow(title: "Calories", value: $caloriesInput, unit: "kcal", icon: "flame.fill", color: .red)
                        goalsFormRow(title: "Protein", value: $proteinInput, unit: "g", icon: "tortoise.fill", color: .blue)
                        goalsFormRow(title: "Carbs", value: $carbsInput, unit: "g", icon: "leaf.fill", color: .green)
                        goalsFormRow(title: "Fat", value: $fatInput, unit: "g", icon: "circle.hexagongrid.fill", color: .orange)
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Information note
                    Text("These are your weekly targets to help you stay on track with your nutrition goals.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .padding(.bottom, 20)
                .alert(isPresented: $showValidationAlert) {
                    Alert(
                        title: Text("Invalid Input"),
                        message: Text(validationMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoals()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                initializeInputs()
            }
        }
    }
    
    // Create a row for the form
    private func goalsFormRow(title: String, value: Binding<String>, unit: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            TextField("0", text: value)
                .keyboardType(.numberPad)
                .frame(width: 70)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            Text(unit)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 30, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
    
    // Save goals with validation
    private func saveGoals() {
        // Validate inputs
        guard let calories = Int(caloriesInput), calories > 0 else {
            validationMessage = "Please enter a valid calorie goal (must be a positive number)."
            showValidationAlert = true
            return
        }
        
        guard let protein = Double(proteinInput), protein >= 0 else {
            validationMessage = "Please enter a valid protein goal (must be a non-negative number)."
            showValidationAlert = true
            return
        }
        
        guard let carbs = Double(carbsInput), carbs >= 0 else {
            validationMessage = "Please enter a valid carbs goal (must be a non-negative number)."
            showValidationAlert = true
            return
        }
        
        guard let fat = Double(fatInput), fat >= 0 else {
            validationMessage = "Please enter a valid fat goal (must be a non-negative number)."
            showValidationAlert = true
            return
        }
        
        // Update goals
        goals.caloriesGoal = calories
        goals.proteinGoal = protein
        goals.carbsGoal = carbs
        goals.fatGoal = fat
        
        // Save to UserDefaults
        goals.saveToUserDefaults()
        
        // Dismiss sheet
        isPresented = false
    }
}

