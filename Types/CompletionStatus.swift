import Foundation
import SwiftUI

/// Represents the completion status of a habit for a specific day
public enum CompletionStatus: Int, Codable {
    case noData = 0      // Not logged (gray)
    case completed = 1   // Completed (green)
    case notCompleted = 2 // Not completed (red)
    
    /// Returns the next status in the cycle: noData -> completed -> notCompleted -> noData
    public var next: CompletionStatus {
        switch self {
        case .noData: return .completed
        case .completed: return .notCompleted
        case .notCompleted: return .noData
        }
    }
    
    /// Returns the color associated with this status
    public var color: Color {
        switch self {
        case .noData: return Color.gray.opacity(0.3)
        case .completed: return Color.green.opacity(0.8)
        case .notCompleted: return Color.red.opacity(0.8)
        }
    }
    
    /// String representation for CloudKit storage
    public var stringValue: String {
        switch self {
        case .completed: return "completed"
        case .notCompleted: return "notCompleted"
        case .noData: return "noData"
        }
    }
    
    /// Initialize from string value (for CloudKit)
    public init?(fromString string: String) {
        switch string {
        case "completed": self = .completed
        case "notCompleted": self = .notCompleted
        case "noData": self = .noData
        default: return nil
        }
    }
} 