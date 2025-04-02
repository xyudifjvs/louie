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
    @Published var nutritionGoals = NutritionGoals.loadFromUserDefaults()
    
    private let cloudKitManager = CloudKitSyncManager.shared
    private let nutritionService = NutritionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Directory for storing meal images
    private let imageDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("MealImages")
    
    public init() {
        // Create image directory if it doesn't exist
        createImageDirectoryIfNeeded()
        
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
        
        // Schedule periodic cleanup to remove any duplicates
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.cleanupDuplicateMeals()
        }
    }
    
    // Create image directory if it doesn't exist
    private func createImageDirectoryIfNeeded() {
        do {
            if !FileManager.default.fileExists(atPath: imageDirectory.path) {
                try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
                print("📁 Created meal images directory")
            }
        } catch {
            print("❌ Failed to create image directory: \(error.localizedDescription)")
        }
    }
    
    // Save image data to file system
    private func saveImageToFileSystem(data: Data, mealId: UUID) -> String? {
        let filename = mealId.uuidString + ".jpg"
        let fileURL = imageDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("📸 Saved image for meal \(mealId) to file system")
            return filename
        } catch {
            print("❌ Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Load image data from file system
    private func loadImageFromFileSystem(filename: String) -> Data? {
        let fileURL = imageDirectory.appendingPathComponent(filename)
        
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            print("❌ Failed to load image \(filename): \(error.localizedDescription)")
            return nil
        }
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
        print("☁️ Fetching meals from CloudKit...")
        isLoading = true
        errorMessage = nil
        
        // First, create a dictionary of existing meals by ID for quick lookup
        let existingMealsById = Dictionary(uniqueKeysWithValues: 
            self.meals.map { ($0.id, $0) })
        
        // Fetch meals from CloudKit
        cloudKitManager.fetchRecords(
            ofType: MealEntry.self,
            sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: false)]
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(var fetchedMeals):
                    print("✅ Successfully fetched \(fetchedMeals.count) meals from CloudKit")
                    
                    // Merge fetched meals with existing meals while preserving image data
                    var mergedMeals = [MealEntry]()
                    
                    for var fetchedMeal in fetchedMeals {
                        // If we already have this meal with image data in memory, and the fetched one doesn't have image data
                        if let existingMeal = existingMealsById[fetchedMeal.id],
                           let existingImageData = existingMeal.imageData,
                           fetchedMeal.imageData == nil {
                            // Preserve the image data we already have
                            fetchedMeal.imageData = existingImageData
                        }
                        
                        // Always ensure isManuallyAdjusted is false (feature removed)
                        fetchedMeal.isManuallyAdjusted = false
                        
                        mergedMeals.append(fetchedMeal)
                    }
                    
                    // Deduplicate meals
                    mergedMeals = self.deduplicateMeals(mergedMeals)
                    
                    // Sort by timestamp (newest first)
                    mergedMeals.sort { $0.timestamp > $1.timestamp }
                    
                    // Update the UI
                    withAnimation {
                        self.meals = mergedMeals
                    }
                    
                    // Save to local cache
                    self.saveToLocalCache()
                    
                    // Update nutrition goals
                    self.updateNutritionGoals()
                    
                case .failure(let error):
                    self.errorMessage = "Error fetching meals: \(error.localizedDescription)"
                    print("❌ Error fetching meals: \(error.localizedDescription)")
                    
                    // Try to load from cache if CloudKit fetch fails
                    self.loadFromLocalCache()
                    
                    // Update nutrition goals with local data
                    self.updateNutritionGoals()
                }
            }
        }
    }
    
    /// Save a new meal or update an existing one
    public func saveMeal(_ meal: MealEntry) {
        print("💾 Saving meal to CloudKit...")
        
        // Make a copy of the meal to preserve image data
        var mealToSave = meal
        
        // Always ensure isManuallyAdjusted is false
        mealToSave.isManuallyAdjusted = false
        
        // IMPORTANT: Check for duplicates BEFORE adding to the local array
        // First check if this meal already exists by ID
        if let index = meals.firstIndex(where: { $0.id == mealToSave.id }) {
            // This is an existing meal - update it
            let existingMeal = meals[index]
            
            // If the existing meal has image data and the new one doesn't, preserve it
            if mealToSave.imageData == nil && existingMeal.imageData != nil {
                mealToSave.imageData = existingMeal.imageData
            }
            
            // Update existing meal
            print("✅ No duplicates found, updating existing meal with ID \(mealToSave.id)")
            meals[index] = mealToSave
        } else {
            // This is a new meal - add it to the array
            print("✅ No duplicates found, saving as new meal with ID \(mealToSave.id)")
            meals.append(mealToSave)
            
            // Sort the meals by timestamp (newest first)
            meals.sort { $0.timestamp > $1.timestamp }
        }
        
        // Update local cache
        saveToLocalCache()
        
        // Update nutrition goals with the new meal data
        updateNutritionGoals()
        
        // Save to CloudKit
        cloudKitManager.saveRecord(mealToSave) { [weak self] (result: Result<MealEntry, CloudKitSyncError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let savedMeal):
                    print("✅ Successfully saved meal to CloudKit")
                    
                    // Update the meal in our local array with the one that has a recordID
                    if let index = self.meals.firstIndex(where: { $0.id == savedMeal.id }) {
                        self.meals[index] = savedMeal
                        
                        // Save updated meal to local cache
                        self.saveToLocalCache()
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Error saving meal: \(error.localizedDescription)"
                    print("❌ Error saving meal to CloudKit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Update an existing meal
    public func updateMeal(_ meal: MealEntry) {
        print("🔄 Updating meal in CloudKit...")
        
        // Create a copy of the meal to ensure we don't modify the original
        var updatedMeal = meal
        
        // Always set isManuallyAdjusted to false (feature removed)
        updatedMeal.isManuallyAdjusted = false
        
        // First update local array for immediate UI update
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            // If the existing meal has image data and the new one doesn't, preserve it
            let existingMeal = meals[index]
            if updatedMeal.imageData == nil && existingMeal.imageData != nil {
                updatedMeal.imageData = existingMeal.imageData
                print("⚠️ Preserving existing image data for meal update")
            }
            
            meals[index] = updatedMeal
            // Save to local cache
            saveToLocalCache()
        }
        
        // Then update in CloudKit
        cloudKitManager.saveRecord(updatedMeal) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(var cloudkitMeal):
                    print("✅ Successfully updated meal in CloudKit")
                    
                    // Preserve the image data if CloudKit doesn't return it
                    if cloudkitMeal.imageData == nil && updatedMeal.imageData != nil {
                        cloudkitMeal.imageData = updatedMeal.imageData
                    }
                    
                    // Always set isManuallyAdjusted to false
                    cloudkitMeal.isManuallyAdjusted = false
                    
                    // Update with the latest version from CloudKit
                    if let index = self.meals.firstIndex(where: { $0.id == cloudkitMeal.id }) {
                        self.meals[index] = cloudkitMeal
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
    
    /// Delete a meal
    public func deleteMeal(_ meal: MealEntry) {
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Remove from local array first for immediate UI update
        meals.removeAll { $0.id == meal.id }
        
        // Update local cache
        saveToLocalCache()
        
        // Update nutrition goals after removing the meal
        updateNutritionGoals()
        
        // Only attempt to delete from CloudKit if the meal has a recordID
        if let recordID = meal.recordID {
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
                        
                        // Update nutrition goals after adding the meal back
                        self.updateNutritionGoals()
                    }
                }
            }
        } else {
            // Meal doesn't have a recordID, so it was never saved to CloudKit
            print("ℹ️ Meal deleted locally only (no CloudKit record)")
        }
    }
    
    // MARK: - Local Caching
    
    /// Save meals to UserDefaults as a backup
    private func saveToLocalCache() {
        print("💾 Saving to local cache...")
        
        do {
            // Create a lightweight version of meals without image data
            var cachedMeals = [CachedMealEntry]()
            
            // Limit to last 30 meals to avoid excessive storage
            let limitedMeals = Array(meals.prefix(30))
            
            for meal in limitedMeals {
                var cachedMeal = CachedMealEntry(from: meal)
                
                // If the meal has image data, save it to the file system
                if let imageData = meal.imageData {
                    // Save image to file system and store the filename
                    if let filename = saveImageToFileSystem(data: imageData, mealId: meal.id) {
                        cachedMeal.imageFilename = filename
                    }
                }
                
                cachedMeals.append(cachedMeal)
            }
            
            // Encode the lightweight meal objects
            let data = try JSONEncoder().encode(cachedMeals)
            UserDefaults.standard.set(data, forKey: "cachedMeals")
            print("💾 Saved \(cachedMeals.count) meals to local cache")
        } catch {
            print("❌ Error saving to local cache: \(error.localizedDescription)")
        }
    }
    
    /// Load meals from UserDefaults when offline
    private func loadFromLocalCache() {
        print("📂 Loading from local cache...")
        
        if let data = UserDefaults.standard.data(forKey: "cachedMeals") {
            do {
                let decoder = JSONDecoder()
                let cachedMeals = try decoder.decode([CachedMealEntry].self, from: data)
                
                print("✅ Loaded \(cachedMeals.count) meals from local cache")
                
                // Create a dictionary of existing meals by ID for quick lookup
                let existingMealsById = Dictionary(uniqueKeysWithValues: 
                    self.meals.map { ($0.id, $0) })
                
                // Convert cached meals back to full meal entries with images
                var fullMeals = [MealEntry]()
                
                for cachedMeal in cachedMeals {
                    var mealEntry = cachedMeal.toMealEntry()
                    
                    // Try to load the image from file system if there's a filename
                    if let filename = cachedMeal.imageFilename, 
                       let imageData = loadImageFromFileSystem(filename: filename) {
                        mealEntry.imageData = imageData
                        print("📸 Loaded image for meal \(mealEntry.id) from file system")
                    } 
                    // If no filename or loading failed, try using existing image if available
                    else if let existingMeal = existingMealsById[mealEntry.id],
                            let existingImageData = existingMeal.imageData {
                        mealEntry.imageData = existingImageData
                    }
                    
                    // Always ensure isManuallyAdjusted is false (feature removed)
                    mealEntry.isManuallyAdjusted = false
                    
                    fullMeals.append(mealEntry)
                }
                
                // Deduplicate meals before updating UI
                let uniqueMeals = deduplicateMeals(fullMeals)
                
                withAnimation {
                    self.meals = uniqueMeals
                }
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
                
                // Also run a cleanup to remove any duplicates
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.cleanupDuplicateMeals()
                }
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
    
    /// Check if two meals are likely duplicates by comparing content
    private func areMealsSimilar(_ meal1: MealEntry, _ meal2: MealEntry) -> Bool {
        // Time-based check: if meals are within 2 minutes of each other
        let timeInterval = abs(meal1.timestamp.timeIntervalSince(meal2.timestamp))
        let areTimestampsClose = timeInterval < 120 // Within 2 minutes
        
        // If timestamps are not close, they're definitely not duplicates
        if !areTimestampsClose {
            return false
        }
        
        // If either meal has no foods, just use the timestamp check
        if meal1.foods.isEmpty || meal2.foods.isEmpty {
            return areTimestampsClose
        }
        
        // Check for similarity in foods
        // For simplicity, we'll check if at least 50% of foods match by name
        let foods1 = Set(meal1.foods.map { $0.name.lowercased() })
        let foods2 = Set(meal2.foods.map { $0.name.lowercased() })
        
        if foods1.isEmpty || foods2.isEmpty {
            return areTimestampsClose
        }
        
        // Find common food items
        let commonItems = foods1.intersection(foods2)
        
        // Calculate similarity ratio
        let similarity = Double(commonItems.count) / Double(max(foods1.count, foods2.count))
        
        // Consider it a duplicate if 50% or more foods match
        return similarity >= 0.5
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
    
    /// Manually force a refresh of all data
    public func forceRefresh() {
        print("🔄 Forcing refresh of data...")
        fetchMeals()
        
        // Run cleanup after fetch completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.cleanupDuplicateMeals()
        }
    }
    
    /// Deduplicate meals based on similarity and ID
    private func deduplicateMeals(_ meals: [MealEntry]) -> [MealEntry] {
        var uniqueMeals = [MealEntry]()
        var seenIds = Set<UUID>()
        var seenContentHashes = Set<String>()
        
        for meal in meals {
            // Skip if we've already seen this ID
            if seenIds.contains(meal.id) {
                print("🔍 Skipping duplicate meal with ID: \(meal.id)")
                continue
            }
            
            // Create a content hash using timestamp and food names
            let timeString = String(format: "%.0f", meal.timestamp.timeIntervalSince1970)
            let foodsString = meal.foods.map { $0.name.lowercased() }.sorted().joined(separator: "-")
            let contentHash = "\(timeString)-\(foodsString)"
            
            // Skip if we've seen a meal with very similar content
            if seenContentHashes.contains(contentHash) {
                print("🔍 Skipping meal with duplicate content: \(contentHash)")
                continue
            }
            
            // Always ensure isManuallyAdjusted is false
            var cleanMeal = meal
            cleanMeal.isManuallyAdjusted = false
            
            // Add to our results
            uniqueMeals.append(cleanMeal)
            seenIds.insert(meal.id)
            seenContentHashes.insert(contentHash)
        }
        
        print("🧹 Deduplicated \(meals.count) meals into \(uniqueMeals.count) unique meals")
        return uniqueMeals
    }
    
    // MARK: - Duplicates and Data Cleanup
    
    /// Perform a thorough cleanup of any duplicate meals
    private func cleanupDuplicateMeals() {
        // Get the current count
        let originalCount = meals.count
        
        // First deduplicate by ID to ensure no duplicated UUIDs
        var seenIds = Set<UUID>()
        var uniqueMeals = [MealEntry]()
        
        for meal in meals {
            if !seenIds.contains(meal.id) {
                // Create a clean copy of the meal
                var cleanMeal = meal
                cleanMeal.isManuallyAdjusted = false
                uniqueMeals.append(cleanMeal)
                seenIds.insert(meal.id)
            }
        }
        
        // Then group by similar timestamp and content to find near-duplicates
        var groups = [String: [MealEntry]]()
        
        for meal in uniqueMeals {
            // Create a fuzzy timestamp bucket (rounded to nearest minute)
            let timeRoundedToMinute = Int(meal.timestamp.timeIntervalSince1970 / 60) * 60
            let foodsHash = meal.foods.map { $0.name.lowercased() }.sorted().joined(separator: "-")
            
            // Create bucket key using the rounded time and foods
            let bucketKey = "\(timeRoundedToMinute)-\(foodsHash)"
            
            if groups[bucketKey] == nil {
                groups[bucketKey] = [meal]
            } else {
                groups[bucketKey]!.append(meal)
            }
        }
        
        // For each group of similar meals, keep only the one with the most data
        var finalMeals = [MealEntry]()
        
        for (_, similarMeals) in groups {
            if similarMeals.count > 1 {
                print("🧹 Found \(similarMeals.count) similar meals - keeping best one")
                
                // Sort by which has the most data (image, foods, etc)
                let bestMeal = similarMeals.max { a, b in
                    let aScore = (a.imageData != nil ? 10 : 0) + a.foods.count
                    let bScore = (b.imageData != nil ? 10 : 0) + b.foods.count
                    return aScore < bScore
                }
                
                if let meal = bestMeal {
                    finalMeals.append(meal)
                }
            } else {
                // Only one meal in this group, just add it
                finalMeals.append(similarMeals[0])
            }
        }
        
        // Sort by timestamp (newest first) and update
        finalMeals.sort { $0.timestamp > $1.timestamp }
        
        if finalMeals.count < originalCount {
            print("🧹 Cleaned up \(originalCount - finalMeals.count) duplicate meals")
            
            withAnimation {
                self.meals = finalMeals
            }
            
            // Save to local cache
            saveToLocalCache()
        } else {
            print("✅ No duplicates found during cleanup")
        }
    }
    
    // MARK: - Nutrition Goals
    
    /// Update nutrition goals based on all meals from the current week
    private func updateNutritionGoals() {
        // Load the current goals
        var goals = NutritionGoals.loadFromUserDefaults()
        
        // Reset progress first to avoid double-counting
        goals.resetProgress()
        
        // Get start of the week (Sunday)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1 // 1 = Sunday in Gregorian calendar
        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        
        // Filter to this week's meals only
        let thisWeeksMeals = meals.filter { meal in
            let mealDate = calendar.startOfDay(for: meal.timestamp)
            return mealDate >= startOfWeek && mealDate <= today
        }
        
        // Add up all nutrition data for the week
        for meal in thisWeeksMeals {
            // Calculate total calories
            let calories = meal.macronutrients.totalCalories
            
            // Add this meal's nutrients to the weekly progress
            goals.addMeal(
                calories: calories,
                protein: meal.macronutrients.protein,
                carbs: meal.macronutrients.carbs,
                fat: meal.macronutrients.fat
            )
        }
        
        // Update the published property
        nutritionGoals = goals
        
        // Save updated goals to UserDefaults
        goals.saveToUserDefaults()
        
        // Also save to CloudKit for sync across devices
        if iCloudAvailable {
            cloudKitManager.saveRecord(goals) { [weak self] (result: Result<NutritionGoals, CloudKitSyncError>) in
                guard let self = self else { return }
                
                switch result {
                case .success(let savedGoals):
                    print("✅ Successfully saved nutrition goals to CloudKit")
                    
                    // Update goals with the CloudKit record ID
                    DispatchQueue.main.async {
                        self.nutritionGoals = savedGoals
                        savedGoals.saveToUserDefaults()
                    }
                    
                case .failure(let error):
                    print("❌ Error saving nutrition goals to CloudKit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns only meals from today, sorted by timestamp (newest first)
    public var todayMeals: [MealEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { 
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    /// Check if iCloud is available for CloudKit operations
    private var iCloudAvailable: Bool {
        return cloudKitManager.iCloudAvailable
    }
}

// A lightweight version of MealEntry for caching
struct CachedMealEntry: Codable {
    let id: UUID
    let timestamp: Date
    var foods: [FoodItem]
    var userNotes: String?
    var nutritionScore: Int
    var macronutrients: MacroData
    var micronutrients: MicroData
    var isManuallyAdjusted: Bool
    var recordIDString: String?
    var imageFilename: String?  // Store filename instead of actual image data
    
    // Create from a MealEntry
    init(from meal: MealEntry) {
        self.id = meal.id
        self.timestamp = meal.timestamp
        self.foods = meal.foods
        self.userNotes = meal.userNotes
        self.nutritionScore = meal.nutritionScore
        self.macronutrients = meal.macronutrients
        self.micronutrients = meal.micronutrients
        self.isManuallyAdjusted = meal.isManuallyAdjusted
        self.recordIDString = meal.recordID?.recordName
        self.imageFilename = nil // Will be set if image is saved to file system
    }
    
    // Convert back to MealEntry
    func toMealEntry() -> MealEntry {
        var mealEntry = MealEntry(
            id: id, 
            timestamp: timestamp,
            imageData: nil,  // Will be loaded separately
            imageURL: nil,
            foods: foods,
            nutritionScore: nutritionScore,
            macronutrients: macronutrients,
            micronutrients: micronutrients,
            userNotes: userNotes,
            isManuallyAdjusted: isManuallyAdjusted
        )
        
        // Set recordID if available
        if let recordIDString = recordIDString {
            mealEntry.recordID = CKRecord.ID(recordName: recordIDString)
        }
        
        return mealEntry
    }
}
