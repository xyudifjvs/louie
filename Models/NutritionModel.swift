//
//  NutritionModel.swift
//  Louie
//
//  Created by Carson on 3/28/25.
//

import SwiftUI
import CloudKit
// Ensure we can access any utilities for Color+Hex
import SwiftUI

// MARK: - Data Models
struct MealEntry: Identifiable, Codable {
    var id = UUID()
    var timestamp: Date
    var imageData: Data?
    var imageURL: String?
    var foods: [FoodItem]
    var nutritionScore: Int
    var macronutrients: MacroData
    var micronutrients: MicroData
    var userNotes: String?
    var isManuallyAdjusted: Bool
    
    // CloudKit record ID for syncing
    var recordID: CKRecord.ID?
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, imageURL, foods, nutritionScore, macronutrients, micronutrients, userNotes, isManuallyAdjusted
        // Note: imageData and recordID are handled separately
    }
}

struct FoodItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: String
    var calories: Int
    var macros: MacroData
    var micros: MicroData
}

struct MacroData: Codable {
    var protein: Double // grams
    var carbs: Double // grams
    var fat: Double // grams
    var fiber: Double // grams
    var sugar: Double // grams
    
    var totalCalories: Int {
        return Int((protein * 4) + (carbs * 4) + (fat * 9))
    }
    
    // Calculates macronutrient balance score (0-100)
    func calculateBalanceScore() -> Int {
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

struct MicroData: Codable {
    // Essential vitamins
    var vitaminA: Double = 0 // μg
    var vitaminC: Double = 0 // mg
    var vitaminD: Double = 0 // μg
    var vitaminE: Double = 0 // mg
    var vitaminK: Double = 0 // μg
    var thiamin: Double = 0 // mg
    var riboflavin: Double = 0 // mg
    var niacin: Double = 0 // mg
    var vitaminB6: Double = 0 // mg
    var folate: Double = 0 // μg
    var vitaminB12: Double = 0 // μg
    
    // Essential minerals
    var calcium: Double = 0 // mg
    var iron: Double = 0 // mg
    var magnesium: Double = 0 // mg
    var phosphorus: Double = 0 // mg
    var potassium: Double = 0 // mg
    var sodium: Double = 0 // mg
    var zinc: Double = 0 // mg
    var copper: Double = 0 // mg
    var manganese: Double = 0 // mg
    var selenium: Double = 0 // μg
    
    // Calculate diversity score based on how many micronutrients are present
    func calculateDiversityScore() -> Int {
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

// MARK: - ViewModel for Nutrition
class NutritionViewModel: ObservableObject {
    @Published var meals: [MealEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let cloudKitManager = CloudKitManager.shared
    private let recordType = "MealEntry"
    
    // Calculate nutrition score based on multiple factors
    func calculateNutritionScore(foods: [FoodItem]) -> Int {
        guard !foods.isEmpty else { return 0 }
        
        // Combine all macros and micros for the meal
        let combinedMacros = foods.reduce(MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)) { result, food in
            return MacroData(
                protein: result.protein + food.macros.protein,
                carbs: result.carbs + food.macros.carbs,
                fat: result.fat + food.macros.fat,
                fiber: result.fiber + food.macros.fiber,
                sugar: result.sugar + food.macros.sugar
            )
        }
        
        // Accumulate all micronutrients
        var combinedMicros = MicroData()
        for food in foods {
            let mirror = Mirror(reflecting: food.micros)
            let resultMirror = Mirror(reflecting: combinedMicros)
            
            for (childIndex, child) in mirror.children.enumerated() {
                if let value = child.value as? Double {
                    let resultChild = resultMirror.children[resultMirror.children.index(resultMirror.children.startIndex, offsetBy: childIndex)]
                    if let resultValue = resultChild.value as? Double, let propertyName = resultChild.label {
                        // This is a simplification - in a real app we would use a more robust approach
                        let newValue = resultValue + value
                        // Using KeyPath would be better but this is a workaround
                        if propertyName == "vitaminA" { combinedMicros.vitaminA += value }
                        else if propertyName == "vitaminC" { combinedMicros.vitaminC += value }
                        else if propertyName == "vitaminD" { combinedMicros.vitaminD += value }
                        // ... add other properties as needed
                    }
                }
            }
        }
        
        // Factors for nutrition score:
        // 1. Macro balance (33%)
        let macroBalanceScore = combinedMacros.calculateBalanceScore()
        
        // 2. Micronutrient diversity (25%)
        let microDiversityScore = combinedMicros.calculateDiversityScore()
        
        // 3. Portion size appropriateness (20%)
        // Simplified calculation based on calories (assumes ~600 calories per meal is appropriate)
        let calories = combinedMacros.totalCalories
        let portionScore = 100 - min(100, Int(abs(Double(calories - 600)) / 6.0))
        
        // 4. Processing level (12%) - This would typically come from the AI service
        // For now we'll use a placeholder
        let processingScore = 70 // Placeholder
        
        // 5. Color variety (10%) - This would typically come from the AI service
        // For now we'll use a placeholder
        let colorScore = 80 // Placeholder
        
        // Calculate weighted average
        let weightedScore = (macroBalanceScore * 33 +
                           microDiversityScore * 25 +
                           portionScore * 20 +
                           processingScore * 12 +
                           colorScore * 10) / 100
        
        return weightedScore
    }
    
    // MARK: - CloudKit Operations
    
    func saveMeal(_ meal: MealEntry) {
        isLoading = true
        errorMessage = nil
        
        let record = CKRecord(recordType: recordType)
        
        // Set record values
        record["timestamp"] = meal.timestamp
        record["foods"] = try? JSONEncoder().encode(meal.foods)
        record["nutritionScore"] = meal.nutritionScore
        record["macronutrients"] = try? JSONEncoder().encode(meal.macronutrients)
        record["micronutrients"] = try? JSONEncoder().encode(meal.micronutrients)
        record["userNotes"] = meal.userNotes
        record["isManuallyAdjusted"] = meal.isManuallyAdjusted
        
        if let imageData = meal.imageData {
            let imageAsset = CKAsset(fileURL: saveImageToTempDirectory(imageData: imageData))
            record["mealImage"] = imageAsset
        }
        
        cloudKitManager.saveRecord(record) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let savedRecord):
                    var savedMeal = meal
                    savedMeal.recordID = savedRecord.recordID
                    self?.meals.append(savedMeal)
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to save meal: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchMeals() {
        isLoading = true
        errorMessage = nil
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        cloudKitManager.performQuery(query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let records):
                    self?.meals = records.compactMap { record in
                        guard let timestamp = record["timestamp"] as? Date,
                              let nutritionScore = record["nutritionScore"] as? Int else {
                            return nil
                        }
                        
                        // Parse foods
                        var foods: [FoodItem] = []
                        if let foodsData = record["foods"] as? Data {
                            foods = (try? JSONDecoder().decode([FoodItem].self, from: foodsData)) ?? []
                        }
                        
                        // Parse macronutrients
                        var macronutrients = MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)
                        if let macroData = record["macronutrients"] as? Data {
                            macronutrients = (try? JSONDecoder().decode(MacroData.self, from: macroData)) ?? macronutrients
                        }
                        
                        // Parse micronutrients
                        var micronutrients = MicroData()
                        if let microData = record["micronutrients"] as? Data {
                            micronutrients = (try? JSONDecoder().decode(MicroData.self, from: microData)) ?? micronutrients
                        }
                        
                        // Get image if available
                        var imageData: Data? = nil
                        var imageURL: String? = nil
                        if let asset = record["mealImage"] as? CKAsset, let fileURL = asset.fileURL {
                            imageData = try? Data(contentsOf: fileURL)
                            imageURL = fileURL.absoluteString
                        }
                        
                        return MealEntry(
                            id: UUID(),
                            timestamp: timestamp,
                            imageData: imageData,
                            imageURL: imageURL,
                            foods: foods,
                            nutritionScore: nutritionScore,
                            macronutrients: macronutrients,
                            micronutrients: micronutrients,
                            userNotes: record["userNotes"] as? String,
                            isManuallyAdjusted: record["isManuallyAdjusted"] as? Bool ?? false,
                            recordID: record.recordID
                        )
                    }
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch meals: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveImageToTempDirectory(imageData: Data) -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        try? imageData.write(to: fileURL)
        return fileURL
    }
}

// MARK: - CloudKit Manager Extension
extension CloudKitManager {
    func saveRecord(_ record: CKRecord, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let database = CKContainer.default().privateCloudDatabase
        
        database.save(record) { record, error in
            if let error = error {
                completion(.failure(error))
            } else if let record = record {
                completion(.success(record))
            }
        }
    }
    
    func performQuery(_ query: CKQuery, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let database = CKContainer.default().privateCloudDatabase
        
        database.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
            } else if let records = records {
                completion(.success(records))
            } else {
                completion(.success([]))
            }
        }
    }
} 
