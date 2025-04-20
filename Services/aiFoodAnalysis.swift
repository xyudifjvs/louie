//
//  OpenAIService.swift
//  Louie
//
//  Created by Carson on 3/28/25.
//

import Foundation
import UIKit
import SwiftOpenAI

/// Errors thrown by OpenAIService
enum OpenAIServiceError: Error {
    case apiError(message: String)
    case invalidResponseFormat(reason: String)
    case imagePreprocessingFailed
    case imageEncodingFailed
    case missingExpectedData
}

/// A singleton service wrapping SwiftOpenAI client calls
final class OpenAIService {
    static let shared = OpenAIService()
    private let service = OpenAIServiceFactory.service(apiKey: APIConstants.openAIAPIKey)

    private init() {}
    
    // ... existing methods like analyzeImageWithGPT4o(...)
}
