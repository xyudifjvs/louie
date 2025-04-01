//
//  NutritionViewModel2.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//
//
//  NutritionViewModel.swift
//  Louie
//
//  Created by Carson on 3/31/25.
//

import SwiftUI
import CloudKit
import Combine

// MARK: - ViewModel for Nutrition
public class NutritionViewModel2: ObservableObject {
    @Published public var meals: [MealEntry] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var currentMeal: MealEntry?
    @Published public var nutritionInsights: [NutritionInsight] = []
    @Published var cloudSyncStatus: SyncStatus = .idle
    
    private let cloudKitManager = CloudKitSyncManager.shared
    private let nutritionService = NutritionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Subscribe to sync status changes
        cloudKitManager.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.cloudSyncStatus = status
                self?.isLoading = status.isActive
            }
            .store(in: &cancellables)
        
        // Setup app lifecycle observers
        setupAppLifecycleObservers()
    }
    
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
        print("🔄 Fetching meals from CloudKit...")
        errorMessage = nil
        
        cloudKitManager.fetchRecords(ofType: MealEntry.self, sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: false)]) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedMeals):
                    print("✅ Successfully fetched \(fetchedMeals.count) meals")
                    withAnimation {
                        self.meals = fetchedMeals
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Error fetching meals: \(error.localizedDescription)")
                    
                    // Try to load from local cache instead
                    self.loadFromLocalCache()
                }
            }
        }
    }
    
    /// Save a meal to CloudKit
    public func saveMeal(_ meal: MealEntry) {
        print("💾 Saving meal to CloudKit...")
        errorMessage = nil
        
        // First, save to local meals array for immediate UI update
        var mealCopy = meal
        
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            // Update existing meal
            meals[index] = mealCopy
        } else {
            // Add new meal to the beginning of the array
            meals.insert(mealCopy, at: 0)
        }
        
        // Save to local cache
        saveToLocalCache()
        
        // Then save to CloudKit
        cloudKitManager.saveRecord(mealCopy) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let savedMeal):
                    print("✅ Successfully saved meal to CloudKit")
                    
                    // Update the meal in our array with the one returned from CloudKit (with recordID)
                    if let index = self.meals.firstIndex(where: { $0.id == savedMeal.id }) {
                        self.meals[index] = savedMeal
                        
                        // Also update local cache
                        self.saveToLocalCache()
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Error saving meal: \(error.localizedDescription)"
                    print("❌ Error saving meal: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Update an existing meal
    public func updateMeal(_ meal: MealEntry) {
        print("🔄 Updating meal in CloudKit...")
        
        // First update local array for immediate UI update
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            meals[index] = meal
            // Save to local cache
            saveToLocalCache()
        }
        
        // Then update in CloudKit
        cloudKitManager.saveRecord(meal) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedMeal):
                    print("✅ Successfully updated meal in CloudKit")
                    
                    // Update with the latest version from CloudKit
                    if let index = self.meals.firstIndex(where: { $0.id == updatedMeal.id }) {
                        self.meals[index] = updatedMeal
                        // Update local cache
                        self.saveToLocalCache()
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Error updating meal: \(error.localizedDescription)"
                    print("❌ Error updating meal: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Delete a meal from CloudKit and local storage
    public func deleteMeal(_ meal: MealEntry) {
        print("🗑️ Deleting meal from CloudKit...")
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Remove from local array first for immediate UI update
        withAnimation {
            meals.removeAll { $0.id == meal.id }
        }
        
        // Update local cache
        saveToLocalCache()
        
        // Then delete from CloudKit
        cloudKitManager.deleteRecord(meal) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Successfully deleted meal from CloudKit")
                    
                case .failure(let error):
                    self.errorMessage = "Error deleting meal: \(error.localizedDescription)"
                    print("❌ Error deleting meal: \(error.localizedDescription)")
                    
                    // Add the meal back to the array if CloudKit deletion failed
                    self.meals.append(meal)
                    self.meals.sort { $0.timestamp > $1.timestamp }
                    
                    // Update local cache
                    self.saveToLocalCache()
                }
            }
        }
    }
    
    // MARK: - Local Caching
    
    /// Save meals to UserDefaults as a backup
    private func saveToLocalCache() {
        print("💾 Saving to local cache...")
        
        do {
            // Limit to last 30 meals to avoid excessive storage
            let limitedMeals = Array(meals.prefix(30))
            let data = try JSONEncoder().encode(limitedMeals)
            UserDefaults.standard.set(data, forKey: "cachedMeals")
        } catch {
            print("❌ Error saving to local cache: \(error.localizedDescription)")
        }
    }
    
    /// Load meals from UserDefaults when offline
    private func loadFromLocalCache() {
        print("📂 Loading from local cache...")
        
        if let data = UserDefaults.standard.data(forKey: "cachedMeals") {
            do {
                let cachedMeals = try JSONDecoder().decode([MealEntry].self, from: data)
                withAnimation {
                    self.meals = cachedMeals
                }
                print("✅ Loaded \(cachedMeals.count) meals from local cache")
            } catch {
                print("❌ Error loading from local cache: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - App Lifecycle
    
    /// Setup app lifecycle observers to refresh data
    private func setupAppLifecycleObservers() {
        // Refresh data when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                print("📱 App became active, refreshing data...")
                self?.fetchMeals()
            }
            .store(in: &cancellables)
        
        // Refresh iCloud status
        NotificationCenter.default.publisher(for: Notification.Name.CKAccountChanged)
            .sink { [weak self] _ in
                print("☁️ iCloud account changed, refreshing data...")
                self?.fetchMeals()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
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
    
    /// Manually force a refresh of all data
    public func forceRefresh() {
        print("🔄 Forcing refresh of data...")
        fetchMeals()
    }
}
