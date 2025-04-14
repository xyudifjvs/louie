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
                                    score: Float(0.95),
                                    topicality: Float(0.95)
                                )
                                allFoodLabels.append(label)
                            }
                        }
                        
                        // Add web entities
                        if let entities = webDetection.webEntities {
                            for entity in entities where entity.score > 0.5 && entity.description != nil {
                                let label = LabelAnnotation(
                                    description: entity.description!,
                                    score: Float(entity.score),
                                    topicality: Float(entity.score)
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
                    
                    // Remove duplicate/redundant items like burger variants
                    let filteredLabels = self.removeDuplicateItems(uniqueLabels)
                    
                    // Add improved debugging output
                    print("Vision API analysis results:")
                    print("  - Generic labels detected: \(allFoodLabels.filter { !self.isFoodRelated($0.description) }.map { "\($0.description) (\(Int($0.score * 100))%)" }.joined(separator: ", "))")
                    print("  - Specific food items identified: \(filteredLabels.filter { self.isFoodRelated($0.description) }.map { "\($0.description) (\(Int($0.score * 100))%)" }.joined(separator: ", "))")
                    
                    completion(.success(filteredLabels))
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
        request.timeoutInterval = 10 // Add shorter timeout for faster failure
        
        // Create JSON request body - OPTIMIZED TO REQUEST ONLY LABEL_DETECTION
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": [
                        "content": base64Image
                    ],
                    "features": [
                        [
                            "type": "LABEL_DETECTION",
                            "maxResults": 10 // Reduced from 15 for faster response
                        ]
                        // Removed WEB_DETECTION and OBJECT_LOCALIZATION for faster response
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
        // Define food ingredient categories (specific foods)
        let specificFoodItems = [
            // Proteins
            "egg", "chicken", "beef", "pork", "turkey", "fish", "salmon", "tuna", "shrimp", 
            "tofu", "beans", "lentils", "sausage", "bacon", "ham", "steak",
            
            // Vegetables
            "lettuce", "spinach", "kale", "broccoli", "carrot", "potato", "tomato", "onion", 
            "pepper", "cucumber", "corn", "peas", "mushroom", "avocado",
            
            // Fruits
            "apple", "banana", "orange", "strawberry", "blueberry", "grape", "melon", "watermelon",
            "pineapple", "mango", "peach", "pear", "cherry", "berry",
            
            // Grains & Starches
            "bread", "toast", "rice", "pasta", "noodle", "cereal", "oatmeal", "pancake", 
            "waffle", "tortilla", "bun", "bagel", "croissant", "muffin",
            
            // Dairy
            "milk", "cheese", "yogurt", "butter", "cream", "ice cream",
            
            // Prepared foods
            "sandwich", "burger", "pizza", "salad", "soup", "stew", "casserole", "taco", 
            "burrito", "wrap", "sushi", "curry", "pasta dish", "stir fry"
        ]
        
        // Generic categories to filter out
        let genericCategories = [
            "food", "dish", "cuisine", "meal", "breakfast", "lunch", "dinner", 
            "ingredient", "dishware", "fast food", "snack", "appetizer", "side dish",
            "comfort food", "gourmet", "homemade", "restaurant", "delicious", "tasty",
            "plate", "bowl", "fork", "spoon", "cooking", "kitchen", "dining", "table"
        ]
        
        // First, extract specific food items
        var specificFoods = labels.filter { label in
            let desc = label.description.lowercased()
            
            // Check if it contains a specific food item
            for food in specificFoodItems {
                if desc.contains(food) || desc == food {
                    // Make sure it's not just part of a generic category
                    for generic in genericCategories {
                        if desc == generic {
                            return false
                        }
                    }
                    return true
                }
            }
            return false
        }
        
        // If we found specific food items, return them sorted by confidence
        if !specificFoods.isEmpty {
            return specificFoods.sorted { $0.score > $1.score }
        }
        
        // Add special case detection for common meal types
        var mealTypeLabels: [LabelAnnotation] = []
        for label in labels {
            let desc = label.description.lowercased()
            
            // Check for breakfast items
            if desc.contains("breakfast") && (
                desc.contains("full") || desc.contains("american") || desc.contains("english") || 
                desc.contains("continental") || desc.contains("platter")
            ) {
                // Create specific breakfast components instead
                let components = [
                    "eggs", "bacon", "sausage", "toast", "hash browns", "pancakes"
                ]
                
                for (index, component) in components.enumerated() {
                    let adjustedScore = max(0.5, label.score - (Float(index) * 0.05))
                    let foodLabel = LabelAnnotation(
                        description: component,
                        score: adjustedScore,
                        topicality: adjustedScore
                    )
                    mealTypeLabels.append(foodLabel)
                }
            }
        }
        
        if !mealTypeLabels.isEmpty {
            return mealTypeLabels.sorted { $0.score > $1.score }
        }
        
        // If still nothing, use addSpecificFoodSuggestions
        var suggestedLabels: [LabelAnnotation] = []
        let hasBreakfast = labels.contains { $0.description.lowercased().contains("breakfast") }
        let hasDinner = labels.contains { $0.description.lowercased().contains("dinner") }
        let hasLunch = labels.contains { $0.description.lowercased().contains("lunch") }
        
        // Add meal-specific foods
        if hasBreakfast {
            suggestedLabels.append(LabelAnnotation(description: "eggs", score: Float(0.9), topicality: Float(0.9)))
            suggestedLabels.append(LabelAnnotation(description: "toast", score: Float(0.85), topicality: Float(0.85)))
            suggestedLabels.append(LabelAnnotation(description: "bacon", score: Float(0.8), topicality: Float(0.8)))
        } else if hasLunch {
            suggestedLabels.append(LabelAnnotation(description: "sandwich", score: Float(0.9), topicality: Float(0.9)))
            suggestedLabels.append(LabelAnnotation(description: "salad", score: Float(0.85), topicality: Float(0.85)))
        } else if hasDinner {
            suggestedLabels.append(LabelAnnotation(description: "chicken", score: Float(0.9), topicality: Float(0.9)))
            suggestedLabels.append(LabelAnnotation(description: "rice", score: Float(0.85), topicality: Float(0.85)))
            suggestedLabels.append(LabelAnnotation(description: "vegetables", score: Float(0.8), topicality: Float(0.8)))
        }
        
        if !suggestedLabels.isEmpty {
            return suggestedLabels
        }
        
        // If all else fails, return the top 3 labels with a warning
        let topLabels = Array(labels.sorted { $0.score > $1.score }.prefix(3))
        print("WARNING: No specific food items detected. Using generic labels.")
        return topLabels
    }
    
    /// Check if a term is a specific food item rather than a generic category
    private func isFoodRelated(_ term: String) -> Bool {
        // Define food ingredient categories (specific foods)
        let specificFoodItems = [
            // Proteins
            "egg", "chicken", "beef", "pork", "turkey", "fish", "salmon", "tuna", "shrimp", 
            "tofu", "beans", "lentils", "sausage", "bacon", "ham", "steak",
            
            // Vegetables
            "lettuce", "spinach", "kale", "broccoli", "carrot", "potato", "tomato", "onion", 
            "pepper", "cucumber", "corn", "peas", "mushroom", "avocado",
            
            // Fruits
            "apple", "banana", "orange", "strawberry", "blueberry", "grape", "melon", "watermelon",
            "pineapple", "mango", "peach", "pear", "cherry", "berry",
            
            // Grains & Starches
            "bread", "toast", "rice", "pasta", "noodle", "cereal", "oatmeal", "pancake", 
            "waffle", "tortilla", "bun", "bagel", "croissant", "muffin",
            
            // Dairy
            "milk", "cheese", "yogurt", "butter", "cream", "ice cream",
            
            // Prepared foods
            "sandwich", "burger", "pizza", "salad", "soup", "stew", "casserole", "taco", 
            "burrito", "wrap", "sushi", "curry", "pasta dish", "stir fry"
        ]
        
        // Generic categories to filter out
        let genericCategories = [
            "food", "dish", "cuisine", "meal", "breakfast", "lunch", "dinner", 
            "ingredient", "dishware", "fast food", "snack", "appetizer", "side dish"
        ]
        
        let lowercasedTerm = term.lowercased()
        
        // Filter out generic categories
        for generic in genericCategories {
            if lowercasedTerm == generic {
                return false
            }
        }
        
        // Check for specific food items
        for food in specificFoodItems {
            if lowercasedTerm.contains(food) || lowercasedTerm == food {
                return true
            }
        }
        
        // Check for common dishes and meal patterns
        if (lowercasedTerm.contains("breakfast") && (
            lowercasedTerm.contains("full") || lowercasedTerm.contains("american") || 
            lowercasedTerm.contains("english") || lowercasedTerm.contains("platter"))) {
            return true
        }
        
        return false
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
        // Check if we already have specific food items
        let existingFoodItems = labels.map { $0.description.lowercased() }
        
        // Check for specific foods - if we already have specific items like "cheeseburger", don't add similar items
        let specificFoodItems = ["cheeseburger", "hamburger", "pizza", "sushi", "taco", "burrito", "sandwich", 
                                "steak", "pasta", "chicken nuggets", "hot dog", "ice cream", "salad"]
        let hasSpecificFood = existingFoodItems.contains { item in
            specificFoodItems.contains(item)
        }
        
        // If we already have a specific food item, don't add suggestions
        if hasSpecificFood {
            print("Debug: Found specific food item, skipping additional suggestions")
            return
        }
        
        // Add common foods at lower confidence to help Nutritionix
        var suggestedFoods: [String] = []
        
        // Check for meal types
        let hasBreakfast = labels.contains { $0.description.lowercased().contains("breakfast") }
        let hasDinner = labels.contains { $0.description.lowercased().contains("dinner") }
        let hasLunch = labels.contains { $0.description.lowercased().contains("lunch") }
        let hasBrunch = labels.contains { $0.description.lowercased().contains("brunch") }
        
        // Check for cooking/preparation methods 
        let hasFried = labels.contains { $0.description.lowercased().contains("fried") }
        let hasGrilled = labels.contains { $0.description.lowercased().contains("grilled") }
        let hasBaked = labels.contains { $0.description.lowercased().contains("baked") }
        let hasRoasted = labels.contains { $0.description.lowercased().contains("roasted") }
        
        // Check for food categories
        let hasFastFood = labels.contains { $0.description.lowercased().contains("fast food") }
        let hasItalian = labels.contains { $0.description.lowercased().contains("italian") }
        let hasMexican = labels.contains { $0.description.lowercased().contains("mexican") }
        let hasAsian = labels.contains { 
            let desc = $0.description.lowercased()
            return desc.contains("asian") || desc.contains("chinese") || 
                   desc.contains("japanese") || desc.contains("thai")
        }
        
        // Add breakfast specific foods
        if hasBreakfast || hasBrunch {
            suggestedFoods.append(contentsOf: ["eggs", "toast", "bacon", "sausage", "oatmeal", "pancakes"])
            
            if hasFried {
                suggestedFoods.append(contentsOf: ["fried eggs", "hash browns"])
            }
        }
        
        // Add lunch specific foods
        if hasLunch {
            suggestedFoods.append(contentsOf: ["sandwich", "salad", "soup", "wrap"])
            
            if hasFried {
                suggestedFoods.append("french fries")
            }
        }
        
        // Add dinner specific foods
        if hasDinner {
            suggestedFoods.append(contentsOf: ["chicken", "beef", "fish", "rice", "potato", "vegetables"])
            
            if hasGrilled {
                suggestedFoods.append(contentsOf: ["grilled chicken", "grilled steak"])
            }
            
            if hasBaked || hasRoasted {
                suggestedFoods.append(contentsOf: ["roasted vegetables", "baked potato"])
            }
        }
        
        // Add cuisine-specific foods
        if hasItalian {
            suggestedFoods.append(contentsOf: ["pasta", "pizza", "bread", "tomato sauce"])
        }
        
        if hasMexican {
            suggestedFoods.append(contentsOf: ["taco", "burrito", "rice", "beans"])
        }
        
        if hasAsian {
            suggestedFoods.append(contentsOf: ["rice", "noodles", "vegetables"])
        }
        
        // Add fast food items - but limit similar items
        if hasFastFood {
            // Just add a single burger type instead of multiple similar types
            suggestedFoods.append("hamburger")
            suggestedFoods.append("french fries")
            suggestedFoods.append("chicken sandwich")
        }
        
        // Create final suggestion list
        var finalSuggestions = Set<String>()
        for food in suggestedFoods {
            finalSuggestions.insert(food.lowercased())
        }
        
        // Add suggested foods as new labels (avoiding duplicates)
        for food in finalSuggestions {
            // Check if this suggestion is already in the labels
            if !labels.contains(where: { $0.description.lowercased() == food }) {
                let suggestedLabel = LabelAnnotation(
                    description: food,
                    score: Float(0.85), // Higher confidence since these are targeted suggestions
                    topicality: Float(0.85)
                )
                labels.append(suggestedLabel)
            }
        }
        
        // Debug output
        print("Added specific food suggestions: \(Array(finalSuggestions).joined(separator: ", "))")
    }
    
    /// Add a new method to filter out redundant food items (like burger variants)
    private func removeDuplicateItems(_ labels: [LabelAnnotation]) -> [LabelAnnotation] {
        var result = [LabelAnnotation]()
        var processedCategories = Set<String>()
        
        // Groups of similar foods that should not appear together
        let similarGroups: [[String]] = [
            ["hamburger", "cheeseburger", "veggie burger", "burger"], // burger types
            ["pizza", "cheese pizza", "pepperoni pizza"], // pizza types
            ["chicken", "fried chicken", "grilled chicken", "roasted chicken"], // chicken types
            ["sandwich", "club sandwich", "blt sandwich", "grilled cheese"],  // sandwich types
            ["taco", "soft taco", "hard taco", "breakfast taco"] // taco types
        ]
        
        // Sort by highest score first
        let sortedLabels = labels.sorted { $0.score > $1.score }
        
        for label in sortedLabels {
            let lowerDesc = label.description.lowercased()
            
            // Check if this item belongs to a group we've already processed
            var inProcessedGroup = false
            for group in similarGroups {
                if group.contains(where: { $0 == lowerDesc }) {
                    let groupKey = group[0] // Use the first item as the group key
                    if processedCategories.contains(groupKey) {
                        inProcessedGroup = true
                        break
                    } else {
                        processedCategories.insert(groupKey)
                    }
                }
            }
            
            if !inProcessedGroup {
                result.append(label)
            }
        }
        
        return result
    }
}
