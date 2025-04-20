//
//  NutritionService.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//
//  NutritionService.swift
//  Louie
//
//  Handles NutritionIX API integration (Partially Deprecated)

import Foundation
import UIKit
import SwiftUI

// Service-specific enums (Potentially keep if insights are kept)
public enum NutritionServiceInsightType: String, Codable {
    case positive
    case neutral
    case warning
}

// NOTE: This service primarily handled NutritionIX integration, which is being
// replaced by OpenAIService for image analysis. Some functions remain as placeholders
// or for potential future refactoring (e.g., text lookup, insights).

/// A service originally for interacting with the Nutritionix API.
/// Most core functionality related to image analysis is DEPRECATED.
class NutritionService {
    static let shared = NutritionService()

    private init() {}

    // MARK: - DEPRECATED / REMOVED NutritionIX Functions -

    // func getNutritionInfo(...) - Removed
    // private func processLabels(...) - Removed
    // private func isSpecificFood(...) - Removed
    // private func createCombinedFoodQuery(...) - Removed
    // private func getNutritionData(...) - Removed (Core NutritionIX call)
    // private func convertToFoodItem(...) - Removed
    // private func determineFoodCategory(...) - Removed
    // public func processDetectedFoods(...) - Removed

    // MARK: - Potentially Reusable / Refactorable Functions -

    /// Lookup nutrition information for a single food item (useful for manually added items)
    /// - Parameters:
    ///   - foodName: The name of the food to look up
    ///   - completion: Completion handler with Result containing the FoodItem or error
    ///   - NOTE: This function is currently non-functional pending refactoring.
    func lookupSingleFoodItem(foodName: String, completion: @escaping (Result<FoodItem, APIError>) -> Void) {
        // --- Entire function body replaced --- 
        print("Looking up nutrition data for: \(foodName)")
        print("WARNING: lookupSingleFoodItem is currently non-functional and does not call any API.")
        DispatchQueue.main.async {
            completion(.failure(.serverError("lookupSingleFoodItem not implemented post-OpenAI migration")))
        }
        // --- End of replaced body ---
    }

    /// Returns a list of nutrition insights for the specified food items
    /// - NOTE: This uses placeholder logic and might be replaced by insights from OpenAI.
    public func getNutritionalInsights(for foodLabels: [String]) -> [NutritionInsight] {
        // This would normally call an AI service or use more sophisticated logic.
        print("Generating placeholder nutritional insights.")
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
            insightType = .negative // Map warning to negative for the app model
        }

        return NutritionInsight(
            title: serviceInsight.insightText,
            description: serviceInsight.detail ?? "",
            icon: iconForInsightType(insightType),
            type: insightType
        )
    }

    // Helper to get SFSymbol name for insight type
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

    // Internal struct for placeholder insights
    private struct ServiceInsight {
        let insightText: String
        let insightType: NutritionServiceInsightType
        let detail: String?
    }

    // Generate placeholder insights for development/testing
    // (This logic can remain as is for now)
    private func generatePlaceholderInsights(for foodLabels: [String]) -> [ServiceInsight] {
        var insights: [ServiceInsight] = []
        let uniqueFoodLabels = Set(foodLabels.map { $0.lowercased() })

        // Category-based insights (Simplified example - keeping existing complex logic)
        let proteinSources = uniqueFoodLabels.filter { label in ["egg", "chicken", "beef", "salmon", "tuna", "tofu", "beans"].contains { label.contains($0) } }
        let vegetables = uniqueFoodLabels.filter { label in ["broccoli", "spinach", "kale", "carrot", "salad"].contains { label.contains($0) } }
        let fruits = uniqueFoodLabels.filter { label in ["apple", "banana", "orange", "berries"].contains { label.contains($0) } }
        let wholegrains = uniqueFoodLabels.filter { label in ["oats", "quinoa", "brown rice"].contains { label.contains($0) } }
        let refinedCarbs = uniqueFoodLabels.filter { label in ["white bread", "pasta", "white rice", "cake", "cookie"].contains { label.contains($0) } }
        let fastFood = uniqueFoodLabels.filter { label in ["burger", "pizza", "fries", "fried chicken"].contains { label.contains($0) } }
        let dairy = uniqueFoodLabels.filter { label in ["milk", "cheese", "yogurt"].contains { label.contains($0) } }

        if !proteinSources.isEmpty { insights.append(ServiceInsight(insightText: "Good protein sources", insightType: .positive, detail: proteinSources.joined(separator: ", "))) }
        if !vegetables.isEmpty { insights.append(ServiceInsight(insightText: "Nutrient-rich vegetables", insightType: .positive, detail: vegetables.joined(separator: ", "))) }
        if !fruits.isEmpty { insights.append(ServiceInsight(insightText: "Vitamin-rich fruits", insightType: .positive, detail: fruits.joined(separator: ", "))) }
        if !wholegrains.isEmpty { insights.append(ServiceInsight(insightText: "Fiber-rich whole grains", insightType: .positive, detail: wholegrains.joined(separator: ", "))) }
        if !refinedCarbs.isEmpty { insights.append(ServiceInsight(insightText: "Refined carbohydrates", insightType: .warning, detail: refinedCarbs.joined(separator: ", "))) }
        if !fastFood.isEmpty { insights.append(ServiceInsight(insightText: "Processed fast food", insightType: .warning, detail: fastFood.joined(separator: ", "))) }
        if !dairy.isEmpty { insights.append(ServiceInsight(insightText: "Contains dairy", insightType: .neutral, detail: dairy.joined(separator: ", "))) }

        if !vegetables.isEmpty && !proteinSources.isEmpty && (!wholegrains.isEmpty || !fruits.isEmpty) {
            insights.append(ServiceInsight(insightText: "Well-balanced meal", insightType: .positive, detail: nil))
        }

        if insights.isEmpty { insights.append(ServiceInsight(insightText: "Limited nutritional data", insightType: .neutral, detail: "Couldn't identify specific nutrition patterns")) }

        // Remove duplicates (same logic)
        var uniqueInsights: [ServiceInsight] = []
        var seen = Set<String>()
        for insight in insights { if !seen.contains(insight.insightText) { uniqueInsights.append(insight); seen.insert(insight.insightText) } }
        return uniqueInsights
    }
}
