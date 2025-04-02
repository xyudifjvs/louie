struct LocalMealEntry: Codable {
    let id: UUID
    let timestamp: Date
    let imageName: String?
    let foods: [FoodItem]
    let nutritionScore: Int
    let macronutrients: MacroData
    let micronutrients: MicroData
    let userNotes: String?
    let isManuallyAdjusted: Bool
    let isDraft: Bool
    let recordIDString: String?
    
    init(from mealEntry: MealEntry, imageName: String? = nil) {
        self.id = mealEntry.id
        self.timestamp = mealEntry.timestamp
        self.imageName = imageName
        self.foods = mealEntry.foods
        self.nutritionScore = mealEntry.nutritionScore
        self.macronutrients = mealEntry.macronutrients
        self.micronutrients = mealEntry.micronutrients
        self.userNotes = mealEntry.userNotes
        self.isManuallyAdjusted = mealEntry.isManuallyAdjusted
        self.isDraft = mealEntry.isDraft
        self.recordIDString = mealEntry.recordID?.recordName
    }
    
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
            isManuallyAdjusted: isManuallyAdjusted,
            isDraft: isDraft
        )
        
        // Set recordID if available
        if let recordIDString = recordIDString {
            mealEntry.recordID = CKRecord.ID(recordName: recordIDString)
        }
        
        return mealEntry
    }
} 