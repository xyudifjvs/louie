//
//  APIConstants.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//
//  APIConstants.swift
//  Louie
//
//  Contains secure storage for API keys and endpoints

import Foundation

struct APIConstants {
    // Google Cloud Vision API
    static let googleCloudVisionAPIKey = "AIzaSyCt35UEmwLql_iNgJC3ce0QCFLdlXVKAJw"
    static let googleCloudVisionEndpoint = "https://vision.googleapis.com/v1/images:annotate"
    
    // NutritionIX API
    static let nutritionixAppID = "809924bf"
    static let nutritionixAPIKey = "74a5d218b4ba9be4ce1adf63120137a7"
    static let nutritionixEndpoint = "https://trackapi.nutritionix.com/v2/natural/nutrients"
}
