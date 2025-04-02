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
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top 50% - Today's Meals section
                    VStack(spacing: 16) {
                        // Header with title and action buttons
                        ZStack {
                            // Centered title
                            Text("Nutrition")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Left aligned buttons
                            HStack {
                                Button(action: {
                                    // Calendar button action (to be implemented later)
                                }) {
                                    Image(systemName: "calendar")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                            }
                            
                            // Right aligned buttons
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    // Barcode scanner button action (to be implemented later)
                                }) {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    showCameraView = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Today's Meals Container
                        VStack(spacing: 16) {
                            // Container header
                            HStack {
                                Text("Today's Meals")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                            
                            // Meal cards for today
                            if viewModel.isLoading {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Spacer()
                            } else if viewModel.todayMeals.isEmpty {
                                Spacer()
                                VStack(spacing: 16) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text("No meals logged today")
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
                                // Use List with swipeActions for a native swipe-to-delete experience
                                List {
                                    ForEach(viewModel.todayMeals) { meal in
                                        MealCardView(meal: meal)
                                            .listRowBackground(Color.clear)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        viewModel.deleteMeal(meal)
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                    .listRowSeparator(.hidden)
                                }
                                .listStyle(PlainListStyle())
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                            }
                        }
                        .frame(minHeight: geometry.size.height * 0.3)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.2))
                        )
                        .padding(.horizontal)
                        
                        Spacer() // Push content to the top
                    }
                    .frame(height: geometry.size.height * 0.5)
                    
                    // Bottom 50% - Weekly Goals section
                    VStack {
                        // Weekly Goals View
                        WeeklyGoalsView(goals: $viewModel.nutritionGoals)
                            .padding(.top, 16)
                            .padding(.bottom, 30) // Reduced padding to avoid too much empty space
                    }
                    .frame(height: geometry.size.height * 0.5)
                }
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

// MARK: - MealEntry Extension
extension MealEntry {
    /// Returns the food item with highest calories, or first food item, or fallback text
    var primaryFoodItem: String {
        guard !foods.isEmpty else { return "Meal" }
        
        // Filter out problematic food names that are too long or contain suspicious phrases
        let validFoods = foods.filter { food in
            let name = food.name.lowercased()
            
            // Filter out items that look like essay titles or web content
            let suspiciousPhrases = ["eating", "affect", "health", "justify", "our", "the impact of", "benefits of", "why"]
            let isSuspicious = suspiciousPhrases.contains { name.contains($0) }
            
            // Keep only food names that are reasonably short and don't look like article titles
            return name.count < 25 && !isSuspicious
        }
        
        // Use filtered foods if available
        if !validFoods.isEmpty {
            // Try to find the food with highest calories
            if let highestCalorieFood = validFoods.max(by: { $0.calories < $1.calories }) {
                return highestCalorieFood.name.capitalized
            }
            
            // Fallback to first valid food
            return validFoods.first!.name.capitalized
        }
        
        // If we have no valid foods, provide a generic label based on time
        let hour = Calendar.current.component(.hour, from: timestamp)
        if hour < 11 {
            return "Breakfast"
        } else if hour < 14 {
            return "Lunch"
        } else if hour < 18 {
            return "Afternoon Snack"
        } else {
            return "Dinner"
        }
    }
    
    /// Returns true if the meal was logged today
    var isFromToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }
}

// MARK: - Card View
struct MealCardView: View {
    let meal: MealEntry
    
    var body: some View {
        // Use native .swipeActions for better scrolling compatibility
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
                // Primary food name
                Text(meal.primaryFoodItem)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Food items - without serving size info
                Text(foodItemsText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                // Time
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Circular nutrition score
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.3))
                    .frame(width: 42, height: 42)
                
                Text("\(meal.nutritionScore)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(scoreColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: meal.timestamp)
    }
    
    private var foodItemsText: String {
        if meal.foods.isEmpty {
            return "No food items recorded"
        } else if meal.foods.count == 1 {
            return "\(meal.foods.count) food item"
        } else {
            return "\(meal.foods.count) food items"
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
