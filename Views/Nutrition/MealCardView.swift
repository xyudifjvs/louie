//
//  MealCardView.swift
//  Louie
//
//  Created by Carson on 3/28/25.
//

import SwiftUI
import UIKit

struct MealCardView: View {
    let meal: MealEntry
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100:
            return Color.green
        case 60..<80:
            return Color.blue
        case 40..<60:
            return Color.yellow
        default:
            return Color.red
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                VStack(alignment: .leading) {
                    Text(formattedTime(meal.timestamp))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(dateString(from: meal.timestamp))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(scoreColor(meal.nutritionScore))
                        .frame(width: 50, height: 50)
                    
                    Text("\(meal.nutritionScore)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 2)
            
            // Food items list
            ForEach(meal.foods) { food in
                HStack {
                    Text(food.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(food.amount)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(food.calories) cal")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 2)
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Macro breakdown
            HStack(spacing: 12) {
                MacroView(
                    title: "Protein",
                    value: "\(Int(meal.macronutrients.protein))g",
                    color: .blue
                )
                
                MacroView(
                    title: "Carbs",
                    value: "\(Int(meal.macronutrients.carbs))g",
                    color: .green
                )
                
                MacroView(
                    title: "Fat",
                    value: "\(Int(meal.macronutrients.fat))g",
                    color: .yellow
                )
                
                Spacer()
                
                Text("\(meal.macronutrients.totalCalories) cal")
                    .font(.caption)
                    .padding(6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(5)
                    .foregroundColor(.white)
            }
            
            // Meal image thumbnail if available
            if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .cornerRadius(8)
                    .padding(.top, 5)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hexCode: "1a1a2e").opacity(0.8), Color(hexCode: "2a6041").opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct MacroView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }
} 
