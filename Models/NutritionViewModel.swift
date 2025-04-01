//
//  NutritionViewModel.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI
import CloudKit

// MARK: - ViewModel for Nutrition
public class NutritionViewModel: ObservableObject {
    @Published public var meals: [MealEntry] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var currentMeal: MealEntry?
    @Published public var nutritionInsights: [NutritionInsight] = []
    
    private let cloudKitManager = CloudKitManager.shared
    private let recordType = "MealEntry"
    private let nutritionService = NutritionService.shared
    
    public init() {}
    
    // Calculate nutrition score based on multiple factors
    public func calculateNutritionScore(foods: [FoodItem]) -> Int {
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
    
    /// Fetch meals from CloudKit
    public func fetchMeals() {
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
    
    /// Save a meal to CloudKit
    public func saveMeal(_ meal: MealEntry) {
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
    
    /// Delete a meal from CloudKit and local storage
    public func deleteMeal(_ meal: MealEntry) {
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Remove from local array first for immediate UI update
        DispatchQueue.main.async {
            withAnimation {
                self.meals.removeAll { $0.id == meal.id }
            }
        }
        
        // Then delete from CloudKit if we have a record ID
        if let recordID = meal.recordID {
            let database = CKContainer.default().privateCloudDatabase
            database.delete(withRecordID: recordID) { (recordID, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to delete meal: \(error.localizedDescription)"
                        print("Error deleting meal: \(error)")
                        
                        // Add the meal back to the array if CloudKit deletion failed
                        self.meals.append(meal)
                        self.meals.sort { $0.timestamp > $1.timestamp }
                    } else {
                        print("Successfully deleted meal from CloudKit")
                    }
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
    
    /// Generate nutritional insights for the current meal
    public func generateInsights() {
        guard let currentMeal = currentMeal, !currentMeal.foods.isEmpty else {
            nutritionInsights = []
            return
        }
        
        let foodLabels = currentMeal.foods.map { $0.name }
        // Use the synchronous version that returns insights directly
        nutritionInsights = nutritionService.getNutritionalInsights(for: foodLabels)
    }
} 