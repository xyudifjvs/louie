//
//  VisionService.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//
//  VisionService.swift
//  Louie
//
//  Handles Google Cloud Vision API integration

import Foundation
import UIKit

/// A service for interacting with the Google Cloud Vision API for image analysis
class VisionService {
    static let shared = VisionService()
    
    private init() {}
    
    /// Analyzes an image for food labels using Google Cloud Vision API
    /// - Parameters:
    ///   - image: The UIImage to analyze
    ///   - completion: Completion handler with Result containing array of labels or error
    func analyzeFood(image: UIImage, completion: @escaping (Result<[LabelAnnotation], APIError>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Resize image if needed to stay under API limits
        let processedImage = processImage(image: image)
        guard let processedImageData = processedImage.jpegData(compressionQuality: 0.7) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Google Vision API requires base64 encoded image
        let base64Image = processedImageData.base64EncodedString()
        
        // Create the API request
        var request = createVisionRequest(base64Image: base64Image)
        
        // Execute the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // Process the response
            do {
                let decoder = JSONDecoder()
                let visionResponse = try decoder.decode(VisionResponse.self, from: data)
                
                // Check for API-reported errors
                if let firstResponse = visionResponse.responses.first,
                   let responseError = firstResponse.error {
                    completion(.failure(.serverError(responseError.message)))
                    return
                }
                
                // Extract and combine all types of annotations
                var allFoodLabels = [LabelAnnotation]()
                
                if let firstResponse = visionResponse.responses.first {
                    // Add standard labels
                    if let labels = firstResponse.labelAnnotations {
                        let foodLabels = self.filterFoodLabels(labels)
                        allFoodLabels.append(contentsOf: foodLabels)
                    }
                    
                    // Add web detection entities as labels
                    if let webDetection = firstResponse.webDetection {
                        // Add best guess labels first (these are usually very accurate)
                        if let bestGuesses = webDetection.bestGuessLabels {
                            for guess in bestGuesses {
                                let label = LabelAnnotation(
                                    description: guess.label,
                                    score: 0.95, // High confidence for best guesses
                                    topicality: 0.95
                                )
                                allFoodLabels.append(label)
                            }
                        }
                        
                        // Add web entities
                        if let entities = webDetection.webEntities {
                            for entity in entities where entity.score > 0.5 && entity.description != nil {
                                let label = LabelAnnotation(
                                    description: entity.description!,
                                    score: entity.score,
                                    topicality: entity.score
                                )
                                
                                // Only add if it's food-related
                                if self.isFoodRelated(entity.description!) {
                                    allFoodLabels.append(label)
                                }
                            }
                        }
                    }
                    
                    // Add object localization results
                    if let objects = firstResponse.localizedObjectAnnotations {
                        for object in objects {
                            let label = LabelAnnotation(
                                description: object.name,
                                score: object.score,
                                topicality: object.score
                            )
                            
                            // Only add if it's food-related
                            if self.isFoodRelated(object.name) {
                                allFoodLabels.append(label)
                            }
                        }
                    }
                }
                
                // Remove duplicates and sort by confidence
                var uniqueLabels = [LabelAnnotation]()
                var seenDescriptions = Set<String>()
                
                for label in allFoodLabels.sorted(by: { $0.score > $1.score }) {
                    let lowercasedDesc = label.description.lowercased()
                    if !seenDescriptions.contains(lowercasedDesc) {
                        uniqueLabels.append(label)
                        seenDescriptions.insert(lowercasedDesc)
                    }
                }
                
                // Check if we found any food labels
                if uniqueLabels.isEmpty {
                    completion(.failure(.noLabelsFound))
                } else {
                    // Add some specific food keywords if we only have generic terms
                    if uniqueLabels.count <= 3 && self.containsOnlyGenericFoodTerms(uniqueLabels) {
                        self.addSpecificFoodSuggestions(&uniqueLabels)
                    }
                    
                    completion(.success(uniqueLabels))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    /// Creates the URLRequest for the Vision API
    private func createVisionRequest(base64Image: String) -> URLRequest {
        // Create Vision API request URL
        let url = URL(string: APIConstants.googleCloudVisionEndpoint + "?key=" + APIConstants.googleCloudVisionAPIKey)!
        
        // Configure request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create JSON request body
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": [
                        "content": base64Image
                    ],
                    "features": [
                        [
                            "type": "LABEL_DETECTION",
                            "maxResults": 15
                        ],
                        [
                            "type": "WEB_DETECTION",
                            "maxResults": 10
                        ],
                        [
                            "type": "OBJECT_LOCALIZATION",
                            "maxResults": 10
                        ]
                    ]
                ]
            ]
        ]
        
        // Serialize to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        return request
    }
    
    /// Process the image to ensure it meets API requirements
    private func processImage(image: UIImage) -> UIImage {
        // Maximum dimensions allowed to avoid excessive payload size
        let maxDimension: CGFloat = 1024
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // Check if resizing is needed
        if originalWidth <= maxDimension && originalHeight <= maxDimension {
            return image
        }
        
        // Calculate new dimensions while maintaining aspect ratio
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if originalWidth > originalHeight {
            newWidth = maxDimension
            newHeight = (originalHeight / originalWidth) * maxDimension
        } else {
            newHeight = maxDimension
            newWidth = (originalWidth / originalHeight) * maxDimension
        }
        
        // Create a new context and draw the resized image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    /// Filter and return only food-related labels
    private func filterFoodLabels(_ labels: [LabelAnnotation]) -> [LabelAnnotation] {
        // Common food categories for filtering
        let foodCategories = ["food", "dish", "cuisine", "meal", "ingredient", "breakfast", "lunch", "dinner", 
                              "vegetable", "fruit", "meat", "snack", "dessert", "beverage", "drink"]
        
        // First, try to find explicit food labels
        let foodLabels = labels.filter { label in
            for category in foodCategories {
                if label.description.lowercased().contains(category) {
                    return true
                }
            }
            return false
        }
        
        // If we found food labels, return them sorted by confidence
        if !foodLabels.isEmpty {
            return foodLabels.sorted { $0.score > $1.score }
        }
        
        // If no explicit food labels, return the top 5 labels by confidence
        return Array(labels.sorted { $0.score > $1.score }.prefix(5))
    }
    
    /// Check if a term is food-related
    private func isFoodRelated(_ term: String) -> Bool {
        let foodCategories = ["food", "dish", "cuisine", "meal", "ingredient", "breakfast", "lunch", "dinner", 
                              "vegetable", "fruit", "meat", "snack", "dessert", "beverage", "drink", "sandwich",
                              "burger", "pizza", "pasta", "salad", "chicken", "beef", "pork", "fish", "bread",
                              "cheese", "rice", "potato", "egg", "milk", "coffee", "tea", "juice", "soup"]
        
        let lowercasedTerm = term.lowercased()
        return foodCategories.contains { lowercasedTerm.contains($0) }
    }
    
    /// Check if all terms are generic food categories rather than specific foods
    private func containsOnlyGenericFoodTerms(_ labels: [LabelAnnotation]) -> Bool {
        let genericTerms = ["food", "dish", "cuisine", "meal", "fast food", "fried food", "junk food", "restaurant food"]
        let specificTerms = ["pizza", "burger", "salad", "sandwich", "chicken", "steak", "pasta", "rice"]
        
        // If we find any specific food term, return false
        for label in labels {
            let desc = label.description.lowercased()
            for term in specificTerms {
                if desc.contains(term) {
                    return false
                }
            }
        }
        
        // Check if all labels are generic
        var allGeneric = true
        for label in labels {
            let desc = label.description.lowercased()
            var isGeneric = false
            for term in genericTerms {
                if desc.contains(term) {
                    isGeneric = true
                    break
                }
            }
            if !isGeneric {
                allGeneric = false
                break
            }
        }
        
        return allGeneric
    }
    
    /// Add specific food suggestions based on generic categories
    private func addSpecificFoodSuggestions(_ labels: inout [LabelAnnotation]) {
        // Add common foods at lower confidence to help Nutritionix
        var suggestedFoods: [String] = []
        
        // Check if we have certain categories
        let hasGenericFastFood = labels.contains { $0.description.lowercased().contains("fast food") }
        let hasFriedFood = labels.contains { $0.description.lowercased().contains("fried") }
        
        if hasGenericFastFood {
            suggestedFoods.append(contentsOf: ["hamburger", "cheeseburger", "french fries", "chicken sandwich"])
        }
        
        if hasFriedFood {
            suggestedFoods.append(contentsOf: ["fried chicken", "chicken nuggets", "onion rings"])
        }
        
        // Add common foods for general "food" category
        suggestedFoods.append(contentsOf: ["sandwich", "pizza", "burger", "salad", "chicken"])
        
        // Add suggested foods as new labels with lower confidence
        for food in suggestedFoods {
            let suggestedLabel = LabelAnnotation(
                description: food,
                score: 0.7, // Lower confidence since these are guesses
                topicality: 0.7
            )
            labels.append(suggestedLabel)
        }
    }
}
