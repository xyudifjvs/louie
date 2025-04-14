//
//  MealCardView.swift
//  Louie
//
//  Created by Carson on 4/4/25.
//

import SwiftUI

// Note: DateDisplayMode enum is now in Models/NutritionTypes.swift

struct MealCardView: View {
    let meal: MealEntry
    var dateDisplayMode: DateDisplayMode = .timeOfDay // Parameter to control date display
    
    // Access ViewModel's formatter. Ensure VM is provided where MealCardView is used.
    @EnvironmentObject var viewModel: NutritionViewModel2
    
    var body: some View {
        HStack(alignment: .top) {
            // Re-introduce image loading logic
            if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Placeholder if no image data
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Top row: Primary Food Item & Date/Time
                HStack {
                    Text(meal.primaryFoodItem)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedDate) // Use computed property for date/time
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Middle row: Nutrition Score
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Score: \(meal.nutritionScore)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Bottom row: User Notes (if available)
                if let notes = meal.userNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
    
    // Computed property for formatted date string
    private var formattedDate: String {
        switch dateDisplayMode {
        case .timeOfDay:
            return meal.timestamp.formatted(date: .omitted, time: .shortened)
        case .dayOfWeek:
            // Use the formatter from the ViewModel
            return viewModel.dayOfWeekFormatter.string(from: meal.timestamp)
        }
    }
}

// Preview Provider (requires DateDisplayMode to be visible)
struct MealCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample MealEntry for preview
        let sampleMacros = MacroData(protein: 25, carbs: 40, fat: 15, fiber: 5, sugar: 10)
        let sampleMicros = MicroData()
        let sampleFoods = [
            FoodItem(name: "Chicken Breast", calories: 150, macros: MacroData(protein: 30, carbs: 0, fat: 3)),
            FoodItem(name: "Broccoli", calories: 50, macros: MacroData(protein: 3, carbs: 10, fat: 1, fiber: 4))
        ]
        let sampleMeal = MealEntry(
            timestamp: Date(),
            foods: sampleFoods,
            nutritionScore: 85,
            macronutrients: sampleMacros,
            micronutrients: sampleMicros,
            userNotes: "Delicious and healthy!"
        )
        
        let viewModel = NutritionViewModel2()
        
        return VStack(spacing: 10) {
            MealCardView(meal: sampleMeal, dateDisplayMode: .timeOfDay)
                .environmentObject(viewModel) // Provide VM for preview
            MealCardView(meal: sampleMeal, dateDisplayMode: .dayOfWeek)
                 .environmentObject(viewModel) // Provide VM for preview
        }
        .padding()
        .background(Color.gray.opacity(0.5))
    }
}

