//
//  NutritionGoals.swift
//  Louie
//
//  Created by Carson on 4/2/25.
//

import Foundation
import CloudKit

public struct NutritionGoals: Codable {
    // Weekly target goals
    var caloriesGoal: Int
    var proteinGoal: Double
    var carbsGoal: Double
    var fatGoal: Double
    
    // Current progress
    var caloriesProgress: Int
    var proteinProgress: Double
    var carbsProgress: Double
    var fatProgress: Double
    
    // CloudKit record ID for syncing
    var recordID: CKRecord.ID?
    
    // Default initializer with reasonable defaults
    public init(
        caloriesGoal: Int = 2000,
        proteinGoal: Double = 150,
        carbsGoal: Double = 225,
        fatGoal: Double = 70,
        caloriesProgress: Int = 0,
        proteinProgress: Double = 0,
        carbsProgress: Double = 0,
        fatProgress: Double = 0,
        recordID: CKRecord.ID? = nil
    ) {
        self.caloriesGoal = caloriesGoal
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatGoal = fatGoal
        self.caloriesProgress = caloriesProgress
        self.proteinProgress = proteinProgress
        self.carbsProgress = carbsProgress
        self.fatProgress = fatProgress
        self.recordID = recordID
    }
    
    // Calculate progress percentages
    var caloriesPercentage: Double {
        guard caloriesGoal > 0 else { return 0 }
        return min(Double(caloriesProgress) / Double(caloriesGoal), 1.0)
    }
    
    var proteinPercentage: Double {
        guard proteinGoal > 0 else { return 0 }
        return min(proteinProgress / proteinGoal, 1.0)
    }
    
    var carbsPercentage: Double {
        guard carbsGoal > 0 else { return 0 }
        return min(carbsProgress / carbsGoal, 1.0)
    }
    
    var fatPercentage: Double {
        guard fatGoal > 0 else { return 0 }
        return min(fatProgress / fatGoal, 1.0)
    }
    
    // Add meal to progress
    mutating func addMeal(calories: Int, protein: Double, carbs: Double, fat: Double) {
        caloriesProgress += calories
        proteinProgress += protein
        carbsProgress += carbs
        fatProgress += fat
    }
    
    // Reset progress for new week
    mutating func resetProgress() {
        caloriesProgress = 0
        proteinProgress = 0
        carbsProgress = 0
        fatProgress = 0
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case caloriesGoal, proteinGoal, carbsGoal, fatGoal
        case caloriesProgress, proteinProgress, carbsProgress, fatProgress
        case recordIDName // For storing the recordID's name
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode regular properties
        caloriesGoal = try container.decode(Int.self, forKey: .caloriesGoal)
        proteinGoal = try container.decode(Double.self, forKey: .proteinGoal)
        carbsGoal = try container.decode(Double.self, forKey: .carbsGoal)
        fatGoal = try container.decode(Double.self, forKey: .fatGoal)
        caloriesProgress = try container.decode(Int.self, forKey: .caloriesProgress)
        proteinProgress = try container.decode(Double.self, forKey: .proteinProgress)
        carbsProgress = try container.decode(Double.self, forKey: .carbsProgress)
        fatProgress = try container.decode(Double.self, forKey: .fatProgress)
        
        // Handle optional recordID
        if let recordIDName = try container.decodeIfPresent(String.self, forKey: .recordIDName) {
            recordID = CKRecord.ID(recordName: recordIDName)
        } else {
            recordID = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode regular properties
        try container.encode(caloriesGoal, forKey: .caloriesGoal)
        try container.encode(proteinGoal, forKey: .proteinGoal)
        try container.encode(carbsGoal, forKey: .carbsGoal)
        try container.encode(fatGoal, forKey: .fatGoal)
        try container.encode(caloriesProgress, forKey: .caloriesProgress)
        try container.encode(proteinProgress, forKey: .proteinProgress)
        try container.encode(carbsProgress, forKey: .carbsProgress)
        try container.encode(fatProgress, forKey: .fatProgress)
        
        // Handle optional recordID
        if let recordIDName = recordID?.recordName {
            try container.encode(recordIDName, forKey: .recordIDName)
        }
    }
    
    // Save to UserDefaults
    func saveToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            UserDefaults.standard.set(data, forKey: "nutritionGoals")
        } catch {
            print("❌ Failed to save nutrition goals: \(error.localizedDescription)")
        }
    }
    
    // Load from UserDefaults
    static func loadFromUserDefaults() -> NutritionGoals {
        guard let data = UserDefaults.standard.data(forKey: "nutritionGoals") else {
            return NutritionGoals() // Return default goals if none found
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(NutritionGoals.self, from: data)
        } catch {
            print("❌ Failed to load nutrition goals: \(error.localizedDescription)")
            return NutritionGoals() // Return default goals if decode fails
        }
    }
}

