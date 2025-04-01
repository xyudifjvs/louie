//
//  SmartListDetectionView.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI
import Foundation

// MARK: - Supporting Views for SmartListDetectionView

struct SmartListDetectionView: View {
    let foodImage: UIImage
    let detectedLabels: [FoodLabelAnnotation]
    @Binding var foodItems: [FoodItem]
    @Binding var showAddFood: Bool
    @Binding var showFoods: Bool
    
    // GeometryReader to get screen dimensions
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Top 50% - Image Card
                    imageCard(height: geometry.size.height * 0.45)
                    
                    // Bottom 50% - Category Cards in 2x2 Grid
                    categoryGridSection(width: geometry.size.width)
                    
                    // Bottom Action Buttons
                    actionButtons
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Image Card Section
    private func imageCard(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image title
            Text("Your Meal")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 8)
            
            // Food image 
            Image(uiImage: foodImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height - 40) // Account for title and padding
                .clipped()
                .cornerRadius(16)
        }
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Category Grid Section
    private func categoryGridSection(width: CGFloat) -> some View {
        VStack(spacing: 12) {
            // First row
            HStack(spacing: 12) {
                categoryCard(for: .proteins, width: width * 0.44)
                categoryCard(for: .carbs, width: width * 0.44)
            }
            
            // Second row
            HStack(spacing: 12) {
                categoryCard(for: .vegetables, width: width * 0.44)
                categoryCard(for: .others, width: width * 0.44)
            }
        }
    }
    
    // MARK: - Individual Category Card
    private func categoryCard(for category: FoodCategory, width: CGFloat) -> some View {
        let categoryItems = foodItems.filter { $0.category == category }
        let categoryInfo = getCategoryInfo(category)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Card header
            HStack {
                Image(systemName: categoryInfo.icon)
                    .foregroundColor(categoryInfo.color)
                
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Show items if available, otherwise a placeholder
            if categoryItems.isEmpty {
                Text("No items detected")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption)
                    .padding(.top, 4)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(categoryItems) { item in
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(Int(item.calories)) cal")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .frame(maxHeight: 80)
            }
        }
        .padding(12)
        .frame(width: width, height: width * 0.8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    categoryInfo.color.opacity(0.8),
                    categoryInfo.color.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // Helper to get category UI info
    private func getCategoryInfo(_ category: FoodCategory) -> (icon: String, color: Color) {
        switch category {
        case .proteins:
            return ("fish", Color(hexCode: "2a6c8e"))
        case .carbs:
            return ("rectangle.grid.2x2", Color(hexCode: "8e612a"))
        case .vegetables:
            return ("leaf.fill", Color(hexCode: "2a8e38"))
        case .others:
            return ("drop.fill", Color(hexCode: "8e2a6c"))
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Edit button
            Button(action: {
                showAddFood = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Confirm button
            Button(action: {
                // Navigate to next screen
                withAnimation {
                    showFoods = true
                }
            }) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Confirm")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hexCode: "2a6041"), Color(hexCode: "1a1a2e")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(foodItems.isEmpty)
            .opacity(foodItems.isEmpty ? 0.5 : 1.0)
        }
        .padding(.top, 10)
    }
}

// MARK: - Supporting Views

struct FoodCategoryView: View {
    let category: FoodCategory
    let items: [FoodItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(items) { item in
                HStack {
                    Text(item.name)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(item.servingAmount))g")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
}

// MARK: - Supporting Views

// Category Section
struct CategorySection: View {
    let categoryName: String
    let foodItems: [FoodItem]
    let onDelete: (FoodItem) -> Void
    
    private var categoryIcon: String {
        switch categoryName {
        case "Proteins":
            return "drumstick.fill"
        case "Vegetables":
            return "leaf.fill"
        case "Carbs":
            return "rectangle.grid.2x2.fill"
        default:
            return "circle.hexagongrid.fill"
        }
    }
    
    private var categoryColor: Color {
        switch categoryName {
        case "Proteins":
            return .blue
        case "Vegetables":
            return .green
        case "Carbs":
            return .orange
        default:
            return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category header
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                
                Text(categoryName)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)
            
            // Food items
            ForEach(foodItems) { item in
                FoodItemRow(item: item, onDelete: onDelete)
                    .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

// Food Item Row
struct FoodItemRow: View {
    let item: FoodItem
    let onDelete: (FoodItem) -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    var body: some View {
        ZStack {
            // Delete background
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        self.onDelete(item)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .frame(width: 60, height: 40)
                        .background(Color.red)
                        .cornerRadius(8)
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
                
                Text("\(item.calories) cal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hexCode: "1a1a2e").opacity(0.8), Color(hexCode: "2a6041").opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(8)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            self.offset = value.translation.width
                            self.isSwiping = true
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -50 {
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
        }
    }
}

