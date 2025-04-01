//
//  EnhancedNutritionScoreView.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI
import Foundation

struct EnhancedNutritionScoreView: View {
    let foodImage: UIImage
    let foodItems: [FoodItem]
    @ObservedObject var viewModel: NutritionViewModel2
    
    var body: some View {
        VStack {
            // Food image
            Image(uiImage: foodImage)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .cornerRadius(20)
                .padding()
            
            // Nutrition score
            VStack(spacing: 10) {
                Text("Nutrition Score")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(calculateNutritionScore())")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("out of 100")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(15)
            
            // Food list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(foodItems) { item in
                        FoodItemCard(item: item)
                    }
                }
                .padding()
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func calculateNutritionScore() -> Int {
        // Simple scoring based on food categories
        var score = 0
        for item in foodItems {
            switch item.category {
            case .proteins:
                score += 30
            case .vegetables:
                score += 40
            case .carbs:
                score += 20
            case .others:
                score += 10
            }
        }
        return min(score, 100)
    }
}

// MARK: - Supporting Views

// Food Item Card for horizontal scrolling
struct FoodItemCard: View {
    let item: FoodItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(Int(item.servingAmount))g")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("\(item.calories) cal")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 150)
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
}

// Note: MacroRingGroup is imported from MacroRingView.swift
// Note: Color extension with hexCode is imported from Color+Hex.swift

