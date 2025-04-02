//
//  CloudKitSyncManager.swift
//  Louie
//
//  Created by Carson on 4/1/25.
//

import Foundation
import CloudKit
import SwiftUI
import Combine

// MARK: - CloudKit Error Types
enum CloudKitSyncError: Error {
    case networkFailure
    case iCloudAccountNotAvailable
    case permissionDenied
    case recordNotFound
    case unknownError(Error)
    case operationCancelled
    case serverRejectedRequest
    case validationFailed(String)
    case decodingFailed
    case limitExceeded
    case notAuthenticated
    case quotaExceeded
    
    init(from ckError: Error) {
        let nsError = ckError as NSError
        switch nsError.code {
        case CKError.networkFailure.rawValue:
            self = .networkFailure
        case CKError.notAuthenticated.rawValue:
            self = .notAuthenticated
        case CKError.permissionFailure.rawValue:
            self = .permissionDenied
        case CKError.unknownItem.rawValue:
            self = .recordNotFound
        case CKError.serverRejectedRequest.rawValue:
            self = .serverRejectedRequest
        case CKError.limitExceeded.rawValue:
            self = .limitExceeded
        case CKError.quotaExceeded.rawValue:
            self = .quotaExceeded
        default:
            self = .unknownError(ckError)
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .networkFailure:
            return "Network connection failed. Please check your internet connection."
        case .iCloudAccountNotAvailable:
            return "iCloud account not found. Please sign in to your iCloud account in Settings."
        case .permissionDenied:
            return "Permission denied. Please check your iCloud settings."
        case .recordNotFound:
            return "The requested record was not found."
        case .unknownError(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        case .operationCancelled:
            return "Operation was cancelled."
        case .serverRejectedRequest:
            return "Server rejected the request. Please try again later."
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .decodingFailed:
            return "Failed to decode data from CloudKit."
        case .limitExceeded:
            return "CloudKit operation limit exceeded. Please try again later."
        case .notAuthenticated:
            return "Not authenticated with iCloud. Please check your iCloud account settings."
        case .quotaExceeded:
            return "CloudKit quota exceeded. Please try again later."
        }
    }
    
    var isRetriable: Bool {
        switch self {
        case .networkFailure, .serverRejectedRequest, .limitExceeded:
            return true
        default:
            return false
        }
    }
}

// MARK: - Sync Status Tracking
enum SyncStatus {
    case idle
    case syncing
    case failed(CloudKitSyncError)
    case succeeded
    
    var isActive: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
}

// MARK: - Main CloudKitSyncManager Class
class CloudKitSyncManager {
    // MARK: - Singleton instance
    static let shared = CloudKitSyncManager()
    
    // MARK: - Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private let cache = NSCache<NSString, CKRecord>()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var iCloudAvailable: Bool = false
    
    private var syncInProgress = false
    private var pendingOperations: [CKRecord.ID: CKOperation] = [:]
    private var retryCount: [CKRecord.ID: Int] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0 // Base delay in seconds
    
    // MARK: - Initialization
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
        
        // Setup
        setupNotificationObservers()
        checkiCloudAccountStatus()
    }
    
    // MARK: - Public API
    
    /// Fetch records of a specific type with an optional predicate
    /// - Parameters:
    ///   - recordType: The type of record to fetch
    ///   - predicate: Optional predicate to filter records
    ///   - sortDescriptors: Optional sort descriptors for ordering records
    ///   - resultsLimit: Optional limit on the number of results
    ///   - completion: Completion handler with the fetched records or an error
    func fetchRecords<T: CloudKitRecord>(
        ofType recordType: T.Type,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor]? = nil,
        resultsLimit: Int? = nil,
        completion: @escaping (Result<[T], CloudKitSyncError>) -> Void
    ) {
        guard iCloudAvailable else {
            completion(.failure(.iCloudAccountNotAvailable))
            return
        }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        
        var queryOperation: CKQueryOperation
        if let resultsLimit = resultsLimit {
            queryOperation = CKQueryOperation(query: query)
            queryOperation.resultsLimit = resultsLimit
        } else {
            queryOperation = CKQueryOperation(query: query)
        }
        
        var fetchedRecords: [T] = []
        
        queryOperation.recordMatchedBlock = { (recordID, recordResult) in
            switch recordResult {
            case .success(let record):
                // Cache the record
                self.cache.setObject(record, forKey: record.recordID.recordName as NSString)
                
                // Decode the record
                if let decodedRecord = T(from: record) {
                    fetchedRecords.append(decodedRecord)
                } else {
                    print("❌ Failed to decode record of type \(T.recordType): \(record.recordID.recordName)")
                }
                
            case .failure(let error):
                print("❌ Error fetching record \(recordID.recordName): \(error.localizedDescription)")
            }
        }
        
        queryOperation.queryResultBlock = { result in
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                self.syncStatus = .succeeded
                
                switch result {
                case .success:
                    print("✅ Successfully fetched \(fetchedRecords.count) records of type \(T.recordType)")
                    completion(.success(fetchedRecords))
                    
                case .failure(let error):
                    let syncError = CloudKitSyncError(from: error)
                    print("❌ Error fetching records of type \(T.recordType): \(syncError.localizedDescription)")
                    self.syncStatus = .failed(syncError)
                    completion(.failure(syncError))
                }
            }
        }
        
        privateDatabase.add(queryOperation)
    }
    
    /// Save a record to CloudKit with retry logic
    /// - Parameters:
    ///   - record: The record to save, conforming to CloudKitRecord protocol
    ///   - completion: Completion handler with the saved record or an error
    func saveRecord<T: CloudKitRecord>(
        _ record: T,
        completion: @escaping (Result<T, CloudKitSyncError>) -> Void
    ) {
        guard iCloudAvailable else {
            completion(.failure(.iCloudAccountNotAvailable))
            return
        }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        let ckRecord = record.toCKRecord()
        
        // Save to local cache immediately
        cache.setObject(ckRecord, forKey: ckRecord.recordID.recordName as NSString)
        
        // Perform the CloudKit save
        privateDatabase.save(ckRecord) { [weak self] (savedRecord, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    let syncError = CloudKitSyncError(from: error)
                    print("❌ Error saving record of type \(T.recordType): \(syncError.localizedDescription)")
                    self.syncStatus = .failed(syncError)
                    
                    // Attempt retry if appropriate
                    if syncError.isRetriable {
                        let retryCount = self.retryCount[ckRecord.recordID] ?? 0
                        if retryCount < self.maxRetryAttempts {
                            self.retryCount[ckRecord.recordID] = retryCount + 1
                            let delay = self.calculateRetryDelay(attempt: retryCount)
                            
                            print("🔄 Retry attempt \(retryCount + 1) for record \(ckRecord.recordID.recordName) in \(delay) seconds")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                self.saveRecord(record, completion: completion)
                            }
                            return
                        }
                    }
                    
                    // If we reach here, all retries failed or not retriable
                    completion(.failure(syncError))
                    return
                }
                
                guard let savedRecord = savedRecord else {
                    print("❌ Saved record is nil but no error was provided")
                    self.syncStatus = .failed(.validationFailed("Saved record is nil"))
                    completion(.failure(.validationFailed("Saved record is nil")))
                    return
                }
                
                // Update cache with the saved record
                self.cache.setObject(savedRecord, forKey: savedRecord.recordID.recordName as NSString)
                
                // Clear retry count
                self.retryCount[ckRecord.recordID] = nil
                
                // Convert back to the original type
                guard var updatedRecord = record as? T else {
                    self.syncStatus = .failed(.decodingFailed)
                    completion(.failure(.decodingFailed))
                    return
                }
                
                // Update record with any server changes
                updatedRecord.update(from: savedRecord)
                
                print("✅ Successfully saved record of type \(T.recordType): \(savedRecord.recordID.recordName)")
                self.lastSyncDate = Date()
                self.syncStatus = .succeeded
                
                // Return the updated record
                completion(.success(updatedRecord))
            }
        }
    }
    
    /// Delete a record from CloudKit with retry logic
    /// - Parameters:
    ///   - record: The record to delete, conforming to CloudKitRecord protocol
    ///   - completion: Completion handler with success or error
    func deleteRecord<T: CloudKitRecord>(
        _ record: T,
        completion: @escaping (Result<Void, CloudKitSyncError>) -> Void
    ) {
        guard iCloudAvailable else {
            completion(.failure(.iCloudAccountNotAvailable))
            return
        }
        
        guard let recordID = record.recordID else {
            completion(.failure(.validationFailed("Record has no recordID")))
            return
        }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        // Remove from cache immediately
        cache.removeObject(forKey: recordID.recordName as NSString)
        
        // Perform the CloudKit delete
        privateDatabase.delete(withRecordID: recordID) { [weak self] (recordID, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    let syncError = CloudKitSyncError(from: error)
                    print("❌ Error deleting record: \(syncError.localizedDescription)")
                    self.syncStatus = .failed(syncError)
                    
                    // Attempt retry if appropriate
                    if syncError.isRetriable, let recordID = recordID {
                        let retryCount = self.retryCount[recordID] ?? 0
                        if retryCount < self.maxRetryAttempts {
                            self.retryCount[recordID] = retryCount + 1
                            let delay = self.calculateRetryDelay(attempt: retryCount)
                            
                            print("🔄 Retry attempt \(retryCount + 1) for deleting record \(recordID.recordName) in \(delay) seconds")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                self.deleteRecord(record, completion: completion)
                            }
                            return
                        }
                    }
                    
                    // If we reach here, all retries failed or not retriable
                    completion(.failure(syncError))
                    return
                }
                
                // Clear retry count
                if let recordID = recordID {
                    self.retryCount[recordID] = nil
                }
                
                print("✅ Successfully deleted record: \(recordID?.recordName ?? "unknown")")
                self.lastSyncDate = Date()
                self.syncStatus = .succeeded
                
                completion(.success(()))
            }
        }
    }
    
    /// Force a sync operation to refresh data
    func forceSync<T: CloudKitRecord>(
        ofType recordType: T.Type,
        completion: @escaping (Result<[T], CloudKitSyncError>) -> Void
    ) {
        print("🔄 Forcing sync of \(T.recordType)")
        fetchRecords(ofType: recordType, completion: completion)
    }
    
    /// Check if iCloud is available for the current user
    func checkiCloudAccountStatus() {
        container.accountStatus { [weak self] (status, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error checking iCloud account status: \(error.localizedDescription)")
                    self.iCloudAvailable = false
                    return
                }
                
                switch status {
                case .available:
                    print("✅ iCloud account is available")
                    self.iCloudAvailable = true
                case .noAccount:
                    print("⚠️ No iCloud account found")
                    self.iCloudAvailable = false
                case .restricted:
                    print("⚠️ iCloud account is restricted")
                    self.iCloudAvailable = false
                case .couldNotDetermine:
                    print("⚠️ Could not determine iCloud account status")
                    self.iCloudAvailable = false
                @unknown default:
                    print("⚠️ Unknown iCloud account status")
                    self.iCloudAvailable = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate exponential backoff for retry attempts
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        // Use exponential backoff with jitter
        let exponentialDelay = retryDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.5) // Add up to 50% jitter
        return exponentialDelay + (exponentialDelay * jitter)
    }
    
    /// Setup notification observers for app lifecycle events
    private func setupNotificationObservers() {
        // Listen for app foreground event to refresh data
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                print("📱 App entering foreground, checking iCloud status")
                self?.checkiCloudAccountStatus()
            }
            .store(in: &cancellables)
        
        // Listen for iCloud account changes
        NotificationCenter.default.publisher(for: Notification.Name.CKAccountChanged)
            .sink { [weak self] _ in
                print("☁️ iCloud account changed, updating status")
                self?.checkiCloudAccountStatus()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Protocol for CloudKit Records
protocol CloudKitRecord {
    static var recordType: String { get }
    var recordID: CKRecord.ID? { get }
    
    // Convert to CKRecord
    func toCKRecord() -> CKRecord
    
    // Create from CKRecord
    init?(from record: CKRecord)
    
    // Update from CKRecord
    mutating func update(from record: CKRecord)
}

// MARK: - CloudKit Record Extension for MealEntry
extension MealEntry: CloudKitRecord {
    static var recordType: String { return "MealEntry" }
    
    func toCKRecord() -> CKRecord {
        let record: CKRecord
        if let recordID = self.recordID {
            record = CKRecord(recordType: MealEntry.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: MealEntry.recordType)
        }
        
        // Set record values
        record["timestamp"] = self.timestamp
        record["foods"] = try? JSONEncoder().encode(self.foods)
        record["nutritionScore"] = self.nutritionScore
        record["macronutrients"] = try? JSONEncoder().encode(self.macronutrients)
        record["micronutrients"] = try? JSONEncoder().encode(self.micronutrients)
        record["userNotes"] = self.userNotes
        record["isManuallyAdjusted"] = self.isManuallyAdjusted
        record["isDraft"] = self.isDraft
        
        if let imageData = self.imageData {
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: fileURL)
                let imageAsset = CKAsset(fileURL: fileURL)
                record["mealImage"] = imageAsset
            } catch {
                print("❌ Error saving image to temporary directory: \(error.localizedDescription)")
            }
        }
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard record.recordType == MealEntry.recordType,
              let timestamp = record["timestamp"] as? Date,
              let nutritionScore = record["nutritionScore"] as? Int else {
            return nil
        }
        
        // Parse foods
        var foods: [FoodItem] = []
        if let foodsData = record["foods"] as? Data {
            foods = (try? JSONDecoder().decode([FoodItem].self, from: foodsData)) ?? []
        }
        
        // Parse macronutrients
        var macronutrients = MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)
        if let macroData = record["macronutrients"] as? Data {
            macronutrients = (try? JSONDecoder().decode(MacroData.self, from: macroData)) ?? macronutrients
        }
        
        // Parse micronutrients
        var micronutrients = MicroData()
        if let microData = record["micronutrients"] as? Data {
            micronutrients = (try? JSONDecoder().decode(MicroData.self, from: microData)) ?? micronutrients
        }
        
        // Get image if available
        var imageData: Data? = nil
        var imageURL: String? = nil
        if let asset = record["mealImage"] as? CKAsset, let fileURL = asset.fileURL {
            imageData = try? Data(contentsOf: fileURL)
            imageURL = fileURL.absoluteString
        }
        
        self.init(
            id: UUID(),
            timestamp: timestamp,
            imageData: imageData,
            imageURL: imageURL,
            foods: foods,
            nutritionScore: nutritionScore,
            macronutrients: macronutrients,
            micronutrients: micronutrients,
            userNotes: record["userNotes"] as? String,
            isManuallyAdjusted: record["isManuallyAdjusted"] as? Bool ?? false,
            isDraft: record["isDraft"] as? Bool ?? false,
            recordID: record.recordID
        )
    }
    
    mutating func update(from record: CKRecord) {
        self.recordID = record.recordID
    }
}

// MARK: - CloudKit Record Extension for NutritionGoals
extension NutritionGoals: CloudKitRecord {
    static var recordType: String { return "NutritionGoals" }
    
    func toCKRecord() -> CKRecord {
        let recordID = self.recordID ?? CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: NutritionGoals.recordType, recordID: recordID)
        
        record["caloriesGoal"] = caloriesGoal as CKRecordValue
        record["proteinGoal"] = proteinGoal as CKRecordValue
        record["carbsGoal"] = carbsGoal as CKRecordValue
        record["fatGoal"] = fatGoal as CKRecordValue
        record["caloriesProgress"] = caloriesProgress as CKRecordValue
        record["proteinProgress"] = proteinProgress as CKRecordValue
        record["carbsProgress"] = carbsProgress as CKRecordValue
        record["fatProgress"] = fatProgress as CKRecordValue
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard record.recordType == NutritionGoals.recordType else {
            return nil
        }
        
        self.init(
            caloriesGoal: record["caloriesGoal"] as? Int ?? 2000,
            proteinGoal: record["proteinGoal"] as? Double ?? 150,
            carbsGoal: record["carbsGoal"] as? Double ?? 225,
            fatGoal: record["fatGoal"] as? Double ?? 70,
            caloriesProgress: record["caloriesProgress"] as? Int ?? 0,
            proteinProgress: record["proteinProgress"] as? Double ?? 0,
            carbsProgress: record["carbsProgress"] as? Double ?? 0,
            fatProgress: record["fatProgress"] as? Double ?? 0,
            recordID: record.recordID
        )
    }
    
    mutating func update(from record: CKRecord) {
        self.recordID = record.recordID
        self.caloriesGoal = record["caloriesGoal"] as? Int ?? self.caloriesGoal
        self.proteinGoal = record["proteinGoal"] as? Double ?? self.proteinGoal
        self.carbsGoal = record["carbsGoal"] as? Double ?? self.carbsGoal
        self.fatGoal = record["fatGoal"] as? Double ?? self.fatGoal
        self.caloriesProgress = record["caloriesProgress"] as? Int ?? self.caloriesProgress
        self.proteinProgress = record["proteinProgress"] as? Double ?? self.proteinProgress
        self.carbsProgress = record["carbsProgress"] as? Double ?? self.carbsProgress
        self.fatProgress = record["fatProgress"] as? Double ?? self.fatProgress
    }
}

