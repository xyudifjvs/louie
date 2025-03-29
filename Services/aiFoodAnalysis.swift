//
//  aiFoodAnalysis.swift
//  Louie
//
//  Created by Carson on 3/28/25.
//

import Foundation
import UIKit

/// Service responsible for coordinating the food analysis process
/// Combines Google Cloud Vision API for image analysis and NutritionIX API for nutrition data
class AIFoodAnalysisService {
    static let shared = AIFoodAnalysisService()
    
    private let visionService = VisionService.shared
    private let nutritionService = NutritionService.shared
    private let nutritionScoreCalculator = NutritionScoreCalculator.shared
    
    private init() {}
    
    /// Complete pipeline for analyzing food images and retrieving nutrition data
    /// - Parameters:
    ///   - image: The image containing food to analyze
    ///   - completion: Completion handler with Result containing a MealEntry or error
    func analyzeFoodImage(_ image: UIImage, completion: @escaping (Result<MealEntry, APIError>) -> Void) {
        // Step 1: Analyze image with Google Cloud Vision
        visionService.analyzeFood(image: image) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let foodLabels):
                // Log success and proceed to nutrition lookup
                print("Vision API success: Found \(foodLabels.count) labels")
                print("Top labels: \(foodLabels.prefix(3).map { "\($0.description) (\(Int($0.score * 100))%)" }.joined(separator: ", "))")
                
                // Step 2: Get nutrition data using labels from Vision API
                self.nutritionService.getNutritionInfo(for: foodLabels) { nutritionResult in
                    switch nutritionResult {
                    case .success(let foodItems):
                        // Log success
                        print("Nutrition API success: Found \(foodItems.count) food items")
                        
                        // Create image data for storage
                        let imageData = image.jpegData(compressionQuality: 0.7)
                        
                        // Step 3: Calculate nutrition score
                        let nutritionScore = self.nutritionScoreCalculator.calculateScore(for: foodItems)
                        
                        // Calculate combined macronutrients
                        let totalMacros = foodItems.reduce(MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)) { result, item in
                            MacroData(
                                protein: result.protein + item.macros.protein,
                                carbs: result.carbs + item.macros.carbs,
                                fat: result.fat + item.macros.fat,
                                fiber: result.fiber + item.macros.fiber,
                                sugar: result.sugar + item.macros.sugar
                            )
                        }
                        
                        // Combine micronutrients
                        var totalMicros = MicroData()
                        for item in foodItems {
                            totalMicros.vitaminA += item.micros.vitaminA
                            totalMicros.vitaminC += item.micros.vitaminC
                            totalMicros.vitaminD += item.micros.vitaminD
                            totalMicros.vitaminE += item.micros.vitaminE
                            totalMicros.vitaminK += item.micros.vitaminK
                            totalMicros.thiamin += item.micros.thiamin
                            totalMicros.riboflavin += item.micros.riboflavin
                            totalMicros.niacin += item.micros.niacin
                            totalMicros.vitaminB6 += item.micros.vitaminB6
                            totalMicros.folate += item.micros.folate
                            totalMicros.vitaminB12 += item.micros.vitaminB12
                            
                            totalMicros.calcium += item.micros.calcium
                            totalMicros.iron += item.micros.iron
                            totalMicros.magnesium += item.micros.magnesium
                            totalMicros.phosphorus += item.micros.phosphorus
                            totalMicros.potassium += item.micros.potassium
                            totalMicros.sodium += item.micros.sodium
                            totalMicros.zinc += item.micros.zinc
                            totalMicros.copper += item.micros.copper
                            totalMicros.manganese += item.micros.manganese
                            totalMicros.selenium += item.micros.selenium
                        }
                        
                        // Create meal entry
                        let mealEntry = MealEntry(
                            id: UUID(),
                            timestamp: Date(),
                            imageData: imageData,
                            imageURL: nil,
                            foods: foodItems,
                            nutritionScore: nutritionScore,
                            macronutrients: totalMacros,
                            micronutrients: totalMicros,
                            userNotes: nil,
                            isManuallyAdjusted: false
                        )
                        
                        // Generate recommendations (could be added to userNotes)
                        let recommendations = self.nutritionScoreCalculator.generateRecommendations(for: foodItems, score: nutritionScore)
                        print("Nutrition recommendations: \(recommendations.joined(separator: " "))")
                        
                        // Return successful meal entry
                        completion(.success(mealEntry))
                        
                    case .failure(let error):
                        print("Nutrition API error: \(error.description)")
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                print("Vision API error: \(error.description)")
                completion(.failure(error))
            }
        }
    }
    
    /// Creates a meal entry from food items and an image
    /// - Parameters:
    ///   - foodItems: Array of food items with nutrition data
    ///   - image: The original food image
    ///   - userNotes: Optional user notes for the meal
    ///   - isManuallyAdjusted: Whether this entry was manually adjusted by the user
    /// - Returns: A complete MealEntry object
    func createMealEntry(from foodItems: [FoodItem], image: UIImage?, userNotes: String? = nil, isManuallyAdjusted: Bool = false) -> MealEntry {
        // Create image data for storage if image is provided
        let imageData = image?.jpegData(compressionQuality: 0.7)
        
        // Calculate nutrition score
        let nutritionScore = nutritionScoreCalculator.calculateScore(for: foodItems)
        
        // Calculate combined macronutrients
        let totalMacros = foodItems.reduce(MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)) { result, item in
            MacroData(
                protein: result.protein + item.macros.protein,
                carbs: result.carbs + item.macros.carbs,
                fat: result.fat + item.macros.fat,
                fiber: result.fiber + item.macros.fiber,
                sugar: result.sugar + item.macros.sugar
            )
        }
        
        // Combine micronutrients
        var totalMicros = MicroData()
        for item in foodItems {
            totalMicros.vitaminA += item.micros.vitaminA
            totalMicros.vitaminC += item.micros.vitaminC
            totalMicros.vitaminD += item.micros.vitaminD
            totalMicros.vitaminE += item.micros.vitaminE
            totalMicros.vitaminK += item.micros.vitaminK
            totalMicros.thiamin += item.micros.thiamin
            totalMicros.riboflavin += item.micros.riboflavin
            totalMicros.niacin += item.micros.niacin
            totalMicros.vitaminB6 += item.micros.vitaminB6
            totalMicros.folate += item.micros.folate
            totalMicros.vitaminB12 += item.micros.vitaminB12
            
            totalMicros.calcium += item.micros.calcium
            totalMicros.iron += item.micros.iron
            totalMicros.magnesium += item.micros.magnesium
            totalMicros.phosphorus += item.micros.phosphorus
            totalMicros.potassium += item.micros.potassium
            totalMicros.sodium += item.micros.sodium
            totalMicros.zinc += item.micros.zinc
            totalMicros.copper += item.micros.copper
            totalMicros.manganese += item.micros.manganese
            totalMicros.selenium += item.micros.selenium
        }
        
        // Create meal entry
        let mealEntry = MealEntry(
            id: UUID(),
            timestamp: Date(),
            imageData: imageData,
            imageURL: nil,
            foods: foodItems,
            nutritionScore: nutritionScore,
            macronutrients: totalMacros,
            micronutrients: totalMicros,
            userNotes: userNotes,
            isManuallyAdjusted: isManuallyAdjusted
        )
        
        // Generate recommendations (could be added to userNotes)
        let recommendations = nutritionScoreCalculator.generateRecommendations(for: foodItems, score: nutritionScore)
        print("Nutrition recommendations: \(recommendations.joined(separator: " "))")
        
        return mealEntry
    }
} 
