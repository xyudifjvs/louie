//  NutritionView.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI
import Foundation

// MARK: - Nutrition Module
struct NutritionView: View {
    @StateObject private var viewModel = NutritionViewModel2()
    @State private var showCameraView = false
    @State private var showPermissionAlert = false
    @State private var showDeleteConfirmation = false
    @State private var mealToDelete: MealEntry? = nil
    @State private var showNutritionFlow = false
    @State private var processedImage: UIImage?
    @State private var detectedLabels: [FoodLabelAnnotation] = []
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 5) {
                    Text("Nutrition")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    if !viewModel.meals.isEmpty {
                        Text("Today's nutrition score: \(todayAverageScore)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 5)
                    }
                }
                .padding(.horizontal)
                
                // Meal List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.meals.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No meals logged yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Take a photo of your meal to get started")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.meals) { meal in
                                MealCardView(meal: meal)
                                    .onTapGesture {
                                        // Handle meal selection
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            mealToDelete = meal
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }

            // ADD the new Floating Action Button here within the ZStack
            VStack {
                Spacer() // Pushes button to the bottom
                HStack {
                    Spacer() // Add a spacer BEFORE the button to center it
                    Button(action: {
                        showCameraView = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color(hexCode: "1a1a2e")) // Use top gradient color
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    Spacer() // Add a spacer AFTER the button to center it
                }
                 .padding(.bottom) // Add some padding from the bottom edge
            }
        }
        .sheet(isPresented: $showCameraView, content: {
            CameraView(viewModel: viewModel, showCameraView: $showCameraView)
        })
        .fullScreenCover(isPresented: $showNutritionFlow, content: {
            NutritionAnimatedFlowView(
                viewModel: viewModel,
                showView: $showNutritionFlow,
                foodImage: processedImage ?? UIImage(),
                detectedLabels: detectedLabels
            )
        })
        .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to log your meals.")
        }
        .alert("Delete Meal", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete {
                    viewModel.deleteMeal(meal)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this meal?")
        }
        .onAppear {
            viewModel.fetchMeals()
        }
    }
    
    private var todayAverageScore: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todayMeals = viewModel.meals.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        guard !todayMeals.isEmpty else { return 0 }
        return todayMeals.reduce(0) { $0 + $1.nutritionScore } / todayMeals.count
    }
}

// MARK: - Card View
struct MealCardView: View {
    let meal: MealEntry
    
    var body: some View {
        HStack(spacing: 15) {
            // Meal image
            if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            
            // Meal info
            VStack(alignment: .leading, spacing: 6) {
                // Time
                Text(formattedTime)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Food items
                Text(foodItemsText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                // Nutrition score
                HStack {
                    Text("Score: \(meal.nutritionScore)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(scoreColor.opacity(0.2))
                        .cornerRadius(5)
                        .foregroundColor(scoreColor)
                    
                    if meal.isManuallyAdjusted {
                        Text("Edited")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(5)
                            .foregroundColor(Color.blue)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: meal.timestamp)
    }
    
    private var foodItemsText: String {
        if meal.foods.isEmpty {
            return "No food items recorded"
        } else {
            return meal.foods.map { $0.name }.joined(separator: ", ")
        }
    }
    
    private var scoreColor: Color {
        if meal.nutritionScore >= 80 {
            return .green
        } else if meal.nutritionScore >= 60 {
            return .yellow
        } else if meal.nutritionScore >= 40 {
            return .orange
        } else {
            return .red
        }
    }
}
