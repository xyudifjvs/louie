//
//  NutritionTypes.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//
//
//  NutritionTypes.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI
import CloudKit

// MARK: - Date Display Mode
enum DateDisplayMode {
    case timeOfDay
    case dayOfWeek
}

// MARK: - Food Label Annotation
public struct FoodLabelAnnotation: Identifiable, Codable {
    public var id = UUID()
    public var description: String
    public var confidence: Double
    
    public init(description: String, confidence: Double = 0.0) {
        self.description = description
        self.confidence = confidence
    }
}

// MARK: - Nutrition Insights
public struct NutritionInsight: Identifiable {
    public var id = UUID()
    public var title: String
    public var description: String
    public var icon: String
    public var type: InsightType
    
    public init(title: String, description: String, icon: String, type: InsightType) {
        self.title = title
        self.description = description
        self.icon = icon
        self.type = type
    }
    
    public enum InsightType {
        case positive
        case negative
        case neutral
        case suggestion
    }
}

// MARK: - Data Models
public enum FoodCategory: String, Codable, CaseIterable {
    case proteins = "Proteins"
    case vegetables = "Vegetables"
    case carbs = "Carbs"
    case others = "Others"
}

public struct FoodItem: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var amount: String
    public var servingAmount: Double // in grams
    public var calories: Int
    public var category: FoodCategory
    public var macros: MacroData
    public var micros: MicroData
    
    public init(id: UUID = UUID(), name: String, amount: String = "1 serving", servingAmount: Double = 100, calories: Int = 100, category: FoodCategory = .others, macros: MacroData = MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0), micros: MicroData = MicroData()) {
        self.id = id
        self.name = name
        self.amount = amount
        self.servingAmount = servingAmount
        self.calories = calories
        self.category = category
        self.macros = macros
        self.micros = micros
    }
}

public struct MealEntry: Identifiable, Codable {
    public var id = UUID()
    public var timestamp: Date
    public var imageData: Data?
    public var imageURL: String?
    public var foods: [FoodItem]
    public var nutritionScore: Int
    public var macronutrients: MacroData
    public var micronutrients: MicroData
    public var userNotes: String?
    public var isManuallyAdjusted: Bool
    
    // CloudKit record ID for syncing
    public var recordID: CKRecord.ID?
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), imageData: Data? = nil, imageURL: String? = nil, foods: [FoodItem] = [], nutritionScore: Int = 0, macronutrients: MacroData = MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0), micronutrients: MicroData = MicroData(), userNotes: String? = nil, isManuallyAdjusted: Bool = false, recordID: CKRecord.ID? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.imageData = imageData
        self.imageURL = imageURL
        self.foods = foods
        self.nutritionScore = nutritionScore
        self.macronutrients = macronutrients
        self.micronutrients = micronutrients
        self.userNotes = userNotes
        self.isManuallyAdjusted = isManuallyAdjusted
        self.recordID = recordID
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, imageURL, foods, nutritionScore, macronutrients, micronutrients, userNotes, isManuallyAdjusted
        // Note: imageData and recordID are handled separately
    }
}

public struct MacroData: Codable {
    public var protein: Double // grams
    public var carbs: Double // grams
    public var fat: Double // grams
    public var fiber: Double // grams
    public var sugar: Double // grams
    
    public init(protein: Double = 0, carbs: Double = 0, fat: Double = 0, fiber: Double = 0, sugar: Double = 0) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
    }
    
    public init() {
        self.init(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)
    }
    
    public var totalCalories: Int {
        return Int((protein * 4) + (carbs * 4) + (fat * 9))
    }
    
    // Calculates macronutrient balance score (0-100)
    public func calculateBalanceScore() -> Int {
        // Ideal macro ratios (approximate)
        let idealProteinPercentage: Double = 0.30
        let idealCarbPercentage: Double = 0.40
        let idealFatPercentage: Double = 0.30
        
        let totalGrams = protein + carbs + fat
        guard totalGrams > 0 else { return 0 }
        
        let proteinPercentage = protein / totalGrams
        let carbPercentage = carbs / totalGrams
        let fatPercentage = fat / totalGrams
        
        // Calculate deviation from ideal (lower is better)
        let proteinDeviation = abs(proteinPercentage - idealProteinPercentage)
        let carbDeviation = abs(carbPercentage - idealCarbPercentage)
        let fatDeviation = abs(fatPercentage - idealFatPercentage)
        
        // Calculate overall deviation (0-1 scale, where 0 is perfect)
        let totalDeviation = (proteinDeviation + carbDeviation + fatDeviation) / 3
        
        // Convert to 0-100 score (100 being perfect)
        return min(100, max(0, Int((1 - totalDeviation) * 100)))
    }
}

public struct MicroData: Codable {
    // Essential vitamins
    public var vitaminA: Double = 0 // μg
    public var vitaminC: Double = 0 // mg
    public var vitaminD: Double = 0 // μg
    public var vitaminE: Double = 0 // mg
    public var vitaminK: Double = 0 // μg
    public var thiamin: Double = 0 // mg
    public var riboflavin: Double = 0 // mg
    public var niacin: Double = 0 // mg
    public var vitaminB6: Double = 0 // mg
    public var folate: Double = 0 // μg
    public var vitaminB12: Double = 0 // μg
    
    // Essential minerals
    public var calcium: Double = 0 // mg
    public var iron: Double = 0 // mg
    public var magnesium: Double = 0 // mg
    public var phosphorus: Double = 0 // mg
    public var potassium: Double = 0 // mg
    public var sodium: Double = 0 // mg
    public var zinc: Double = 0 // mg
    public var copper: Double = 0 // mg
    public var manganese: Double = 0 // mg
    public var selenium: Double = 0 // μg
    
    public init() { }
    
    // Calculate diversity score based on how many micronutrients are present
    public func calculateDiversityScore() -> Int {
        var count = 0
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let value = child.value as? Double, value > 0 {
                count += 1
            }
        }
        
        // Score based on percentage of micronutrients present (out of 22 total)
        return min(100, Int((Double(count) / 22.0) * 100))
    }
}
