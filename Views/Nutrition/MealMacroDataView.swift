//
//  MealMacroDataView.swift
//  Louie
//
//  Created by Carson on 4/4/25.
//

import SwiftUI

struct MealMacroDataView: View {
    let macros: MacroData
    
    var body: some View {
        HStack(spacing: 12) {
            MacroCard(label: "Calories", value: "\(macros.totalCalories)")
            MacroCard(label: "Protein", value: String(format: "%.0f g", macros.protein))
            MacroCard(label: "Carbs", value: String(format: "%.0f g", macros.carbs))
            MacroCard(label: "Fat", value: String(format: "%.0f g", macros.fat))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.25))
        .cornerRadius(10)
    }
}

// Helper view for individual macro cards
struct MacroCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity) // Ensure cards distribute width
    }
}

// Preview Provider
struct MealMacroDataView_Previews: PreviewProvider {
    static var previews: some View {
        MealMacroDataView(macros: MacroData(protein: 35, carbs: 55, fat: 20, fiber: 8, sugar: 15))
            .padding()
            .background(Color.gray) // Add background for preview visibility
    }
}

