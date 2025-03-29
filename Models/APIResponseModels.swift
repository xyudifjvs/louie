//
//  APIResponseModels.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//

//  APIResponseModels.swift
//  Louie
//
//  Contains model definitions for API responses

import Foundation

// MARK: - Google Cloud Vision API Models
struct VisionResponse: Codable {
    let responses: [AnnotateImageResponse]
}

struct AnnotateImageResponse: Codable {
    let labelAnnotations: [LabelAnnotation]?
    let webDetection: WebDetection?
    let localizedObjectAnnotations: [LocalizedObjectAnnotation]?
    let error: ResponseError?
}

struct LabelAnnotation: Codable {
    let description: String
    let score: Float
    let topicality: Float
}

struct WebDetection: Codable {
    let webEntities: [WebEntity]?
    let bestGuessLabels: [BestGuessLabel]?
}

struct WebEntity: Codable {
    let entityId: String?
    let score: Float
    let description: String?
}

struct BestGuessLabel: Codable {
    let label: String
    let languageCode: String?
}

struct LocalizedObjectAnnotation: Codable {
    let name: String
    let score: Float
}

struct ResponseError: Codable {
    let code: Int
    let message: String
}

// MARK: - NutritionIX API Models
struct NutritionResponse: Codable {
    let foods: [NutritionixFood]
}

struct NutritionixFood: Codable {
    let foodName: String
    let servingQty: Double
    let servingUnit: String
    let servingWeightGrams: Double
    let nfCalories: Double
    let nfTotalFat: Double
    let nfSaturatedFat: Double
    let nfCholesterol: Double
    let nfSodium: Double
    let nfTotalCarbohydrate: Double
    let nfDietaryFiber: Double
    let nfSugars: Double
    let nfProtein: Double
    let nfPotassium: Double
    let nfP: Double? // Phosphorus
    
    // Additional nutrients that may be included
    let full_nutrients: [NutrientInfo]?
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case servingQty = "serving_qty"
        case servingUnit = "serving_unit"
        case servingWeightGrams = "serving_weight_grams"
        case nfCalories = "nf_calories"
        case nfTotalFat = "nf_total_fat"
        case nfSaturatedFat = "nf_saturated_fat"
        case nfCholesterol = "nf_cholesterol"
        case nfSodium = "nf_sodium"
        case nfTotalCarbohydrate = "nf_total_carbohydrate"
        case nfDietaryFiber = "nf_dietary_fiber"
        case nfSugars = "nf_sugars"
        case nfProtein = "nf_protein"
        case nfPotassium = "nf_potassium"
        case nfP = "nf_p"
        case full_nutrients
    }
}

struct NutrientInfo: Codable {
    let attr_id: Int
    let value: Double
}

// MARK: - API Error Types
enum APIError: Error {
    case networkError(Error)
    case noData
    case decodingError(Error)
    case noLabelsFound
    case noNutritionData
    case invalidImage
    case serverError(String)
    
    var description: String {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received from the server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noLabelsFound:
            return "No food items were recognized in the image"
        case .noNutritionData:
            return "Could not find nutrition data for the recognized food"
        case .invalidImage:
            return "The image could not be processed"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
