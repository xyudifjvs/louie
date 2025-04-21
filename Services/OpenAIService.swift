import UIKit
import Foundation

// Updated error enum
enum OpenAIServiceError: Error {
    case imageEncodingFailed
    case apiError(Error)
    case decodingError(Error)
    case invalidResponseFormat(String)
    case unexpectedResponse
    case networkError(Int, String)
}

/// Temporary struct matching the JSON structure from the OpenAI prompt
private struct OpenAIResponse: Codable {
    let identifiedFoods: [OpenAIFoodItem]
}

private struct OpenAIFoodItem: Codable {
    let name: String
    let amount: String // e.g., "100 g"
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let category: String // Matches FoodCategory raw values
    let vitaminC: Double?
    let iron: Double?
    let calcium: Double?
    let note: String? // e.g., "approximate"
}

/// Central helper that will talk to the OpenAI Vision endpoint.
// Renamed class to avoid conflict with SwiftOpenAI protocol
final class LouieOpenAIService {

    // Updated shared instance reference
    static let shared = LouieOpenAIService()
    private init() {}

    // MARK: - Prompt builder
    private func createFoodAnalysisPrompt() -> String {
        return """
        SYSTEM:
        You are NutriVision AI, a nutrition expert with vision capabilities.

        INSTRUCTIONS:
        1. Identify each distinct food item in the provided image.
        2. For each item, estimate its serving size in **grams** (or milliliters for liquids). If uncertain, provide your best estimate and include a `"note": "approximate"` field.
        3. For each item, return nutrition facts using reputable sources, with these exact keys and types:
           - calories (integer, kcal)
           - protein (float, grams)
           - carbs   (float, grams)
           - fat     (float, grams)
           - fiber   (float|null, grams)
           - sugar   (float|null, grams)
           - vitaminC (float|null, mg)
           - iron     (float|null, mg)
           - calcium  (float|null, mg)
        4. Classify each item into exactly one category: "Proteins", "Vegetables", "Carbs", or "Others".
        5. Always include an `"amount"` field for serving size in grams, e.g., `"amount": "100 g"`.
        6. Return **only** a single JSON object matching the schema below, with no markdown, comments, or extra text.

        EXAMPLE OUTPUT:
        {
          "identifiedFoods": [
            {
              "name": "Scrambled Eggs",
              "amount": "100 g",
              "calories": 148,
              "protein": 12.8,
              "carbs": 1.5,
              "fat": 10.0,
              "fiber": null,
              "sugar": null,
              "category": "Proteins",
              "vitaminC": null,
              "iron": null,
              "calcium": null,
              "note": "approximate"
            }
            // Additional items...
          ]
        }
        """
    }

    // MARK: - Data Mapping Helpers

    /// Parses the numeric value from the amount string (e.g., "100 g" -> 100.0)
    private func parseServingAmount(from amountString: String) -> Double {
        // Attempt to extract numeric part
        let components = amountString.components(separatedBy: CharacterSet.decimalDigits.inverted)
        if let numberString = components.first, let amount = Double(numberString) {
            return amount
        }
        // Fallback or default if parsing fails
        return 100.0 // Or handle error appropriately
    }

    /// Maps the raw category string to the FoodCategory enum
    private func mapCategory(from categoryString: String) -> FoodCategory {
        return FoodCategory(rawValue: categoryString) ?? .others
    }
    
    /// Maps the OpenAI response item to our FoodItem model
    private func mapOpenAIToFoodItem(_ openAIItem: OpenAIFoodItem) -> FoodItem {
        let servingAmount = parseServingAmount(from: openAIItem.amount)
        let category = mapCategory(from: openAIItem.category)

        let macros = MacroData(
            protein: openAIItem.protein,
            carbs: openAIItem.carbs,
            fat: openAIItem.fat,
            fiber: openAIItem.fiber ?? 0,
            sugar: openAIItem.sugar ?? 0
        )

        // Map available micros
        var micros = MicroData()
        micros.vitaminC = openAIItem.vitaminC ?? 0
        micros.iron = openAIItem.iron ?? 0
        micros.calcium = openAIItem.calcium ?? 0
        // Note: Other micros are not provided by the prompt structure

        return FoodItem(
            name: openAIItem.name,
            amount: openAIItem.amount,
            servingAmount: servingAmount,
            calories: openAIItem.calories,
            category: category,
            macros: macros,
            micros: micros
        )
    }
    
    /// Aggregates nutrition data from multiple FoodItems into a single MealEntry summary
    private func aggregateNutrition(foods: [FoodItem]) -> (macros: MacroData, micros: MicroData, score: Int) {
        var totalMacros = MacroData()
        var totalMicros = MicroData()

        for food in foods {
            totalMacros.protein += food.macros.protein
            totalMacros.carbs += food.macros.carbs
            totalMacros.fat += food.macros.fat
            totalMacros.fiber += food.macros.fiber
            totalMacros.sugar += food.macros.sugar

            totalMicros.vitaminC += food.micros.vitaminC
            totalMicros.iron += food.micros.iron
            totalMicros.calcium += food.micros.calcium
            // Add other micros if they become available
        }
        
        // Placeholder for nutrition score calculation
        let score = calculateNutritionScore(macros: totalMacros, micros: totalMicros)

        return (totalMacros, totalMicros, score)
    }
    
    /// Placeholder function for calculating the overall meal nutrition score
    private func calculateNutritionScore(macros: MacroData, micros: MicroData) -> Int {
        // Basic score based on macro balance and micro diversity (example)
        let balanceScore = macros.calculateBalanceScore() // Assuming this exists in MacroData
        let diversityScore = micros.calculateDiversityScore() // Assuming this exists in MicroData
        return (balanceScore + diversityScore) / 2 // Simple average
    }

    // MARK: - Public API

    func analyzeImageWithGPT4o(_ image: UIImage,
                               completion: @escaping (Result<MealEntry, Error>) -> Void) {
        
        // 1. Encode Image to Base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(OpenAIServiceError.imageEncodingFailed))
            return
        }
        let base64Image = imageData.base64EncodedString()
        
        // 2. Create request payload
        let apiKey = APIConstants.openAIAPIKey
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(OpenAIServiceError.unexpectedResponse))
            return
        }
        
        // Create the message content
        let systemPrompt = createFoodAnalysisPrompt()
        
        // Create JSON request body
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": "Analyze the food items in this image and return nutritional information in the specified JSON format."],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                ]]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 2048
        ]
        
        // 3. Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert request body to JSON data
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(OpenAIServiceError.apiError(error)))
            return
        }
        
        // 4. Make the API call
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(OpenAIServiceError.apiError(error)))
                }
                return
            }
            
            // Ensure we have response data
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(OpenAIServiceError.unexpectedResponse))
                }
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                DispatchQueue.main.async {
                    completion(.failure(OpenAIServiceError.networkError(httpResponse.statusCode, errorString)))
                }
                return
            }
            
            // 5. Process the response
            do {
                // First decode the OpenAI response structure
                let decoder = JSONDecoder()
                
                // Debug: print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw OpenAI response: \(jsonString)")
                }
                
                // Decode the OpenAI API response structure
                struct OpenAIAPIResponse: Decodable {
                    struct Choice: Decodable {
                        struct Message: Decodable {
                            let content: String
                        }
                        let message: Message
                    }
                    let choices: [Choice]
                }
                
                let apiResponse = try decoder.decode(OpenAIAPIResponse.self, from: data)
                
                // Extract the JSON content from the response
                guard let firstChoice = apiResponse.choices.first,
                      let jsonData = firstChoice.message.content.data(using: .utf8) else {
                    DispatchQueue.main.async {
                        completion(.failure(OpenAIServiceError.unexpectedResponse))
                    }
                    return
                }
                
                // Parse the JSON content into our food data structure
                let openAIResponse = try decoder.decode(OpenAIResponse.self, from: jsonData)
                
                // Debug print - show food items found
                print("Decoded food items: \(openAIResponse.identifiedFoods.count)")
                openAIResponse.identifiedFoods.forEach { item in
                    print("- \(item.name) (\(item.category)): \(item.calories) cal")
                }
                
                // 6. Map to Domain Models
                let foodItems = openAIResponse.identifiedFoods.map { self.mapOpenAIToFoodItem($0) }
                
                // Debug print - verify mapping
                print("Mapped to \(foodItems.count) FoodItem objects")
                foodItems.forEach { item in
                    print("- \(item.name) (\(item.category.rawValue)): \(item.calories) cal")
                }
                
                // 7. Aggregate Nutrition Data
                let aggregatedData = self.aggregateNutrition(foods: foodItems)
                
                // 8. Create MealEntry
                let mealEntry = MealEntry(
                    timestamp: Date(),
                    imageData: imageData,
                    imageURL: nil,
                    foods: foodItems,
                    nutritionScore: aggregatedData.score,
                    macronutrients: aggregatedData.macros,
                    micronutrients: aggregatedData.micros,
                    userNotes: nil,
                    isManuallyAdjusted: false
                )
                
                // Debug final MealEntry
                print("Created MealEntry with \(mealEntry.foods.count) foods")
                
                // Return result on main thread
                DispatchQueue.main.async {
                    completion(.success(mealEntry))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(OpenAIServiceError.decodingError(error)))
                }
            }
        }
        
        // Start the network request
        task.resume()
    }
}

