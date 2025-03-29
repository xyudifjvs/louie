//
//  FoodDetectionResultView.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//

import SwiftUI

struct FoodDetectionResultView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: NutritionViewModel
    
    let detectedLabels: [LabelAnnotation]
    let foodImage: UIImage
    
    @State private var selectedLabels: [LabelAnnotation]
    @State private var isAnalyzing = false
    @State private var showingEditView = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var mealEntryToConfirm: MealEntry?
    @State private var showConfirmationView = false
    
    // Initialize with detected labels and preselect all of them
    init(viewModel: NutritionViewModel, detectedLabels: [LabelAnnotation], foodImage: UIImage) {
        self.viewModel = viewModel
        self.detectedLabels = detectedLabels
        self.foodImage = foodImage
        _selectedLabels = State(initialValue: detectedLabels)
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
                Text("Detected Food Items")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Select the items that were detected correctly")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 10)
                
                // Food image
                Image(uiImage: foodImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                
                // Detected items list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(detectedLabels, id: \.description) { label in
                            foodItemRow(label)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Button row
                HStack(spacing: 15) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingEditView = true
                    }) {
                        Text("Edit Items")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color(hexCode: "3a7d5a"))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        proceedToConfirmation()
                    }) {
                        Text("Confirm")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color(hexCode: "2a6041"))
                            .cornerRadius(10)
                    }
                    .disabled(selectedLabels.isEmpty)
                    .opacity(selectedLabels.isEmpty ? 0.5 : 1.0)
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
            
            // Loading overlay
            if isAnalyzing {
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            Text("Processing selected foods...")
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
        .sheet(isPresented: $showingEditView) {
            FoodItemEditView(viewModel: viewModel, selectedLabels: $selectedLabels, foodImage: foodImage)
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showConfirmationView, onDismiss: {
            if !showingError {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            if let mealEntry = mealEntryToConfirm {
                FoodLogConfirmationView(
                    viewModel: viewModel,
                    mealEntry: mealEntry
                )
            }
        }
    }
    
    // Individual food item row
    private func foodItemRow(_ label: LabelAnnotation) -> some View {
        let isSelected = selectedLabels.contains { $0.description == label.description }
        
        return HStack {
            Text(label.description.capitalized)
                .foregroundColor(.white)
                .padding(.vertical, 8)
            
            Spacer()
            
            Text("\(Int(label.score * 100))%")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
                .padding(.trailing, 10)
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color(hexCode: "4CD964") : .white.opacity(0.6))
                .font(.system(size: 22))
                .onTapGesture {
                    toggleSelection(label)
                }
        }
        .padding(.horizontal, 15)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
    
    // Toggle selection of a food item
    private func toggleSelection(_ label: LabelAnnotation) {
        if let index = selectedLabels.firstIndex(where: { $0.description == label.description }) {
            selectedLabels.remove(at: index)
        } else {
            selectedLabels.append(label)
        }
    }
    
    // Proceed to the confirmation step with selected items
    private func proceedToConfirmation() {
        isAnalyzing = true
        
        // Use the NutritionService to get nutrition data for the selected labels
        NutritionService.shared.getNutritionInfo(for: selectedLabels) { result in
            DispatchQueue.main.async {
                isAnalyzing = false
                
                switch result {
                case .success(let foodItems):
                    // Use AIFoodAnalysisService to create a meal entry with the food items
                    let mealEntry = AIFoodAnalysisService.shared.createMealEntry(
                        from: foodItems,
                        image: self.foodImage,
                        isManuallyAdjusted: true
                    )
                    
                    // Present the confirmation view
                    self.showFoodLogConfirmation(mealEntry: mealEntry)
                    
                case .failure(let error):
                    errorMessage = "Failed to get nutrition data: \(error.description)"
                    showingError = true
                }
            }
        }
    }
    
    // Navigate to the confirmation view
    private func showFoodLogConfirmation(mealEntry: MealEntry) {
        self.mealEntryToConfirm = mealEntry
        self.showConfirmationView = true
    }
}

// Preview provider
struct FoodDetectionResultView_Previews: PreviewProvider {
    static var previews: some View {
        let mockLabels = [
            LabelAnnotation(description: "Cheeseburger", score: 0.95, topicality: 0.95),
            LabelAnnotation(description: "French fries", score: 0.90, topicality: 0.90),
            LabelAnnotation(description: "Soft drink", score: 0.85, topicality: 0.85)
        ]
        
        return FoodDetectionResultView(
            viewModel: NutritionViewModel(),
            detectedLabels: mockLabels,
            foodImage: UIImage(systemName: "photo")!
        )
        .preferredColorScheme(.dark)
    }
}

