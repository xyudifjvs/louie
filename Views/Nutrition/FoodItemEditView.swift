//
//  FoodItemEditView.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//

import SwiftUI

struct FoodItemEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: NutritionViewModel
    
    @Binding var selectedLabels: [LabelAnnotation]
    let foodImage: UIImage
    
    @State private var newFoodItem: String = ""
    @State private var editingItem: String?
    @State private var itemToEdit: String = ""
    @State private var isLookingUpNutrition = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                Text("Edit Food Items")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Add, remove, or edit detected items")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 20)
                
                // Add new item field
                HStack {
                    TextField("Add a food item", text: $newFoodItem)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .accentColor(.white)
                    
                    Button(action: addNewItem) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                    .disabled(newFoodItem.isEmpty)
                    .opacity(newFoodItem.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Current items list
                if selectedLabels.isEmpty {
                    Spacer()
                    Text("No food items selected")
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                    Spacer()
                } else {
                    List {
                        ForEach(selectedLabels, id: \.description) { label in
                            if editingItem == label.description {
                                // Editing mode
                                HStack {
                                    TextField("Edit item", text: $itemToEdit)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        saveEdit(originalItem: label)
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    
                                    Button(action: {
                                        editingItem = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            } else {
                                // Display mode
                                HStack {
                                    Text(label.description.capitalized)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        startEditing(label)
                                    }) {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Button(action: {
                                        removeItem(label)
                                    }) {
                                        Image(systemName: "trash.circle")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.black.opacity(0.2))
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
                
                // Done button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(hexCode: "2a6041"))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            
            // Loading overlay
            if isLookingUpNutrition {
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            Text("Looking up nutrition data...")
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
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Add a new food item
    private func addNewItem() {
        guard !newFoodItem.isEmpty else { return }
        
        let itemName = newFoodItem.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create a temporary label with low confidence
        let tempLabel = LabelAnnotation(
            description: itemName,
            score: Float(0.7),
            topicality: Float(0.7)
        )
        
        // Add to selectedLabels 
        selectedLabels.append(tempLabel)
        
        // Clear the input field
        newFoodItem = ""
    }
    
    // Start editing an item
    private func startEditing(_ label: LabelAnnotation) {
        editingItem = label.description
        itemToEdit = label.description
    }
    
    // Save edited item
    private func saveEdit(originalItem: LabelAnnotation) {
        guard let index = selectedLabels.firstIndex(where: { $0.description == originalItem.description }),
              !itemToEdit.isEmpty else {
            editingItem = nil
            return
        }
        
        // Create a new label with updated description but same score
        let updatedLabel = LabelAnnotation(
            description: itemToEdit.trimmingCharacters(in: .whitespacesAndNewlines),
            score: originalItem.score,
            topicality: originalItem.topicality
        )
        
        // Replace the original item
        selectedLabels[index] = updatedLabel
        
        // Exit editing mode
        editingItem = nil
    }
    
    // Remove an item
    private func removeItem(_ label: LabelAnnotation) {
        if let index = selectedLabels.firstIndex(where: { $0.description == label.description }) {
            selectedLabels.remove(at: index)
        }
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
            viewModel: NutritionViewModel(),
            selectedLabels: $mockLabels,
            foodImage: UIImage(systemName: "photo")!
        )
        .preferredColorScheme(.dark)
    }
}

