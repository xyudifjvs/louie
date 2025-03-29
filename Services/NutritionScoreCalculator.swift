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
        
        // Calculate negative factor penalties
        let sodiumPenalty = calculateSodiumPenalty(micros: combinedMicros)
        let processedFoodPenalty = calculateProcessedFoodPenalty(foods: foods)
        let saturatedFatPenalty = calculateSaturatedFatPenalty(foods: foods)
        let refinedCarbsPenalty = calculateRefinedCarbsPenalty(foods: foods)
        
        // Weight the positive components
        let baseScore = (
            macroBalanceScore * 0.30 +
            caloricDensityScore * 0.25 +
            nutrientDiversityScore * 0.25 +
            micronutrientContentScore * 0.20
        )
        
        // Apply penalties
        let penaltyFactor = 1.0 - (
            (sodiumPenalty * 0.25) +
            (processedFoodPenalty * 0.30) +
            (saturatedFatPenalty * 0.25) +
            (refinedCarbsPenalty * 0.20)
        )
        
        // Calculate final score
        let finalScore = baseScore * penaltyFactor * 100
        
        // For debug output
        print("Nutrition score components:")
        print("- Macro balance: \(Int(macroBalanceScore * 100))")
        print("- Caloric density: \(Int(caloricDensityScore * 100))")
        print("- Nutrient diversity: \(Int(nutrientDiversityScore * 100))")
        print("- Micronutrient content: \(Int(micronutrientContentScore * 100))")
        print("Penalties:")
        print("- Sodium: \(Int(sodiumPenalty * 100))%")
        print("- Processed food: \(Int(processedFoodPenalty * 100))%")
        print("- Saturated fat: \(Int(saturatedFatPenalty * 100))%")
        print("- Refined carbs: \(Int(refinedCarbsPenalty * 100))%")
        print("Final score: \(Int(finalScore))")
        
        return min(100, max(0, Int(finalScore)))
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
        
        // Combine micros for analysis
        var micros = MicroData()
        for food in foods {
            micros.sodium += food.micros.sodium
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
        
        // Sodium recommendations
        if micros.sodium > 800 {
            recommendations.append("This meal is high in sodium. Consider lower-salt alternatives.")
        }
        
        // Process indicators
        if isProcessedFood(foods) {
            recommendations.append("This meal contains highly processed foods. Try incorporating more whole foods.")
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
        var totalPossiblePoints = 0
        
        // Define minimum meaningful thresholds (approximately 10% of daily value)
        let minVitaminA = 90.0 // μg
        let minVitaminC = 9.0 // mg
        let minVitaminD = 2.0 // μg
        let minVitaminE = 1.5 // mg
        let minVitaminK = 12.0 // μg
        let minThiamin = 0.12 // mg
        let minRiboflavin = 0.13 // mg
        let minNiacin = 1.6 // mg
        let minVitaminB6 = 0.17 // mg
        let minFolate = 40.0 // μg
        let minVitaminB12 = 0.24 // μg
        
        let minCalcium = 100.0 // mg
        let minIron = 1.8 // mg
        let minMagnesium = 40.0 // mg
        let minPhosphorus = 70.0 // mg
        let minPotassium = 350.0 // mg
        let minZinc = 1.1 // mg
        let minCopper = 0.09 // mg
        let minManganese = 0.23 // mg
        let minSelenium = 5.5 // μg
        
        // Check vitamins with meaningful thresholds
        totalPossiblePoints += 1; if micros.vitaminA >= minVitaminA { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.vitaminC >= minVitaminC { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.vitaminD >= minVitaminD { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.vitaminE >= minVitaminE { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.vitaminK >= minVitaminK { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.thiamin >= minThiamin { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.riboflavin >= minRiboflavin { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.niacin >= minNiacin { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.vitaminB6 >= minVitaminB6 { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.folate >= minFolate { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.vitaminB12 >= minVitaminB12 { presentMicronutrients += 1 }
        
        // Check minerals with meaningful thresholds
        totalPossiblePoints += 1; if micros.calcium >= minCalcium { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.iron >= minIron { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.magnesium >= minMagnesium { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.phosphorus >= minPhosphorus { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.potassium >= minPotassium { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.zinc >= minZinc { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.copper >= minCopper { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.manganese >= minManganese { presentMicronutrients += 1 }
        totalPossiblePoints += 1; if micros.selenium >= minSelenium { presentMicronutrients += 1 }
        
        // Sodium isn't counted as a positive (it's usually excessive)
        
        // Calculate percentage of meaningful micronutrients
        return Double(presentMicronutrients) / Double(totalPossiblePoints)
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
    
    // MARK: - Penalty Calculations
    
    /// Calculate penalty for high sodium content (0-1)
    private func calculateSodiumPenalty(micros: MicroData) -> Double {
        // Reference values
        let sodiumDailyLimit: Double = 2300 // mg (upper limit)
        let mealSodiumIdeal: Double = 600 // mg per meal
        
        // No penalty if sodium is below ideal per meal
        if micros.sodium <= mealSodiumIdeal {
            return 0.0
        }
        
        // Calculate penalty based on how much it exceeds ideal
        let excessSodium = micros.sodium - mealSodiumIdeal
        let maxExcessSodium = sodiumDailyLimit - mealSodiumIdeal
        
        // Penalty scales from 0 to 1 as sodium approaches the daily limit
        let penalty = min(1.0, excessSodium / maxExcessSodium)
        return penalty
    }
    
    /// Detect if a meal contains processed foods (0-1 penalty)
    private func calculateProcessedFoodPenalty(foods: [FoodItem]) -> Double {
        var processedFoodScore = 0.0
        
        // Check for common processed food types
        for food in foods {
            let name = food.name.lowercased()
            
            // Fast food and highly processed items (highest penalty)
            if name.contains("burger") || name.contains("fast food") || 
               name.contains("chicken nugget") || name.contains("soda") ||
               name.contains("french fries") || name.contains("pizza") ||
               name.contains("chicken sandwich") || name.contains("hot dog") {
                processedFoodScore += 0.8
            }
            // Moderately processed items (medium penalty)
            else if name.contains("fried") || name.contains("chips") ||
                    name.contains("crackers") || name.contains("cereal") ||
                    name.contains("white bread") || name.contains("deli meat") {
                processedFoodScore += 0.5
            }
            // Minimally processed items (small penalty)
            else if name.contains("bread") || name.contains("cheese") ||
                    name.contains("pasta") || name.contains("sauce") ||
                    name.contains("dressing") {
                processedFoodScore += 0.2
            }
        }
        
        // Cap the penalty at 1.0
        return min(1.0, processedFoodScore / Double(foods.count))
    }
    
    /// Calculate penalty for high saturated fat (0-1)
    private func calculateSaturatedFatPenalty(foods: [FoodItem]) -> Double {
        // Using standard fat values as a proxy since we don't have direct saturated fat data
        let totalFat = foods.reduce(0.0) { $0 + $1.macros.fat }
        let totalCalories = foods.reduce(0) { $0 + $1.calories }
        
        // Estimate saturated fat based on food types
        var estimatedSaturatedFat = 0.0
        for food in foods {
            let name = food.name.lowercased()
            
            // High saturated fat foods
            if name.contains("burger") || name.contains("cheese") || 
               name.contains("butter") || name.contains("bacon") ||
               name.contains("sausage") || name.contains("pizza") {
                estimatedSaturatedFat += food.macros.fat * 0.5 // Estimate 50% of fat is saturated
            } else {
                estimatedSaturatedFat += food.macros.fat * 0.3 // Estimate 30% of fat is saturated
            }
        }
        
        // Guard against division by zero
        guard totalCalories > 0 else { return 0 }
        
        // Calculate percentage of calories from saturated fat
        let saturatedFatCalories = estimatedSaturatedFat * 9 // 9 calories per gram of fat
        let saturatedFatPercentage = saturatedFatCalories / Double(totalCalories)
        
        // No penalty if saturated fat is less than 5% of calories
        if saturatedFatPercentage <= 0.05 {
            return 0.0
        }
        
        // Maximum penalty if saturated fat is more than 15% of calories
        if saturatedFatPercentage >= 0.15 {
            return 1.0
        }
        
        // Scale penalty between 0 and 1 for saturated fat between 5% and 15%
        return (saturatedFatPercentage - 0.05) / 0.10
    }
    
    /// Calculate penalty for refined carbohydrates (0-1)
    private func calculateRefinedCarbsPenalty(foods: [FoodItem]) -> Double {
        let totalCarbs = foods.reduce(0.0) { $0 + $1.macros.carbs }
        let totalFiber = foods.reduce(0.0) { $0 + $1.macros.fiber }
        
        // Guard against division by zero
        guard totalCarbs > 0 else { return 0 }
        
        // Calculate fiber-to-carb ratio (higher is better)
        let fiberToCarRatio = totalFiber / totalCarbs
        
        // Whole foods typically have higher fiber-to-carb ratios
        // No penalty if ratio is above 0.1 (10% fiber)
        if fiberToCarRatio >= 0.1 {
            return 0.0
        }
        
        // Maximum penalty if ratio is below 0.02 (2% fiber, highly refined)
        if fiberToCarRatio <= 0.02 {
            return 1.0
        }
        
        // Scale penalty between 0 and 1 for ratio between 0.02 and 0.1
        return (0.1 - fiberToCarRatio) / 0.08
    }
    
    /// Check if a meal contains processed foods
    private func isProcessedFood(_ foods: [FoodItem]) -> Bool {
        for food in foods {
            let name = food.name.lowercased()
            
            if name.contains("burger") || name.contains("fast food") || 
               name.contains("french fries") || name.contains("chicken nugget") ||
               name.contains("pizza") || name.contains("hot dog") ||
               name.contains("soda") || name.contains("chips") ||
               name.contains("fried") {
                return true
            }
        }
        return false
    }
}
