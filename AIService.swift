//
//  AIService.swift
//  Louie
//
//  Created by Carson on 3/24/25.
//

import Foundation

/// This service will be responsible for sending user data to the AI API and receiving insights back.
/// Initially, insights will be requested once per day after the daily check-in is completed,
/// or generated automatically in the background if no check-in is submitted by midnight.

class AIService {
    static let shared = AIService()

    // MARK: - API Configuration
    private let baseURL = URL(string: "https://your-ai-api.com")! // Replace with actual URL later
    private let apiKey = "YOUR_API_KEY" // Move to Secrets.plist or .env for production

    // MARK: - Insight Request Model (To be defined)
    struct InsightRequest: Codable {
        // Example:
        // let habits: [HabitData]
        // let mood: Int
        // let sleepHours: Double
        // let energyLevel: String
    }

    // MARK: - Insight Response Model (To be defined)
    struct InsightResponse: Codable {
        let insight: String
        let confidence: Double
    }

    // MARK: - Request Insights
    func generateInsight(from requestData: InsightRequest, completion: @escaping (Result<InsightResponse, Error>) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("/generate"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let body = try JSONEncoder().encode(requestData)
            request.httpBody = body
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            do {
                let insight = try JSONDecoder().decode(InsightResponse.self, from: data)
                completion(.success(insight))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}