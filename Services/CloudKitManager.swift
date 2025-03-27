import Foundation
import CloudKit
import SwiftUI

// MARK: - CloudKit Record Type Constants
struct RecordType {
    static let habit = "Habit"
    static let habitCompletion = "HabitCompletion"
    static let moodLog = "MoodLog"
}

// MARK: - CloudKit Key Constants
struct RecordKey {
    // Habit Keys
    struct Habit {
        static let id = "id"
        static let title = "title"
        static let description = "description"
        static let reminderTime = "reminderTime"
        static let frequency = "frequency"
        static let customDays = "customDays"
        static let emoji = "emoji"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }
    
    // Habit Completion Keys
    struct HabitCompletion {
        static let id = "id"
        static let habitID = "habitID"
        static let date = "date"
        static let status = "status"
        static let createdAt = "createdAt"
    }
    
    // Mood Log Keys
    struct MoodLog {
        static let id = "id"
        static let habitID = "habitID"
        static let date = "date"
        static let mood = "mood"
        static let notes = "notes"
        static let createdAt = "createdAt"
    }
}

// MARK: - CloudKit Compatible Models
// These models mirror the app models but are formatted for CloudKit storage

/// CloudKit compatible Habit model
struct CKHabit {
    let id: UUID
    let title: String
    let description: String
    let reminderTime: Date
    let frequency: String
    let customDays: [Int]
    let emoji: String
    let createdAt: Date
    let updatedAt: Date
    
    // Convert to CKRecord for saving to CloudKit
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: RecordType.habit)
        record[RecordKey.Habit.id] = id.uuidString
        record[RecordKey.Habit.title] = title
        record[RecordKey.Habit.description] = description
        record[RecordKey.Habit.reminderTime] = reminderTime
        record[RecordKey.Habit.frequency] = frequency
        record[RecordKey.Habit.customDays] = customDays as CKRecordValue
        record[RecordKey.Habit.emoji] = emoji
        record[RecordKey.Habit.createdAt] = createdAt
        record[RecordKey.Habit.updatedAt] = updatedAt
        return record
    }
    
    // Create from app Habit model
    static func from(habit: Habit) -> CKHabit {
        return CKHabit(
            id: habit.id,
            title: habit.title,
            description: habit.description,
            reminderTime: habit.reminderTime,
            frequency: habit.frequency.rawValue,
            customDays: habit.customDays,
            emoji: habit.emoji,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // Create from CKRecord
    static func from(record: CKRecord) -> CKHabit? {
        guard let idString = record[RecordKey.Habit.id] as? String,
              let id = UUID(uuidString: idString),
              let title = record[RecordKey.Habit.title] as? String,
              let reminderTime = record[RecordKey.Habit.reminderTime] as? Date,
              let frequency = record[RecordKey.Habit.frequency] as? String,
              let emoji = record[RecordKey.Habit.emoji] as? String,
              let createdAt = record[RecordKey.Habit.createdAt] as? Date,
              let updatedAt = record[RecordKey.Habit.updatedAt] as? Date else {
            return nil
        }
        
        let description = record[RecordKey.Habit.description] as? String ?? ""
        let customDays = record[RecordKey.Habit.customDays] as? [Int] ?? []
        
        return CKHabit(
            id: id,
            title: title,
            description: description,
            reminderTime: reminderTime,
            frequency: frequency,
            customDays: customDays,
            emoji: emoji,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// CloudKit compatible Habit Completion model
struct CKHabitCompletion {
    let id: UUID
    let habitID: UUID
    let date: Date
    let status: String
    let createdAt: Date
    
    // Convert to CKRecord for saving to CloudKit
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: RecordType.habitCompletion)
        record[RecordKey.HabitCompletion.id] = id.uuidString
        record[RecordKey.HabitCompletion.habitID] = habitID.uuidString
        record[RecordKey.HabitCompletion.date] = date
        record[RecordKey.HabitCompletion.status] = status
        record[RecordKey.HabitCompletion.createdAt] = createdAt
        return record
    }
    
    // Create from completion status
    static func from(habitID: UUID, date: Date, status: CompletionStatus) -> CKHabitCompletion {
        let statusString: String
        switch status {
        case CompletionStatus.completed:
            statusString = "completed"
        case CompletionStatus.notCompleted:
            statusString = "notCompleted"
        case CompletionStatus.noData:
            statusString = "noData"
        }
        
        return CKHabitCompletion(
            id: UUID(),
            habitID: habitID,
            date: date,
            status: statusString,
            createdAt: Date()
        )
    }
    
    // Create from CKRecord
    static func from(record: CKRecord) -> CKHabitCompletion? {
        guard let idString = record[RecordKey.HabitCompletion.id] as? String,
              let id = UUID(uuidString: idString),
              let habitIDString = record[RecordKey.HabitCompletion.habitID] as? String,
              let habitID = UUID(uuidString: habitIDString),
              let date = record[RecordKey.HabitCompletion.date] as? Date,
              let status = record[RecordKey.HabitCompletion.status] as? String,
              let createdAt = record[RecordKey.HabitCompletion.createdAt] as? Date else {
            return nil
        }
        
        return CKHabitCompletion(
            id: id,
            habitID: habitID,
            date: date,
            status: status,
            createdAt: createdAt
        )
    }
}

/// CloudKit compatible Mood Log model
struct CKMoodLog {
    let id: UUID
    let habitID: UUID
    let date: Date
    let mood: String?
    let notes: String
    let createdAt: Date
    
    // Convert to CKRecord for saving to CloudKit
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: RecordType.moodLog)
        record[RecordKey.MoodLog.id] = id.uuidString
        record[RecordKey.MoodLog.habitID] = habitID.uuidString
        record[RecordKey.MoodLog.date] = date
        record[RecordKey.MoodLog.mood] = mood
        record[RecordKey.MoodLog.notes] = notes
        record[RecordKey.MoodLog.createdAt] = createdAt
        return record
    }
    
    // Create from mood and notes data
    static func from(habitID: UUID, date: Date, mood: String?, notes: String) -> CKMoodLog {
        return CKMoodLog(
            id: UUID(),
            habitID: habitID,
            date: date,
            mood: mood,
            notes: notes,
            createdAt: Date()
        )
    }
    
    // Create from CKRecord
    static func from(record: CKRecord) -> CKMoodLog? {
        guard let idString = record[RecordKey.MoodLog.id] as? String,
              let id = UUID(uuidString: idString),
              let habitIDString = record[RecordKey.MoodLog.habitID] as? String,
              let habitID = UUID(uuidString: habitIDString),
              let date = record[RecordKey.MoodLog.date] as? Date,
              let createdAt = record[RecordKey.MoodLog.createdAt] as? Date else {
            return nil
        }
        
        let mood = record[RecordKey.MoodLog.mood] as? String
        let notes = record[RecordKey.MoodLog.notes] as? String ?? ""
        
        return CKMoodLog(
            id: id,
            habitID: habitID,
            date: date,
            mood: mood,
            notes: notes,
            createdAt: createdAt
        )
    }
}

// MARK: - CloudKit Manager
class CloudKitManager: ObservableObject {
    // MARK: - Properties
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let publicDB: CKDatabase
    private let privateDB: CKDatabase
    
    // Published property for UI updates
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine
    
    // Flag to prevent multiple schema initializations
    private var hasInitializedSchema = false
    private var isCreatingSchema = false
    
    // MARK: - Initialization
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        
        // Check iCloud account status
        checkAccountStatus()
        
        // Initialize CloudKit schemas
        initializeCloudKitSchemas()
    }
    
    // Check iCloud account status
    private func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.iCloudAccountStatus = status
                
                if let error = error {
                    print("[CloudKitError] Account status error: \(error.localizedDescription)")
                } else {
                    if status == .available {
                        print("[CloudKit] iCloud account is available")
                    } else {
                        print("[CloudKitError] iCloud account is not available: \(status)")
                    }
                }
            }
        }
    }
    
    // Initialize CloudKit schemas on startup
    private func initializeCloudKitSchemas() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Create record zones first
            if let operation = self.createHabitSchema() {
                let zoneQueue = OperationQueue()
                zoneQueue.addOperation(operation)
                zoneQueue.waitUntilAllOperationsAreFinished()
            }
            
            // Then create record types by initializing sample records
            let operations = [
                self.createHabitCompletionSchema(),
                self.createMoodLogSchema()
            ].compactMap { $0 }
            
            if !operations.isEmpty {
                let operationQueue = OperationQueue()
                operationQueue.maxConcurrentOperationCount = 1
                operationQueue.addOperations(operations, waitUntilFinished: true)
                print("[CloudKit] Schema initialization completed")
            }
        }
    }
    
    // MARK: - Habit Methods
    
    /// Save a habit to CloudKit
    /// - Parameter habit: The habit to save
    /// - Parameter completion: Completion handler with result
    func saveHabit(_ habit: Habit, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        let ckHabit = CKHabit.from(habit: habit)
        let record = ckHabit.toCKRecord()
        
        privateDB.save(record) { [weak self] record, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error saving habit to CloudKit: \(error.localizedDescription)")
                
                // Check if the error is because Habit record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("Habit") {
                    print("[CloudKitError] Habit record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createHabitSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry saving after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.saveHabit(habit, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                let error = NSError(domain: "CloudKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Unknown error saving habit"])
                completion(.failure(error))
                return
            }
            
            print("[CloudKit] Successfully saved habit to CloudKit with ID: \(record.recordID)")
            completion(.success(record.recordID))
        }
    }
    
    /// Fetch all habits from CloudKit
    /// - Parameter completion: Completion handler with result
    func fetchHabits(completion: @escaping (Result<[CKHabit], Error>) -> Void) {
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        let query = CKQuery(recordType: RecordType.habit, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.Habit.createdAt, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastSyncDate = Date()
            }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error fetching habits from CloudKit: \(error.localizedDescription)")
                
                // Check if the error is because Habit record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("Habit") {
                    print("[CloudKitError] Habit record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createHabitSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry fetching after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchHabits(completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let habits = records.compactMap { CKHabit.from(record: $0) }
            print("[CloudKit] Successfully fetched \(habits.count) habits from CloudKit")
            completion(.success(habits))
        }
    }
    
    /// Delete a habit from CloudKit
    /// - Parameters:
    ///   - habitID: The ID of the habit to delete
    ///   - completion: Completion handler with result
    func deleteHabit(habitID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        // First, find the record ID
        let predicate = NSPredicate(format: "%K == %@", RecordKey.Habit.id, habitID.uuidString)
        let query = CKQuery(recordType: RecordType.habit, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error finding habit to delete: \(error.localizedDescription)")
                
                // Check if the error is because Habit record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("Habit") {
                    print("[CloudKitError] Habit record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createHabitSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry deletion after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.deleteHabit(habitID: habitID, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first else {
                let error = NSError(domain: "CloudKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Habit not found for deletion"])
                completion(.failure(error))
                return
            }
            
            // Now delete the record
            self.privateDB.delete(withRecordID: record.recordID) { _, error in
                if let error = error {
                    print("[CloudKitError] Error deleting habit from CloudKit: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("[CloudKit] Successfully deleted habit from CloudKit")
                completion(.success(()))
                
                // Also delete related completions and mood logs
                self.deleteRelatedRecords(forHabitID: habitID)
            }
        }
    }
    
    /// Delete related records (completions and mood logs) for a habit
    /// - Parameter habitID: The ID of the habit
    private func deleteRelatedRecords(forHabitID habitID: UUID) {
        // Delete completions
        let completionPredicate = NSPredicate(format: "%K == %@", RecordKey.HabitCompletion.habitID, habitID.uuidString)
        let completionQuery = CKQuery(recordType: RecordType.habitCompletion, predicate: completionPredicate)
        
        privateDB.perform(completionQuery, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error finding completions to delete: \(error.localizedDescription)")
                
                // If the error is because the record type doesn't exist, that's okay
                if error.code == .unknownItem {
                    print("[CloudKitError] No HabitCompletion records found to delete (record type may not exist yet)")
                }
                return
            }
            
            guard let records = records, !records.isEmpty else {
                return
            }
            
            // Delete each completion record
            for record in records {
                self.privateDB.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("[CloudKitError] Error deleting completion: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Delete mood logs
        let moodPredicate = NSPredicate(format: "%K == %@", RecordKey.MoodLog.habitID, habitID.uuidString)
        let moodQuery = CKQuery(recordType: RecordType.moodLog, predicate: moodPredicate)
        
        privateDB.perform(moodQuery, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error finding mood logs to delete: \(error.localizedDescription)")
                
                // If the error is because the record type doesn't exist, that's okay
                if error.code == .unknownItem {
                    print("[CloudKitError] No MoodLog records found to delete (record type may not exist yet)")
                }
                return
            }
            
            guard let records = records, !records.isEmpty else {
                return
            }
            
            // Delete each mood log record
            for record in records {
                self.privateDB.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("[CloudKitError] Error deleting mood log: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Habit Completion Methods
    
    /// Save a habit completion to CloudKit using string status
    /// - Parameters:
    ///   - habitID: The ID of the habit
    ///   - date: The date of completion
    ///   - status: The completion status as a string ("completed", "notCompleted", "noData")
    ///   - completion: Completion handler with result
    func saveHabitCompletion(habitID: UUID, date: Date, status: String, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        // Try to convert string to CompletionStatus
        guard let completionStatus = CompletionStatus(fromString: status) else {
            let error = NSError(domain: "CloudKitManager", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid status string: \(status)"])
            completion(.failure(error))
            return
        }
        
        // Call the main implementation with the enum value
        saveHabitCompletion(habitID: habitID, date: date, status: completionStatus, completion: completion)
    }
    
    /// Save a habit completion to CloudKit
    /// - Parameters:
    ///   - habitID: The ID of the habit
    ///   - date: The date of completion
    ///   - status: The completion status
    ///   - completion: Completion handler with result
    func saveHabitCompletion(habitID: UUID, date: Date, status: CompletionStatus, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        // For querying existing completions, we still use the date portion to find any completions on the same day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        // Use a date range to find completions on the same day
        let predicate = NSPredicate(format: "%K == %@ AND %K >= %@ AND %K <= %@", 
                                  RecordKey.HabitCompletion.habitID, habitID.uuidString,
                                  RecordKey.HabitCompletion.date, startOfDay as NSDate,
                                  RecordKey.HabitCompletion.date, endOfDay as NSDate)
        let query = CKQuery(recordType: RecordType.habitCompletion, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error checking for existing habit completion: \(error.localizedDescription)")
                
                // Check if the error is because HabitCompletion record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("HabitCompletion") {
                    print("[CloudKitError] HabitCompletion record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createHabitCompletionSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry saving after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.saveHabitCompletion(habitID: habitID, date: date, status: status, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            // If we found an existing record, update it with the new timestamp and status
            if let existingRecord = records?.first {
                existingRecord[RecordKey.HabitCompletion.status] = status.stringValue
                // Update the date to preserve the exact completion time
                existingRecord[RecordKey.HabitCompletion.date] = date
                
                self.privateDB.save(existingRecord) { record, error in
                    if let error = error {
                        print("[CloudKitError] Error updating habit completion: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let record = record else {
                        let error = NSError(domain: "CloudKitManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Unknown error updating habit completion"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("[CloudKit] Successfully updated habit completion with exact time: \(date)")
                    completion(.success(record.recordID))
                }
            } else {
                // Create a new record with the exact date and time
                let ckCompletion = CKHabitCompletion.from(habitID: habitID, date: date, status: status)
                let record = ckCompletion.toCKRecord()
                
                self.privateDB.save(record) { record, error in
                    if let error = error as? CKError {
                        print("[CloudKitError] Error saving habit completion: \(error.localizedDescription)")
                        
                        // Check if the error is because the record type doesn't exist
                        if error.code == .unknownItem && error.localizedDescription.contains("HabitCompletion") {
                            print("[CloudKitError] HabitCompletion record type doesn't exist. Attempting to create schema...")
                            
                            // Try to create the schema and retry
                            if let operation = self.createHabitCompletionSchema() {
                                let operationQueue = OperationQueue()
                                operationQueue.addOperation(operation)
                                operationQueue.waitUntilAllOperationsAreFinished()
                                
                                // Retry saving after creating schema
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.saveHabitCompletion(habitID: habitID, date: date, status: status, completion: completion)
                                }
                                return
                            }
                        }
                        
                        completion(.failure(error))
                        return
                    }
                    
                    guard let record = record else {
                        let error = NSError(domain: "CloudKitManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Unknown error saving habit completion"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("[CloudKit] Successfully saved habit completion with exact time: \(date)")
                    completion(.success(record.recordID))
                }
            }
        }
    }
    
    /// Fetch all habit completions for a specific habit
    /// - Parameters:
    ///   - habitID: The ID of the habit
    ///   - completion: Completion handler with result
    func fetchHabitCompletions(habitID: UUID, completion: @escaping (Result<[CKHabitCompletion], Error>) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", RecordKey.HabitCompletion.habitID, habitID.uuidString)
        let query = CKQuery(recordType: RecordType.habitCompletion, predicate: predicate)
        
        // Sort by date in descending order (newest first) to show the most recent completions at the top
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.HabitCompletion.date, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error fetching habit completions: \(error.localizedDescription)")
                
                // Check if the error is because HabitCompletion record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("HabitCompletion") {
                    print("[CloudKitError] HabitCompletion record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createHabitCompletionSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry fetching after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchHabitCompletions(habitID: habitID, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let completions = records.compactMap { CKHabitCompletion.from(record: $0) }
            print("[CloudKit] Successfully fetched \(completions.count) habit completions with exact times")
            
            // Log the first few completion dates if available
            if !completions.isEmpty {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                
                let sampleDates = completions.prefix(3).map { dateFormatter.string(from: $0.date) }
                print("[CloudKit] Sample completion dates with times: \(sampleDates.joined(separator: ", "))")
            }
            
            completion(.success(completions))
        }
    }
    
    /// Fetch all habit completions for the user
    /// - Parameter completion: Completion handler with result
    func fetchAllHabitCompletions(completion: @escaping (Result<[CKHabitCompletion], Error>) -> Void) {
        let query = CKQuery(recordType: RecordType.habitCompletion, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.HabitCompletion.date, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error fetching all habit completions: \(error.localizedDescription)")
                
                // Check if the error is because HabitCompletion record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("HabitCompletion") {
                    print("[CloudKitError] HabitCompletion record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createHabitCompletionSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry fetching after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchAllHabitCompletions(completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let completions = records.compactMap { CKHabitCompletion.from(record: $0) }
            print("[CloudKit] Successfully fetched \(completions.count) total habit completions")
            completion(.success(completions))
        }
    }
    
    /// Delete a habit completion from CloudKit
    /// - Parameters:
    ///   - completionID: The ID of the completion to delete
    ///   - completion: Completion handler with result
    func deleteHabitCompletion(completionID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", RecordKey.HabitCompletion.id, completionID.uuidString)
        let query = CKQuery(recordType: RecordType.habitCompletion, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error finding habit completion to delete: \(error.localizedDescription)")
                
                // Check if the error is because HabitCompletion record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("HabitCompletion") {
                    print("[CloudKitError] HabitCompletion record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createHabitCompletionSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry deletion after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.deleteHabitCompletion(completionID: completionID, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first else {
                let error = NSError(domain: "CloudKitManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Habit completion not found for deletion"])
                completion(.failure(error))
                return
            }
            
            self.privateDB.delete(withRecordID: record.recordID) { _, error in
                if let error = error {
                    print("[CloudKitError] Error deleting habit completion: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("[CloudKit] Successfully deleted habit completion")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Mood Log Methods
    
    /// Save a mood log to CloudKit
    /// - Parameters:
    ///   - habitID: The ID of the habit
    ///   - date: The date of the mood log
    ///   - mood: The mood emoji
    ///   - notes: Additional notes for the mood
    ///   - completion: Completion handler with result
    func saveMoodLog(habitID: UUID, date: Date, mood: String?, notes: String, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        // Check if there's an existing mood log for this habit and date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let predicate = NSPredicate(format: "%K == %@ AND %K == %@", 
                                  RecordKey.MoodLog.habitID, habitID.uuidString,
                                  RecordKey.MoodLog.date, startOfDay as NSDate)
        let query = CKQuery(recordType: RecordType.moodLog, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error checking for existing mood log: \(error.localizedDescription)")
                
                // Check if the error is because MoodLog record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("MoodLog") {
                    print("[CloudKitError] MoodLog record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createMoodLogSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry saving after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.saveMoodLog(habitID: habitID, date: date, mood: mood, notes: notes, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            // If we found an existing record, fetch the latest version before updating
            if let existingRecord = records?.first {
                // Get the record ID to fetch the latest version
                let recordID = existingRecord.recordID
                
                // Fetch the latest version of the record to avoid optimistic locking conflicts
                self.privateDB.fetch(withRecordID: recordID) { latestRecord, fetchError in
                    if let fetchError = fetchError {
                        print("[CloudKitError] Error fetching latest mood log record: \(fetchError.localizedDescription)")
                        completion(.failure(fetchError))
                        return
                    }
                    
                    guard var recordToUpdate = latestRecord else {
                        let error = NSError(domain: "CloudKitManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Could not fetch latest mood log record"])
                        completion(.failure(error))
                        return
                    }
                    
                    // Apply updates to the latest record
                    recordToUpdate[RecordKey.MoodLog.mood] = mood
                    recordToUpdate[RecordKey.MoodLog.notes] = notes
                    
                    // Save the updated record
                    self.privateDB.save(recordToUpdate) { savedRecord, saveError in
                        if let saveError = saveError {
                            print("[CloudKitError] Error updating mood log: \(saveError.localizedDescription)")
                            completion(.failure(saveError))
                            return
                        }
                        
                        guard let savedRecord = savedRecord else {
                            let error = NSError(domain: "CloudKitManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Unknown error updating mood log"])
                            completion(.failure(error))
                            return
                        }
                        
                        print("[CloudKit] Successfully updated mood log with safe update pattern")
                        completion(.success(savedRecord.recordID))
                    }
                }
            } else {
                // Create a new record - this path remains unchanged as it doesn't have optimistic locking concerns
                let ckMoodLog = CKMoodLog(
                    id: UUID(),
                    habitID: habitID,
                    date: startOfDay,
                    mood: mood,
                    notes: notes,
                    createdAt: Date()
                )
                let record = ckMoodLog.toCKRecord()
                
                self.privateDB.save(record) { record, error in
                    if let error = error as? CKError {
                        print("[CloudKitError] Error saving mood log: \(error.localizedDescription)")
                        
                        // Check if the error is because the record type doesn't exist
                        if error.code == .unknownItem && error.localizedDescription.contains("MoodLog") {
                            print("[CloudKitError] MoodLog record type doesn't exist. Attempting to create schema...")
                            
                            // Try to create the schema and retry
                            if let operation = self.createMoodLogSchema() {
                                let operationQueue = OperationQueue()
                                operationQueue.addOperation(operation)
                                operationQueue.waitUntilAllOperationsAreFinished()
                                
                                // Retry saving after creating schema
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.saveMoodLog(habitID: habitID, date: date, mood: mood, notes: notes, completion: completion)
                                }
                                return
                            }
                        }
                        
                        completion(.failure(error))
                        return
                    }
                    
                    guard let record = record else {
                        let error = NSError(domain: "CloudKitManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Unknown error saving mood log"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("[CloudKit] Successfully saved new mood log")
                    completion(.success(record.recordID))
                }
            }
        }
    }
    
    /// Fetch all mood logs for a specific habit
    /// - Parameters:
    ///   - habitID: The ID of the habit
    ///   - completion: Completion handler with result
    func fetchMoodLogs(habitID: UUID, completion: @escaping (Result<[CKMoodLog], Error>) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", RecordKey.MoodLog.habitID, habitID.uuidString)
        let query = CKQuery(recordType: RecordType.moodLog, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.MoodLog.date, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error fetching mood logs: \(error.localizedDescription)")
                
                // Check if the error is because MoodLog record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("MoodLog") {
                    print("[CloudKitError] MoodLog record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createMoodLogSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry fetching after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchMoodLogs(habitID: habitID, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let moodLogs = records.compactMap { CKMoodLog.from(record: $0) }
            print("[CloudKit] Successfully fetched \(moodLogs.count) mood logs")
            completion(.success(moodLogs))
        }
    }
    
    /// Fetch all mood logs for the user
    /// - Parameter completion: Completion handler with result
    func fetchAllMoodLogs(completion: @escaping (Result<[CKMoodLog], Error>) -> Void) {
        let query = CKQuery(recordType: RecordType.moodLog, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.MoodLog.date, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error fetching all mood logs: \(error.localizedDescription)")
                
                // Check if the error is because MoodLog record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("MoodLog") {
                    print("[CloudKitError] MoodLog record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createMoodLogSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry fetching after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchAllMoodLogs(completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let moodLogs = records.compactMap { CKMoodLog.from(record: $0) }
            print("[CloudKit] Successfully fetched \(moodLogs.count) total mood logs")
            completion(.success(moodLogs))
        }
    }
    
    /// Delete a mood log from CloudKit
    /// - Parameters:
    ///   - moodLogID: The ID of the mood log to delete
    ///   - completion: Completion handler with result
    func deleteMoodLog(moodLogID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", RecordKey.MoodLog.id, moodLogID.uuidString)
        let query = CKQuery(recordType: RecordType.moodLog, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error as? CKError {
                print("[CloudKitError] Error finding mood log to delete: \(error.localizedDescription)")
                
                // Check if the error is because MoodLog record type doesn't exist
                if error.code == .unknownItem && error.localizedDescription.contains("MoodLog") {
                    print("[CloudKitError] MoodLog record type doesn't exist. Attempting to create schema...")
                    
                    // Try to create the schema and retry
                    if let operation = self.createMoodLogSchema() {
                        let operationQueue = OperationQueue()
                        operationQueue.addOperation(operation)
                        operationQueue.waitUntilAllOperationsAreFinished()
                        
                        // Retry deletion after creating schema
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.deleteMoodLog(moodLogID: moodLogID, completion: completion)
                        }
                        return
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first else {
                let error = NSError(domain: "CloudKitManager", code: 8, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] Mood log not found for deletion"])
                completion(.failure(error))
                return
            }
            
            self.privateDB.delete(withRecordID: record.recordID) { _, error in
                if let error = error {
                    print("[CloudKitError] Error deleting mood log: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("[CloudKit] Successfully deleted mood log")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - CloudKit Schema Management
    
    /// Force initialization of CloudKit schemas
    /// - Parameter completion: Optional completion handler
    public func forceSchemaInitialization(completion: ((Bool) -> Void)? = nil) {
        // Prevent multiple concurrent initializations
        if isCreatingSchema {
            print("[CloudKit] Schema initialization already in progress, skipping.")
            completion?(false)
            return
        }
        
        // Skip if already initialized successfully
        if hasInitializedSchema {
            print("[CloudKit] Schema already initialized, skipping.")
            completion?(true)
            return
        }
        
        isCreatingSchema = true
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { 
                completion?(false)
                return 
            }
            
            // Create record zones first
            if let operation = self.createHabitSchema() {
                let zoneQueue = OperationQueue()
                zoneQueue.addOperation(operation)
                zoneQueue.waitUntilAllOperationsAreFinished()
            }
            
            // Then create record types by initializing sample records
            let operations = [
                self.createHabitCompletionSchema(),
                self.createMoodLogSchema()
            ].compactMap { $0 }
            
            if !operations.isEmpty {
                let operationQueue = OperationQueue()
                operationQueue.maxConcurrentOperationCount = 1
                operationQueue.addOperations(operations, waitUntilFinished: true)
                print("[CloudKit] Schema initialization completed")
            }
            
            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastSyncDate = Date()
                self.hasInitializedSchema = true
                self.isCreatingSchema = false
                completion?(true)
            }
        }
    }
    
    /// Create CloudKit schema programmatically
    /// Call this method once to set up the CloudKit schema
    func createCloudKitSchema(completion: @escaping (Bool) -> Void) {
        // This is typically handled by CloudKit Dashboard, but we can ensure records are properly defined
        let operations = [createHabitSchema(), createHabitCompletionSchema(), createMoodLogSchema()].compactMap { $0 }
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperations(operations, waitUntilFinished: true)
        
        print("[CloudKit] Schema migration completed")
        completion(true)
    }
    
    private func createHabitSchema() -> CKOperation? {
        // Create the zone first
        let recordZone = CKRecordZone(zoneName: "HabitZone")
        let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: nil)
        
        createZoneOperation.modifyRecordZonesCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[CloudKitError] Error creating habit zone: \(error.localizedDescription)")
                return
            }
            
            print("[CloudKit] Successfully created habit zone")
            
            // Create a sample Habit record with a consistent UUID to register the record type
            // This ensures we can find it later by ID, not recordName
            let habitUUID = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()
            
            // Note: We still use recordName for the CKRecord.ID creation (this is fine)
            // but not for future queries
            let recordID = CKRecord.ID(recordName: "SampleHabit", zoneID: CKRecordZone.ID(zoneName: "HabitZone", ownerName: CKCurrentUserDefaultName))
            let record = CKRecord(recordType: RecordType.habit, recordID: recordID)
            
            // Add required fields
            record[RecordKey.Habit.id] = habitUUID.uuidString // Use consistent UUID string for sample record
            record[RecordKey.Habit.title] = "Sample Habit"
            record[RecordKey.Habit.description] = "Schema initialization sample"
            record[RecordKey.Habit.reminderTime] = Date()
            record[RecordKey.Habit.frequency] = "daily"
            record[RecordKey.Habit.customDays] = [1,2,3,4,5,6,7]
            record[RecordKey.Habit.emoji] = "🔄"
            record[RecordKey.Habit.createdAt] = Date()
            record[RecordKey.Habit.updatedAt] = Date()
            
            // Save the sample record to register the record type
            self.privateDB.save(record) { savedRecord, saveError in
                if let saveError = saveError {
                    print("[CloudKitError] Error creating Habit record type: \(saveError.localizedDescription)")
                    return
                }
                
                print("[CloudKit] Successfully registered Habit record type")
                
                // Delete the sample record - using the recordID is still appropriate here
                // since we have a direct reference to it
                if let savedRecord = savedRecord {
                    self.privateDB.delete(withRecordID: savedRecord.recordID) { _, deleteError in
                        if let deleteError = deleteError {
                            print("[CloudKitError] Error cleaning up sample Habit record: \(deleteError.localizedDescription)")
                        } else {
                            print("[CloudKit] Successfully cleaned up sample Habit record")
                        }
                    }
                }
                
                // Also fetch by custom ID to verify the schema and custom ID field work properly
                self.verifySchemaSetup(recordType: RecordType.habit, idFieldKey: RecordKey.Habit.id, idValue: habitUUID.uuidString)
            }
        }
        
        return createZoneOperation
    }
    
    private func createHabitCompletionSchema() -> CKOperation? {
        // Create a sample habit completion record with consistent UUID to initialize the schema
        let sampleCompletionUUID = UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID()
        
        // Note: We still use recordName for CKRecord.ID, but not for queries
        let recordID = CKRecord.ID(recordName: "SampleHabitCompletion")
        let record = CKRecord(recordType: RecordType.habitCompletion, recordID: recordID)
        record[RecordKey.HabitCompletion.id] = sampleCompletionUUID.uuidString // Use consistent ID
        record[RecordKey.HabitCompletion.habitID] = UUID().uuidString
        record[RecordKey.HabitCompletion.date] = Date()
        record[RecordKey.HabitCompletion.status] = "completed"
        record[RecordKey.HabitCompletion.createdAt] = Date()
        
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }
            
            if let error = error {
                // This may fail if the record already exists, which is fine
                print("[CloudKitError] Note: HabitCompletion schema initialization: \(error.localizedDescription)")
                return
            }
            print("[CloudKit] Successfully initialized HabitCompletion schema")
            
            // Verify schema setup using custom ID
            self.verifySchemaSetup(recordType: RecordType.habitCompletion, 
                                  idFieldKey: RecordKey.HabitCompletion.id, 
                                  idValue: sampleCompletionUUID.uuidString)
            
            // Now delete the sample record - using recordID is fine here
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
            deleteOperation.modifyRecordsCompletionBlock = { _, _, deleteError in
                if let deleteError = deleteError {
                    print("[CloudKitError] Could not clean up sample HabitCompletion record: \(deleteError.localizedDescription)")
                    return
                }
                print("[CloudKit] Successfully cleaned up HabitCompletion sample record")
            }
            CKContainer.default().privateCloudDatabase.add(deleteOperation)
        }
        
        return operation
    }
    
    private func createMoodLogSchema() -> CKOperation? {
        // Create a sample mood log record with consistent UUID to initialize the schema
        let sampleMoodLogUUID = UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID()
        
        // Note: We still use recordName for CKRecord.ID, but not for queries
        let recordID = CKRecord.ID(recordName: "SampleMoodLog")
        let record = CKRecord(recordType: RecordType.moodLog, recordID: recordID)
        record[RecordKey.MoodLog.id] = sampleMoodLogUUID.uuidString // Use consistent ID
        record[RecordKey.MoodLog.habitID] = UUID().uuidString
        record[RecordKey.MoodLog.date] = Date()
        record[RecordKey.MoodLog.mood] = "happy"
        record[RecordKey.MoodLog.notes] = "Sample note"
        record[RecordKey.MoodLog.createdAt] = Date()
        
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }
            
            if let error = error {
                // This may fail if the record already exists, which is fine
                print("[CloudKitError] Note: MoodLog schema initialization: \(error.localizedDescription)")
                return
            }
            print("[CloudKit] Successfully initialized MoodLog schema")
            
            // Verify schema setup using custom ID
            self.verifySchemaSetup(recordType: RecordType.moodLog, 
                                  idFieldKey: RecordKey.MoodLog.id, 
                                  idValue: sampleMoodLogUUID.uuidString)
            
            // Now delete the sample record - using recordID is fine here
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
            deleteOperation.modifyRecordsCompletionBlock = { _, _, deleteError in
                if let deleteError = deleteError {
                    print("[CloudKitError] Could not clean up sample MoodLog record: \(deleteError.localizedDescription)")
                    return
                }
                print("[CloudKit] Successfully cleaned up MoodLog sample record")
            }
            CKContainer.default().privateCloudDatabase.add(deleteOperation)
        }
        
        return operation
    }
    
    /// Verifies schema setup by querying a record by its custom ID
    private func verifySchemaSetup(recordType: String, idFieldKey: String, idValue: String) {
        // Use custom ID field for verification, not recordName
        let predicate = NSPredicate(format: "%K == %@", idFieldKey, idValue)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("[CloudKitError] Schema verification error for \(recordType): \(error.localizedDescription)")
            } else if let records = records, !records.isEmpty {
                print("[CloudKit] Schema verification successful for \(recordType) - custom ID field is queryable")
            } else {
                print("[CloudKitWarning] Schema verification could not find sample \(recordType) record by custom ID")
            }
        }
    }
    
    // MARK: - Debugging Utilities
    
    /// Debug utility: Print info about a CloudKit record
    func debugRecordInfo(_ record: CKRecord, operation: String) {
        let recordID = record.recordID
        let recordType = record.recordType
        let zoneID = record.recordID.zoneID
        
        print("🔍 [CloudKitDebug] \(operation) RECORD INFO:")
        print("  • Record ID: \(recordID.recordName)")
        print("  • Record Type: \(recordType)")
        print("  • Zone Name: \(zoneID.zoneName)")
        print("  • Zone Owner: \(zoneID.ownerName)")
        
        // Print all fields and values
        print("  • Fields:")
        for key in record.allKeys() {
            print("    - \(key): \(String(describing: record[key]))")
        }
        print("🔍 [CloudKitDebug] END RECORD INFO")
    }
    
    /// Debug utility: Check available zones and record types
    func debugDatabaseInfo(completion: (() -> Void)? = nil) {
        print("🔍 [CloudKitDebug] Checking CloudKit database structure...")
        
        // List all zones
        privateDB.fetchAllRecordZones { zones, error in
            if let error = error {
                print("🔍 [CloudKitDebug] Error fetching zones: \(error.localizedDescription)")
            } else if let zones = zones {
                print("🔍 [CloudKitDebug] Available zones (\(zones.count)):")
                for zone in zones {
                    print("  • \(zone.zoneID.zoneName) (owner: \(zone.zoneID.ownerName))")
                }
            }
            
            // Check if record types exist by attempting to create sample queries
            let recordTypes = [RecordType.habit, RecordType.habitCompletion, RecordType.moodLog]
            
            for recordType in recordTypes {
                // Use custom id field for querying instead of recordName
                let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                
                // Ensure sort descriptors use queryable fields
                if recordType == RecordType.habit {
                    query.sortDescriptors = [NSSortDescriptor(key: RecordKey.Habit.createdAt, ascending: false)]
                } else if recordType == RecordType.habitCompletion {
                    query.sortDescriptors = [NSSortDescriptor(key: RecordKey.HabitCompletion.createdAt, ascending: false)]
                } else if recordType == RecordType.moodLog {
                    query.sortDescriptors = [NSSortDescriptor(key: RecordKey.MoodLog.createdAt, ascending: false)]
                }
                
                self.privateDB.perform(query, inZoneWith: nil) { records, error in
                    if let error = error {
                        print("🔍 [CloudKitDebug] Record type \(recordType) error: \(error.localizedDescription)")
                    } else {
                        let count = records?.count ?? 0
                        print("🔍 [CloudKitDebug] Record type \(recordType) is valid with \(count) records")
                        
                        // Verify that records have the custom ID field
                        if let firstRecord = records?.first {
                            var customIDExists = false
                            if recordType == RecordType.habit {
                                customIDExists = firstRecord[RecordKey.Habit.id] != nil
                            } else if recordType == RecordType.habitCompletion {
                                customIDExists = firstRecord[RecordKey.HabitCompletion.id] != nil
                            } else if recordType == RecordType.moodLog {
                                customIDExists = firstRecord[RecordKey.MoodLog.id] != nil
                            }
                            
                            if customIDExists {
                                print("🔍 [CloudKitDebug] Custom ID field verified for \(recordType)")
                            } else {
                                print("🔍 [CloudKitDebug] WARNING: Custom ID field missing for \(recordType)")
                            }
                        }
                    }
                }
            }
            
            completion?()
        }
    }
    
    // MARK: - Error Handling
    
    /// Handle CloudKit errors in a standardized way
    /// - Parameter error: The CloudKit error to handle
    /// - Returns: A user-friendly error message or nil if the error was handled
    func handleCloudKitError(_ error: Error) -> String? {
        let ckError = error as NSError
        
        switch ckError.code {
        case CKError.networkFailure.rawValue:
            return "[CloudKitError] Network connection is unavailable. Please check your connection and try again."
        case CKError.notAuthenticated.rawValue:
            return "[CloudKitError] Please sign in to iCloud to use CloudKit features."
        case CKError.quotaExceeded.rawValue:
            return "[CloudKitError] Your iCloud storage quota has been exceeded."
        case CKError.serverResponseLost.rawValue, CKError.serviceUnavailable.rawValue:
            return "[CloudKitError] CloudKit service is currently unavailable. Please try again later."
        case CKError.incompatibleVersion.rawValue:
            return "[CloudKitError] Please update your app to use this feature."
        case CKError.invalidArguments.rawValue:
            if ckError.localizedDescription.contains("recordName") {
                // Handle recordName not queryable errors
                print("[CloudKitError] Query attempted on recordName field which is not queryable. Using custom ID field instead.")
                return "[CloudKitError] Internal CloudKit query issue. Using alternate method to fetch data."
            }
            if ckError.localizedDescription.contains("not marked queryable") {
                print("[CloudKitError] Field is not marked queryable. Verify schema in CloudKit Dashboard.")
                return "[CloudKitError] Internal CloudKit query issue. Please try again."
            }
            return "[CloudKitError] Invalid arguments in CloudKit operation. Please try again."
        case CKError.internalError.rawValue:
            // Try to create the schema if it doesn't exist
            self.createCloudKitSchema { _ in }
            return "[CloudKitError] CloudKit internal error. Please try again."
        case CKError.partialFailure.rawValue:
            // This might be related to schema changes
            self.createCloudKitSchema { _ in }
            return "[CloudKitError] CloudKit operation partially failed. Please try again."
        case CKError.zoneNotFound.rawValue:
            // Try to create the zone if it doesn't exist
            _ = self.createHabitSchema()
            return "[CloudKitError] CloudKit zone not found. Please try again."
        case CKError.unknownItem.rawValue:
            if ckError.localizedDescription.contains("MoodLog") {
                _ = self.createMoodLogSchema()
                return "[CloudKitError] MoodLog schema not found. Creating and retrying..."
            } else if ckError.localizedDescription.contains("HabitCompletion") {
                _ = self.createHabitCompletionSchema()
                return "[CloudKitError] HabitCompletion schema not found. Creating and retrying..."
            } else if ckError.localizedDescription.contains("Habit") {
                _ = self.createHabitSchema()
                return "[CloudKitError] Habit schema not found. Creating and retrying..."
            }
            return "[CloudKitError] Unknown CloudKit item. Please try again."
        default:
            print("[CloudKitError] Unhandled CloudKit error: \(error.localizedDescription)")
            return "[CloudKitError] An unexpected error occurred. Please try again."
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to fetch a record by its custom ID (not recordName)
    /// - Parameters:
    ///   - id: The UUID of the record in string format
    ///   - recordType: The record type to fetch
    ///   - idFieldKey: The key for the ID field in this record type
    ///   - completion: Completion handler with the found record or error
    private func fetchRecordByCustomID(id: String, recordType: String, idFieldKey: String, completion: @escaping (CKRecord?, Error?) -> Void) {
        // Always use the custom ID field, never recordName
        let predicate = NSPredicate(format: "%K == %@", idFieldKey, id)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("[CloudKitError] Error fetching \(recordType) by custom ID: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let record = records?.first else {
                let error = NSError(domain: "CloudKitManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "[CloudKitError] \(recordType) with ID \(id) not found"])
                completion(nil, error)
                return
            }
            
            completion(record, nil)
        }
    }
    
    /// Fetch a habit record by its custom ID
    /// - Parameters:
    ///   - habitID: The UUID of the habit
    ///   - completion: Completion handler with the found record or error
    func fetchHabitRecordByCustomID(habitID: UUID, completion: @escaping (CKRecord?, Error?) -> Void) {
        fetchRecordByCustomID(id: habitID.uuidString, recordType: RecordType.habit, idFieldKey: RecordKey.Habit.id, completion: completion)
    }
    
    /// Fetch a habit completion record by its custom ID
    /// - Parameters:
    ///   - completionID: The UUID of the completion
    ///   - completion: Completion handler with the found record or error
    func fetchHabitCompletionRecordByCustomID(completionID: UUID, completion: @escaping (CKRecord?, Error?) -> Void) {
        fetchRecordByCustomID(id: completionID.uuidString, recordType: RecordType.habitCompletion, idFieldKey: RecordKey.HabitCompletion.id, completion: completion)
    }
    
    /// Fetch a mood log record by its custom ID
    /// - Parameters:
    ///   - moodLogID: The UUID of the mood log
    ///   - completion: Completion handler with the found record or error
    func fetchMoodLogRecordByCustomID(moodLogID: UUID, completion: @escaping (CKRecord?, Error?) -> Void) {
        fetchRecordByCustomID(id: moodLogID.uuidString, recordType: RecordType.moodLog, idFieldKey: RecordKey.MoodLog.id, completion: completion)
    }
} 