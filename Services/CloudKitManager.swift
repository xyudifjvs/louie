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
    
    // MARK: - Initialization
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        
        // Check iCloud account status
        checkAccountStatus()
    }
    
    // Check iCloud account status
    private func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.iCloudAccountStatus = status
                
                if let error = error {
                    print("CloudKit account status error: \(error.localizedDescription)")
                }
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
        
        privateDB.save(record) { record, error in
            if let error = error {
                print("Error saving habit to CloudKit: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                let error = NSError(domain: "CloudKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown error saving habit"])
                completion(.failure(error))
                return
            }
            
            print("Successfully saved habit to CloudKit with ID: \(record.recordID)")
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
            
            if let error = error {
                print("Error fetching habits from CloudKit: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let habits = records.compactMap { CKHabit.from(record: $0) }
            print("Successfully fetched \(habits.count) habits from CloudKit")
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
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error finding habit to delete: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first else {
                let error = NSError(domain: "CloudKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Habit not found for deletion"])
                completion(.failure(error))
                return
            }
            
            // Now delete the record
            self.privateDB.delete(withRecordID: record.recordID) { _, error in
                if let error = error {
                    print("Error deleting habit from CloudKit: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("Successfully deleted habit from CloudKit")
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
        
        privateDB.perform(completionQuery, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error finding completions to delete: \(error.localizedDescription)")
                return
            }
            
            guard let records = records, !records.isEmpty else {
                return
            }
            
            // Delete each completion record
            for record in records {
                self.privateDB.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("Error deleting completion: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Delete mood logs
        let moodPredicate = NSPredicate(format: "%K == %@", RecordKey.MoodLog.habitID, habitID.uuidString)
        let moodQuery = CKQuery(recordType: RecordType.moodLog, predicate: moodPredicate)
        
        privateDB.perform(moodQuery, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error finding mood logs to delete: \(error.localizedDescription)")
                return
            }
            
            guard let records = records, !records.isEmpty else {
                return
            }
            
            // Delete each mood log record
            for record in records {
                self.privateDB.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("Error deleting mood log: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Habit Completion Methods
    
    /// Save a habit completion to CloudKit
    /// - Parameters:
    ///   - habitID: The ID of the habit
    ///   - date: The date of completion
    ///   - status: The completion status
    ///   - completion: Completion handler with result
    func saveHabitCompletion(habitID: UUID, date: Date, status: CompletionStatus, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        // Check if there's an existing completion record for this habit and date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let predicate = NSPredicate(format: "%K == %@ AND %K == %@", 
                                  RecordKey.HabitCompletion.habitID, habitID.uuidString,
                                  RecordKey.HabitCompletion.date, startOfDay as NSDate)
        let query = CKQuery(recordType: RecordType.habitCompletion, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking for existing habit completion: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // If we found an existing record, update it
            if let existingRecord = records?.first {
                existingRecord[RecordKey.HabitCompletion.status] = status.stringValue
                
                self.privateDB.save(existingRecord) { record, error in
                    if let error = error {
                        print("Error updating habit completion: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let record = record else {
                        let error = NSError(domain: "CloudKitManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown error updating habit completion"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("Successfully updated habit completion")
                    completion(.success(record.recordID))
                }
            } else {
                // Create a new record
                let ckCompletion = CKHabitCompletion.from(habitID: habitID, date: startOfDay, status: status)
                let record = ckCompletion.toCKRecord()
                
                self.privateDB.save(record) { record, error in
                    if let error = error {
                        print("Error saving habit completion: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let record = record else {
                        let error = NSError(domain: "CloudKitManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown error saving habit completion"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("Successfully saved habit completion")
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
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.HabitCompletion.date, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error fetching habit completions: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let completions = records.compactMap { CKHabitCompletion.from(record: $0) }
            print("Successfully fetched \(completions.count) habit completions")
            completion(.success(completions))
        }
    }
    
    /// Fetch all habit completions for the user
    /// - Parameter completion: Completion handler with result
    func fetchAllHabitCompletions(completion: @escaping (Result<[CKHabitCompletion], Error>) -> Void) {
        let query = CKQuery(recordType: RecordType.habitCompletion, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.HabitCompletion.date, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error fetching all habit completions: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let completions = records.compactMap { CKHabitCompletion.from(record: $0) }
            print("Successfully fetched \(completions.count) total habit completions")
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
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error finding habit completion to delete: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first else {
                let error = NSError(domain: "CloudKitManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Habit completion not found for deletion"])
                completion(.failure(error))
                return
            }
            
            self.privateDB.delete(withRecordID: record.recordID) { _, error in
                if let error = error {
                    print("Error deleting habit completion: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("Successfully deleted habit completion")
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
            
            if let error = error {
                print("Error checking for existing mood log: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // If we found an existing record, update it
            if let existingRecord = records?.first {
                existingRecord[RecordKey.MoodLog.mood] = mood
                existingRecord[RecordKey.MoodLog.notes] = notes
                
                self.privateDB.save(existingRecord) { record, error in
                    if let error = error {
                        print("Error updating mood log: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let record = record else {
                        let error = NSError(domain: "CloudKitManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "Unknown error updating mood log"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("Successfully updated mood log")
                    completion(.success(record.recordID))
                }
            } else {
                // Create a new record
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
                    if let error = error {
                        print("Error saving mood log: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let record = record else {
                        let error = NSError(domain: "CloudKitManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Unknown error saving mood log"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("Successfully saved mood log")
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
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error fetching mood logs: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let moodLogs = records.compactMap { CKMoodLog.from(record: $0) }
            print("Successfully fetched \(moodLogs.count) mood logs")
            completion(.success(moodLogs))
        }
    }
    
    /// Fetch all mood logs for the user
    /// - Parameter completion: Completion handler with result
    func fetchAllMoodLogs(completion: @escaping (Result<[CKMoodLog], Error>) -> Void) {
        let query = CKQuery(recordType: RecordType.moodLog, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.MoodLog.date, ascending: false)]
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error fetching all mood logs: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let moodLogs = records.compactMap { CKMoodLog.from(record: $0) }
            print("Successfully fetched \(moodLogs.count) total mood logs")
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
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error finding mood log to delete: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first else {
                let error = NSError(domain: "CloudKitManager", code: 8, userInfo: [NSLocalizedDescriptionKey: "Mood log not found for deletion"])
                completion(.failure(error))
                return
            }
            
            self.privateDB.delete(withRecordID: record.recordID) { _, error in
                if let error = error {
                    print("Error deleting mood log: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("Successfully deleted mood log")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - CloudKit Schema Migration
    
    /// Create CloudKit schema programmatically
    /// Call this method once to set up the CloudKit schema
    func createCloudKitSchema(completion: @escaping (Bool) -> Void) {
        // This is typically handled by CloudKit Dashboard, but we can ensure records are properly defined
        let operations = [createHabitSchema(), createHabitCompletionSchema(), createMoodLogSchema()].compactMap { $0 }
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperations(operations, waitUntilFinished: true)
        
        print("CloudKit schema migration completed")
        completion(true)
    }
    
    private func createHabitSchema() -> CKOperation? {
        let recordZone = CKRecordZone(zoneName: "HabitZone")
        let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: nil)
        createZoneOperation.modifyRecordZonesCompletionBlock = { _, _, error in
            if let error = error {
                print("Error creating habit zone: \(error.localizedDescription)")
                return
            }
            print("Successfully created habit zone")
        }
        return createZoneOperation
    }
    
    private func createHabitCompletionSchema() -> CKOperation? {
        return nil // Schema definition typically happens through CloudKit Dashboard or API
    }
    
    private func createMoodLogSchema() -> CKOperation? {
        return nil // Schema definition typically happens through CloudKit Dashboard or API
    }
    
    // MARK: - Error Handling
    
    /// Handle CloudKit errors in a standardized way
    /// - Parameter error: The CloudKit error to handle
    /// - Returns: A user-friendly error message or nil if the error was handled
    func handleCloudKitError(_ error: Error) -> String? {
        let ckError = error as NSError
        
        switch ckError.code {
        case CKError.networkFailure.rawValue:
            return "Network connection is unavailable. Please check your connection and try again."
        case CKError.notAuthenticated.rawValue:
            return "Please sign in to iCloud to use CloudKit features."
        case CKError.quotaExceeded.rawValue:
            return "Your iCloud storage quota has been exceeded."
        case CKError.serverResponseLost.rawValue, CKError.serviceUnavailable.rawValue:
            return "CloudKit service is currently unavailable. Please try again later."
        case CKError.incompatibleVersion.rawValue:
            return "Please update your app to use this feature."
        default:
            print("Unhandled CloudKit error: \(error.localizedDescription)")
            return "An unexpected error occurred. Please try again."
        }
    }
} 