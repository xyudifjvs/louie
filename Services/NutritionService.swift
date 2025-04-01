//
//  NutritionService.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//
//  NutritionService.swift
//  Louie
//
//  Handles NutritionIX API integration

import Foundation
import UIKit
import SwiftUI

// Service-specific enums
public enum NutritionServiceInsightType: String, Codable {
    case positive
    case neutral
    case warning
}

/// A service for interacting with the Nutritionix API to get nutrition data
class NutritionService {
    static let shared = NutritionService()
    
    private init() {}
    
    /// Fetches nutrition information for food items identified by labels
    /// - Parameters:
    ///   - foodLabels: Array of food labels from Vision API
    ///   - completion: Completion handler with Result containing array of FoodItem or error
    func getNutritionInfo(for foodLabels: [LabelAnnotation], completion: @escaping (Result<[FoodItem], APIError>) -> Void) {
        // Log the labels we received
        print("Processing food labels: \(foodLabels.map { "\($0.description) (\(Int($0.score * 100))%)" }.joined(separator: ", "))")
        
        // Categorize labels by specificity
        var specificFoodLabels: [LabelAnnotation] = []
        var genericFoodLabels: [LabelAnnotation] = []
        
        for label in foodLabels {
            if isSpecificFood(label.description) {
                specificFoodLabels.append(label)
            } else {
                genericFoodLabels.append(label)
            }
        }
        
        // Process specific foods first, then try generic ones if needed
        if !specificFoodLabels.isEmpty {
            // Get the top 3 specific food labels
            let topSpecificLabels = Array(specificFoodLabels.prefix(3))
            processLabels(topSpecificLabels, currentIndex: 0, collectedFoods: [], completion: completion)
        } else if !genericFoodLabels.isEmpty {
            // If no specific foods, try to create combined queries from generic labels
            let combinedQuery = createCombinedFoodQuery(from: genericFoodLabels)
            
            // Try the combined query
            getNutritionData(for: combinedQuery) { result in
                switch result {
                case .success(let foods):
                    completion(.success(foods))
                case .failure(_):
                    // If combined query fails, fall back to processing each generic label
                    let topGenericLabels = Array(genericFoodLabels.prefix(5))
                    self.processLabels(topGenericLabels, currentIndex: 0, collectedFoods: [], completion: completion)
                }
            }
        } else {
            // No food labels found
            completion(.failure(.noNutritionData))
        }
    }
    
    /// Recursively process each food label to get nutrition data
    private func processLabels(_ labels: [LabelAnnotation], currentIndex: Int, collectedFoods: [FoodItem], completion: @escaping (Result<[FoodItem], APIError>) -> Void) {
        // Base case: we've processed all labels
        if currentIndex >= labels.count {
            if collectedFoods.isEmpty {
                completion(.failure(.noNutritionData))
            } else {
                completion(.success(collectedFoods))
            }
            return
        }
        
        // Get current label
        let label = labels[currentIndex]
        
        // Query the Nutritionix API
        getNutritionData(for: label.description) { result in
            switch result {
            case .success(let foods):
                // Combine new foods with previously collected ones
                let updatedFoods = collectedFoods + foods
                
                // If we have enough foods, return early
                if updatedFoods.count >= 3 {
                    completion(.success(updatedFoods))
                    return
                }
                
                // Process the next label
                self.processLabels(labels, currentIndex: currentIndex + 1, collectedFoods: updatedFoods, completion: completion)
                
            case .failure(_):
                // If this label fails, try the next one
                self.processLabels(labels, currentIndex: currentIndex + 1, collectedFoods: collectedFoods, completion: completion)
            }
        }
    }
    
    /// Check if a term represents a specific food rather than a generic category
    private func isSpecificFood(_ term: String) -> Bool {
        let genericTerms = ["food", "dish", "cuisine", "meal", "ingredient", "breakfast", "lunch", "dinner", 
                           "fast food", "fried food", "junk food", "restaurant food"]
        
        let lowercasedTerm = term.lowercased()
        
        // Check if it contains a generic term
        for generic in genericTerms {
            if lowercasedTerm == generic {
                return false
            }
        }
        
        return true
    }
    
    /// Create a combined food query from multiple generic labels
    private func createCombinedFoodQuery(from labels: [LabelAnnotation]) -> String {
        // Extract common food types from labels
        var foodTypes: [String] = []
        
        // Look for specific patterns in generic labels
        let fastFood = labels.contains { $0.description.lowercased().contains("fast food") }
        let friedFood = labels.contains { $0.description.lowercased().contains("fried") }
        
        if fastFood && friedFood {
            return "fast food fried chicken sandwich with fries"
        } else if fastFood {
            return "hamburger with fries"
        } else if friedFood {
            return "fried chicken"
        }
        
        // Extract any potential food types
        for label in labels {
            let desc = label.description.lowercased()
            
            if desc.contains("breakfast") {
                foodTypes.append("breakfast")
            } else if desc.contains("lunch") {
                foodTypes.append("lunch")
            } else if desc.contains("dinner") {
                foodTypes.append("dinner")
            } else if desc.contains("dessert") {
                foodTypes.append("dessert")
            } else if desc.contains("snack") {
                foodTypes.append("snack")
            }
        }
        
        // If we found specific meal types, use those
        if !foodTypes.isEmpty {
            let type = foodTypes.first!
            
            switch type {
            case "breakfast":
                return "eggs and toast breakfast"
            case "lunch":
                return "sandwich lunch"
            case "dinner":
                return "chicken dinner"
            case "dessert":
                return "chocolate cake"
            case "snack":
                return "potato chips"
            default:
                return "mixed meal"
            }
        }
        
        // Default generic meal if we couldn't determine anything specific
        return "mixed meal with chicken"
    }
    
    /// Gets nutrition data for a specific food query
    private func getNutritionData(for foodQuery: String, completion: @escaping (Result<[FoodItem], APIError>) -> Void) {
        // Create URL for the Nutritionix API
        guard let url = URL(string: APIConstants.nutritionixEndpoint) else {
            completion(.failure(.networkError(NSError(domain: "NutritionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add required headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(APIConstants.nutritionixAppID, forHTTPHeaderField: "x-app-id")
        request.addValue(APIConstants.nutritionixAPIKey, forHTTPHeaderField: "x-app-key")
        
        // Create request body
        let requestBody: [String: Any] = [
            "query": foodQuery,
            "num_servings": 1,
            "line_delimited": false,
            "use_raw_foods": false,
            "include_subrecipe": false,
            "timezone": "US/Eastern"
        ]
        
        // Serialize to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // Process the response
            do {
                let decoder = JSONDecoder()
                let nutritionResponse = try decoder.decode(NutritionResponse.self, from: data)
                
                // Check if we got any foods
                guard !nutritionResponse.foods.isEmpty else {
                    completion(.failure(.noNutritionData))
                    return
                }
                
                // Convert to our app's FoodItem model
                let foodItems = nutritionResponse.foods.map { self.convertToFoodItem($0) }
                completion(.success(foodItems))
                
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    /// Converts Nutritionix food model to our app's FoodItem model
    private func convertToFoodItem(_ nutritionixFood: NutritionixFood) -> FoodItem {
        // Create macronutrient data
        let macros = MacroData(
            protein: nutritionixFood.nfProtein,
            carbs: nutritionixFood.nfTotalCarbohydrate,
            fat: nutritionixFood.nfTotalFat,
            fiber: nutritionixFood.nfDietaryFiber,
            sugar: nutritionixFood.nfSugars
        )
        
        // Create micronutrient data - extract what we can from full_nutrients
        var micros = MicroData()
        
        if let nutrients = nutritionixFood.full_nutrients {
            // Map nutrient IDs to our MicroData properties
            // This is a mapping of Nutritionix attr_id to our micronutrient properties
            for nutrient in nutrients {
                switch nutrient.attr_id {
                // Vitamins
                case 320: micros.vitaminA = nutrient.value
                case 401: micros.vitaminC = nutrient.value
                case 328: micros.vitaminD = nutrient.value
                case 323: micros.vitaminE = nutrient.value
                case 430: micros.vitaminK = nutrient.value
                case 404: micros.thiamin = nutrient.value
                case 405: micros.riboflavin = nutrient.value
                case 406: micros.niacin = nutrient.value
                case 415: micros.vitaminB6 = nutrient.value
                case 417: micros.folate = nutrient.value
                case 418: micros.vitaminB12 = nutrient.value
                    
                // Minerals
                case 301: micros.calcium = nutrient.value
                case 303: micros.iron = nutrient.value
                case 304: micros.magnesium = nutrient.value
                case 305: micros.phosphorus = nutrient.value
                case 306: micros.potassium = nutrient.value
                case 307: micros.sodium = nutrient.value
                case 309: micros.zinc = nutrient.value
                case 312: micros.copper = nutrient.value
                case 315: micros.manganese = nutrient.value
                case 317: micros.selenium = nutrient.value
                default: break
                }
            }
        }
        
        // Set values we know directly from the top-level properties
        micros.potassium = nutritionixFood.nfPotassium
        if let phosphorus = nutritionixFood.nfP {
            micros.phosphorus = phosphorus
        }
        
        // Create amount string from serving info
        let amount = "\(nutritionixFood.servingQty) \(nutritionixFood.servingUnit) (\(Int(nutritionixFood.servingWeightGrams))g)"
        
        // Create the FoodItem
        return FoodItem(
            name: nutritionixFood.foodName.capitalized,
            amount: amount,
            servingAmount: nutritionixFood.servingWeightGrams,
            calories: Int(nutritionixFood.nfCalories),
            category: determineFoodCategory(foodName: nutritionixFood.foodName),
            macros: macros,
            micros: micros
        )
    }
    
    /// Determine food category based on food name
    private func determineFoodCategory(foodName: String) -> FoodCategory {
        let name = foodName.lowercased()
        
        // Proteins
        if name.contains("chicken") || name.contains("beef") || name.contains("pork") || 
           name.contains("fish") || name.contains("tofu") || name.contains("egg") || 
           name.contains("meat") || name.contains("turkey") || name.contains("lamb") || 
           name.contains("seafood") || name.contains("shrimp") || name.contains("bean") || 
           name.contains("lentil") || name.contains("protein") {
            return .proteins
        }
        
        // Vegetables
        if name.contains("broccoli") || name.contains("spinach") || name.contains("kale") || 
           name.contains("carrot") || name.contains("lettuce") || name.contains("potato") || 
           name.contains("tomato") || name.contains("salad") || name.contains("vegetable") || 
           name.contains("onion") || name.contains("garlic") || name.contains("pepper") || 
           name.contains("cucumber") || name.contains("zucchini") {
            return .vegetables
        }
        
        // Carbs
        if name.contains("rice") || name.contains("bread") || name.contains("pasta") || 
           name.contains("noodle") || name.contains("cereal") || name.contains("grain") || 
           name.contains("oat") || name.contains("wheat") || name.contains("barley") || 
           name.contains("corn") || name.contains("cracker") || name.contains("chip") || 
           name.contains("cookie") || name.contains("cake") || name.contains("sweet") || 
           name.contains("sugar") || name.contains("dessert") || name.contains("pastry") {
            return .carbs
        }
        
        // Default to others
        return .others
    }
    
    /// Lookup nutrition information for a single food item (useful for manually added items)
    /// - Parameters:
    ///   - foodName: The name of the food to look up
    ///   - completion: Completion handler with Result containing the FoodItem or error
    func lookupSingleFoodItem(foodName: String, completion: @escaping (Result<FoodItem, APIError>) -> Void) {
        // Log the query
        print("Looking up nutrition data for: \(foodName)")
        
        // Call the nutrition API
        getNutritionData(for: foodName) { result in
            switch result {
            case .success(let foodItems):
                if let firstItem = foodItems.first {
                    // Return the first item found
                    completion(.success(firstItem))
                } else {
                    // No data found
                    completion(.failure(.noNutritionData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Process multiple food labels to get the best nutrition data
    public func processDetectedFoods(_ detectedLabels: [LabelAnnotation], completion: @escaping (Result<[FoodItem], APIError>) -> Void) {
        // Implementation remains the same...
    }
    
    /// Returns a list of nutrition insights for the specified food items
    public func getNutritionalInsights(for foodLabels: [String]) -> [NutritionInsight] {
        // This would normally call an AI service
        // For now, use placeholder insights
        let insights = generatePlaceholderInsights(for: foodLabels)
        
        // Convert service insights to app-wide format
        return insights.map { convertToAppInsight($0) }
    }
    
    // Convert from service-specific insights to app-wide insights
    private func convertToAppInsight(_ serviceInsight: ServiceInsight) -> NutritionInsight {
        let insightType: NutritionInsight.InsightType
        
        switch serviceInsight.insightType {
        case .positive:
            insightType = .positive
        case .neutral:
            insightType = .neutral
        case .warning:
            insightType = .negative
        }
        
        return NutritionInsight(
            title: serviceInsight.insightText,
            description: serviceInsight.detail ?? "",
            icon: iconForInsightType(insightType),
            type: insightType
        )
    }
    
    private func iconForInsightType(_ type: NutritionInsight.InsightType) -> String {
        switch type {
        case .positive:
            return "checkmark.circle"
        case .negative:
            return "exclamationmark.triangle"
        case .neutral:
            return "info.circle"
        case .suggestion:
            return "lightbulb"
        }
    }
    
    // Generate placeholder insights for development/testing
    private struct ServiceInsight {
        let insightText: String
        let insightType: NutritionServiceInsightType
        let detail: String?
    }

    private func generatePlaceholderInsights(for foodLabels: [String]) -> [ServiceInsight] {
        var insights: [ServiceInsight] = []
        
        // Get unique lowercase food labels
        let uniqueFoodLabels = Set(foodLabels.map { $0.lowercased() })
        
        // Category-based insights
        let proteinSources = uniqueFoodLabels.filter { label in
            ["egg", "eggs", "chicken", "beef", "salmon", "tuna", "tofu", "beans", "lentils", "fish", "pork", "meat", "turkey", "shrimp", "steak"].contains { label.contains($0) }
        }
        
        let vegetables = uniqueFoodLabels.filter { label in
            ["broccoli", "spinach", "kale", "lettuce", "carrot", "carrots", "tomato", "tomatoes", "cucumber", "pepper", "peppers", "onion", "garlic", "asparagus", "zucchini", "eggplant", "cauliflower", "salad", "vegetables", "vegetable"].contains { label.contains($0) }
        }
        
        let fruits = uniqueFoodLabels.filter { label in
            ["apple", "banana", "orange", "berries", "strawberry", "strawberries", "blueberry", "blueberries", "raspberry", "raspberries", "grape", "grapes", "pineapple", "watermelon", "melon", "kiwi", "peach", "mango", "avocado", "fruit", "fruits"].contains { label.contains($0) }
        }
        
        let wholegrains = uniqueFoodLabels.filter { label in
            ["oats", "quinoa", "brown rice", "whole grain", "whole wheat", "whole bread"].contains { label.contains($0) }
        }
        
        let refinedCarbs = uniqueFoodLabels.filter { label in
            ["white bread", "pasta", "white rice", "noodles", "pastry", "cake", "cookie", "cookies", "donut", "bagel", "croissant", "bread"].contains { label.contains($0) }
        }
        
        let fastFood = uniqueFoodLabels.filter { label in
            ["burger", "pizza", "fries", "french fries", "hot dog", "hotdog", "fried chicken", "nachos", "taco", "burrito", "fast food", "chicken nuggets", "mcdonalds", "burger king", "wendys", "kfc", "popeyes", "taco bell", "subway"].contains { label.contains($0) }
        }
        
        let dairy = uniqueFoodLabels.filter { label in
            ["milk", "cheese", "yogurt", "butter", "cream", "ice cream", "dairy"].contains { label.contains($0) }
        }
        
        // Add protein insights
        if !proteinSources.isEmpty {
            insights.append(ServiceInsight(
                insightText: "Good protein sources",
                insightType: .positive,
                detail: proteinSources.joined(separator: ", ")
            ))
        }
        
        // Add vegetable insights
        if !vegetables.isEmpty {
            insights.append(ServiceInsight(
                insightText: "Nutrient-rich vegetables",
                insightType: .positive,
                detail: vegetables.joined(separator: ", ")
            ))
        }
        
        // Add fruit insights
        if !fruits.isEmpty {
            insights.append(ServiceInsight(
                insightText: "Vitamin-rich fruits",
                insightType: .positive,
                detail: fruits.joined(separator: ", ")
            ))
        }
        
        // Add whole grain insights
        if !wholegrains.isEmpty {
            insights.append(ServiceInsight(
                insightText: "Fiber-rich whole grains",
                insightType: .positive,
                detail: wholegrains.joined(separator: ", ")
            ))
        }
        
        // Add refined carb insights
        if !refinedCarbs.isEmpty {
            insights.append(ServiceInsight(
                insightText: "Refined carbohydrates",
                insightType: .warning,
                detail: refinedCarbs.joined(separator: ", ")
            ))
        }
        
        // Add fast food insights
        if !fastFood.isEmpty {
            insights.append(ServiceInsight(
                insightText: "Processed fast food",
                insightType: .warning,
                detail: fastFood.joined(separator: ", ")
            ))
        }
        
        // Add dairy insights
        if !dairy.isEmpty {
            let dairyInsightText = "Contains dairy"
            insights.append(ServiceInsight(
                insightText: dairyInsightText,
                insightType: .neutral,
                detail: dairy.joined(separator: ", ")
            ))
        }
        
        // Check for balanced meal
        if !vegetables.isEmpty && !proteinSources.isEmpty && (!wholegrains.isEmpty || !fruits.isEmpty) {
            insights.append(ServiceInsight(
                insightText: "Well-balanced meal",
                insightType: .positive,
                detail: nil // Explicitly nil
            ))
        }
        
        // If no insights were generated, provide a generic one
        if insights.isEmpty {
            insights.append(ServiceInsight(
                insightText: "Limited nutritional data",
                insightType: .neutral,
                detail: "Couldn't identify specific nutrition patterns"
            ))
        }
        
        // Remove duplicates
        var uniqueInsights: [ServiceInsight] = []
        var seen = Set<String>()
        
        for insight in insights {
            if !seen.contains(insight.insightText) {
                uniqueInsights.append(insight)
                seen.insert(insight.insightText)
            }
        }
        
        return uniqueInsights
    }
}
