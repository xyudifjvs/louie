//
//  NutritionScoreCalculator.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//
//  NutritionScoreCalculator.swift
//  Louie
//
//  Calculates nutrition scores based on food data

import Foundation

/// A service for calculating nutrition scores for meals
class NutritionScoreCalculator {
    static let shared = NutritionScoreCalculator()
    
    private init() {}
    
    /// Calculate a comprehensive nutrition score for a meal
    /// - Parameter foods: Array of food items in the meal
    /// - Returns: Nutrition score from 0-100
    func calculateScore(for foods: [FoodItem]) -> Int {
        guard !foods.isEmpty else { return 0 }
        
        // Combine all macros for the meal
        let combinedMacros = foods.reduce(MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)) { result, food in
            return MacroData(
                protein: result.protein + food.macros.protein,
                carbs: result.carbs + food.macros.carbs,
                fat: result.fat + food.macros.fat,
                fiber: result.fiber + food.macros.fiber,
                sugar: result.sugar + food.macros.sugar
            )
        }
        
        // Combine all micros for the meal
        var combinedMicros = MicroData()
        for food in foods {
            // Add micro values
            combinedMicros.vitaminA += food.micros.vitaminA
            combinedMicros.vitaminC += food.micros.vitaminC
            combinedMicros.vitaminD += food.micros.vitaminD
            combinedMicros.vitaminE += food.micros.vitaminE
            combinedMicros.vitaminK += food.micros.vitaminK
            combinedMicros.thiamin += food.micros.thiamin
            combinedMicros.riboflavin += food.micros.riboflavin
            combinedMicros.niacin += food.micros.niacin
            combinedMicros.vitaminB6 += food.micros.vitaminB6
            combinedMicros.folate += food.micros.folate
            combinedMicros.vitaminB12 += food.micros.vitaminB12
            
            combinedMicros.calcium += food.micros.calcium
            combinedMicros.iron += food.micros.iron
            combinedMicros.magnesium += food.micros.magnesium
            combinedMicros.phosphorus += food.micros.phosphorus
            combinedMicros.potassium += food.micros.potassium
            combinedMicros.sodium += food.micros.sodium
            combinedMicros.zinc += food.micros.zinc
            combinedMicros.copper += food.micros.copper
            combinedMicros.manganese += food.micros.manganese
            combinedMicros.selenium += food.micros.selenium
        }
        
        // Calculate individual score components
        let macroBalanceScore = calculateMacroBalanceScore(macros: combinedMacros)
        let caloricDensityScore = calculateCaloricDensityScore(foods: foods)
        let nutrientDiversityScore = calculateNutrientDiversityScore(micros: combinedMicros)
        let micronutrientContentScore = calculateMicronutrientContentScore(micros: combinedMicros)
        
        // Weight the components according to our plan
        let weightedScore = (
            macroBalanceScore * 0.30 +
            caloricDensityScore * 0.25 +
            nutrientDiversityScore * 0.25 +
            micronutrientContentScore * 0.20
        ) * 100
        
        return min(100, max(0, Int(weightedScore)))
    }
    
    /// Generate nutrition recommendations based on the meal score
    /// - Parameters:
    ///   - foods: Array of food items in the meal
    ///   - score: The calculated nutrition score
    /// - Returns: Array of recommendation strings
    func generateRecommendations(for foods: [FoodItem], score: Int) -> [String] {
        var recommendations: [String] = []
        
        // Combine macros for analysis
        let macros = foods.reduce(MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)) { result, food in
            return MacroData(
                protein: result.protein + food.macros.protein,
                carbs: result.carbs + food.macros.carbs,
                fat: result.fat + food.macros.fat,
                fiber: result.fiber + food.macros.fiber,
                sugar: result.sugar + food.macros.sugar
            )
        }
        
        // Calculate total calories
        let totalCalories = foods.reduce(0) { $0 + $1.calories }
        
        // Calculate percentages
        let totalGrams = macros.protein + macros.carbs + macros.fat
        if totalGrams > 0 {
            let proteinPercentage = macros.protein / totalGrams
            let carbPercentage = macros.carbs / totalGrams
            let fatPercentage = macros.fat / totalGrams
            
            // Macro balance recommendations
            if proteinPercentage < 0.15 {
                recommendations.append("Consider adding more protein to this meal.")
            } else if proteinPercentage > 0.45 {
                recommendations.append("This meal is very high in protein. Consider balancing with more complex carbs.")
            }
            
            if carbPercentage < 0.30 {
                recommendations.append("Try adding more complex carbohydrates for energy.")
            } else if carbPercentage > 0.60 {
                recommendations.append("This meal is carb-heavy. Consider adding more protein or healthy fats.")
            }
            
            if fatPercentage < 0.15 {
                recommendations.append("Add some healthy fats like avocado or olive oil.")
            } else if fatPercentage > 0.40 {
                recommendations.append("This meal is high in fat. Try reducing oils or fatty ingredients.")
            }
        }
        
        // Caloric recommendations
        if totalCalories < 300 {
            recommendations.append("This meal may be too light. Consider adding more nutritious ingredients.")
        } else if totalCalories > 800 {
            recommendations.append("This is a high-calorie meal. Consider reducing portion sizes.")
        }
        
        // Fiber recommendations
        if macros.fiber < 3 {
            recommendations.append("Add more fiber from vegetables, fruits, or whole grains.")
        }
        
        // Sugar recommendations
        if macros.sugar > 15 {
            recommendations.append("This meal is high in sugar. Consider reducing sweet ingredients.")
        }
        
        // If we have a high score and few recommendations
        if score > 80 && recommendations.isEmpty {
            recommendations.append("Great meal choice! This provides excellent nutritional balance.")
        }
        
        // If we have a low score but no specific recommendations
        if score < 50 && recommendations.isEmpty {
            recommendations.append("Try adding more variety of vegetables and lean proteins.")
        }
        
        return recommendations
    }
    
    // MARK: - Private Score Component Calculators
    
    /// Calculate the macronutrient balance score (0-1)
    private func calculateMacroBalanceScore(macros: MacroData) -> Double {
        // Ideal macro ratios based on general nutritional guidelines
        let idealProteinPercentage: Double = 0.30
        let idealCarbPercentage: Double = 0.40
        let idealFatPercentage: Double = 0.30
        
        let totalGrams = macros.protein + macros.carbs + macros.fat
        guard totalGrams > 0 else { return 0 }
        
        let proteinPercentage = macros.protein / totalGrams
        let carbPercentage = macros.carbs / totalGrams
        let fatPercentage = macros.fat / totalGrams
        
        // Calculate deviation from ideal (lower is better)
        let proteinDeviation = abs(proteinPercentage - idealProteinPercentage)
        let carbDeviation = abs(carbPercentage - idealCarbPercentage)
        let fatDeviation = abs(fatPercentage - idealFatPercentage)
        
        // Calculate overall deviation (0-1 scale, where 0 is perfect)
        let totalDeviation = (proteinDeviation + carbDeviation + fatDeviation) / 3
        
        // Convert to 0-1 score (1 being perfect)
        return max(0, min(1, 1 - totalDeviation))
    }
    
    /// Calculate the caloric density score (0-1)
    private func calculateCaloricDensityScore(foods: [FoodItem]) -> Double {
        // Calculate total calories
        let totalCalories = foods.reduce(0) { $0 + $1.calories }
        
        // Calculate nutrient density (protein + fiber per calorie)
        let totalProtein = foods.reduce(0.0) { $0 + $1.macros.protein }
        let totalFiber = foods.reduce(0.0) { $0 + $1.macros.fiber }
        
        // Guard against division by zero
        guard totalCalories > 0 else { return 0 }
        
        // Calculate protein and fiber per 100 calories
        let proteinPer100Cal = (totalProtein * 100) / Double(totalCalories)
        let fiberPer100Cal = (totalFiber * 100) / Double(totalCalories)
        
        // Score protein density (4g per 100 cal is ideal)
        let proteinScore = min(1.0, proteinPer100Cal / 5.0)
        
        // Score fiber density (1.5g per 100 cal is ideal)
        let fiberScore = min(1.0, fiberPer100Cal / 2.0)
        
        // Calculate portion appropriateness (scores highest when 400-700 calories for a meal)
        var portionScore = 1.0
        if totalCalories < 300 {
            portionScore = Double(totalCalories) / 300.0
        } else if totalCalories > 800 {
            portionScore = max(0, 1.0 - (Double(totalCalories) - 800.0) / 800.0)
        }
        
        // Weight the components
        return (proteinScore * 0.4) + (fiberScore * 0.3) + (portionScore * 0.3)
    }
    
    /// Calculate nutrient diversity score (0-1)
    private func calculateNutrientDiversityScore(micros: MicroData) -> Double {
        // Count micronutrients that are present in meaningful amounts
        var presentMicronutrients = 0
        
        // Check vitamins
        if micros.vitaminA > 0 { presentMicronutrients += 1 }
        if micros.vitaminC > 0 { presentMicronutrients += 1 }
        if micros.vitaminD > 0 { presentMicronutrients += 1 }
        if micros.vitaminE > 0 { presentMicronutrients += 1 }
        if micros.vitaminK > 0 { presentMicronutrients += 1 }
        if micros.thiamin > 0 { presentMicronutrients += 1 }
        if micros.riboflavin > 0 { presentMicronutrients += 1 }
        if micros.niacin > 0 { presentMicronutrients += 1 }
        if micros.vitaminB6 > 0 { presentMicronutrients += 1 }
        if micros.folate > 0 { presentMicronutrients += 1 }
        if micros.vitaminB12 > 0 { presentMicronutrients += 1 }
        
        // Check minerals
        if micros.calcium > 0 { presentMicronutrients += 1 }
        if micros.iron > 0 { presentMicronutrients += 1 }
        if micros.magnesium > 0 { presentMicronutrients += 1 }
        if micros.phosphorus > 0 { presentMicronutrients += 1 }
        if micros.potassium > 0 { presentMicronutrients += 1 }
        if micros.zinc > 0 { presentMicronutrients += 1 }
        if micros.copper > 0 { presentMicronutrients += 1 }
        if micros.manganese > 0 { presentMicronutrients += 1 }
        if micros.selenium > 0 { presentMicronutrients += 1 }
        
        // Sodium isn't counted as a positive (it's usually excessive)
        
        // Total potential micronutrients is 20
        return Double(presentMicronutrients) / 20.0
    }
    
    /// Calculate micronutrient content score (0-1)
    private func calculateMicronutrientContentScore(micros: MicroData) -> Double {
        // Define daily reference values (simplified)
        let vitaminARef: Double = 900 // μg
        let vitaminCRef: Double = 90 // mg
        let vitaminDRef: Double = 20 // μg
        let vitaminERef: Double = 15 // mg
        let vitaminKRef: Double = 120 // μg
        let thiaminRef: Double = 1.2 // mg
        let riboflavinRef: Double = 1.3 // mg
        let niacinRef: Double = 16 // mg
        let vitaminB6Ref: Double = 1.7 // mg
        let folateRef: Double = 400 // μg
        let vitaminB12Ref: Double = 2.4 // μg
        
        let calciumRef: Double = 1000 // mg
        let ironRef: Double = 18 // mg
        let magnesiumRef: Double = 400 // mg
        let phosphorusRef: Double = 700 // mg
        let potassiumRef: Double = 3500 // mg
        let zincRef: Double = 11 // mg
        let copperRef: Double = 0.9 // mg
        let manganeseRef: Double = 2.3 // mg
        let seleniumRef: Double = 55 // μg
        
        // Calculate percentage of daily value for each nutrient (capped at 100%)
        var percentOfDV = 0.0
        
        // Add vitamins
        percentOfDV += min(1.0, micros.vitaminA / vitaminARef)
        percentOfDV += min(1.0, micros.vitaminC / vitaminCRef)
        percentOfDV += min(1.0, micros.vitaminD / vitaminDRef)
        percentOfDV += min(1.0, micros.vitaminE / vitaminERef)
        percentOfDV += min(1.0, micros.vitaminK / vitaminKRef)
        percentOfDV += min(1.0, micros.thiamin / thiaminRef)
        percentOfDV += min(1.0, micros.riboflavin / riboflavinRef)
        percentOfDV += min(1.0, micros.niacin / niacinRef)
        percentOfDV += min(1.0, micros.vitaminB6 / vitaminB6Ref)
        percentOfDV += min(1.0, micros.folate / folateRef)
        percentOfDV += min(1.0, micros.vitaminB12 / vitaminB12Ref)
        
        // Add minerals
        percentOfDV += min(1.0, micros.calcium / calciumRef)
        percentOfDV += min(1.0, micros.iron / ironRef)
        percentOfDV += min(1.0, micros.magnesium / magnesiumRef)
        percentOfDV += min(1.0, micros.phosphorus / phosphorusRef)
        percentOfDV += min(1.0, micros.potassium / potassiumRef)
        percentOfDV += min(1.0, micros.zinc / zincRef)
        percentOfDV += min(1.0, micros.copper / copperRef)
        percentOfDV += min(1.0, micros.manganese / manganeseRef)
        percentOfDV += min(1.0, micros.selenium / seleniumRef)
        
        // Divide by total number of nutrients to get average (20 nutrients)
        return percentOfDV / 20.0
    }
}
