//
//  LouieApp.swift
//  Louie
//
//  Created by Carson on 3/8/25.
//

import SwiftUI
import CloudKit

@main
struct LouieApp: App {
    // Create a CloudKit Manager environment object
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    // Flags to ensure we only initialize things once
    @State private var hasInitializedCloudKit = false
    @State private var hasCreatedTestData = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitManager)
                .onAppear {
                    // Check iCloud account status and initialize CloudKit
                    if !hasInitializedCloudKit {
                        initializeCloudKit()
                        hasInitializedCloudKit = true
                    }
                }
        }
    }
    
    private func initializeCloudKit() {
        // Check account status
        CKContainer.default().accountStatus { status, error in
            switch status {
            case .available:
                print("[CloudKit] iCloud account available")
                // Force schema initialization to ensure record types exist
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    cloudKitManager.forceSchemaInitialization { success in
                        if success {
                            print("[CloudKit] Schema initialization completed successfully")
                            // After successful initialization, check if we can fetch data
                            self.debugFetchRecords()
                        }
                    }
                }
            case .noAccount:
                print("[CloudKitError] No iCloud account available. Please sign in to use sync features.")
            case .restricted:
                print("[CloudKitError] iCloud account restricted")
            case .couldNotDetermine:
                if let error = error {
                    print("[CloudKitError] Could not determine iCloud account status: \(error.localizedDescription)")
                }
            @unknown default:
                print("[CloudKitError] Unknown iCloud account status")
            }
        }
    }
    
    // Debug method to fetch records after initialization
    private func debugFetchRecords() {
        // Prevent multiple calls
        if hasCreatedTestData {
            print("[CloudKitDebug] Test data already created, skipping.")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("[CloudKitDebug] Attempting to fetch records to verify schema initialization...")
            
            // Use CloudKitManager's debug methods
            self.cloudKitManager.debugDatabaseInfo {
                // After checking database info, try to create a test habit
                // self.createTestHabit() // Comment out automatic test habit creation
                print("[CloudKitDebug] Skipping automatic test habit creation.") // Add log
                self.hasCreatedTestData = true

                // --- TEMPORARY: Count Habit Records --- 
                print("[CloudKitDebug] Counting total Habit records...")
                self.cloudKitManager.countRecords(ofType: RecordType.habit) { result in // Use RecordType constant if accessible, else "Habit"
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let count):
                            print("----------------------------------------------------")
                            print("[CloudKitDebug] TOTAL HABIT RECORDS FOUND: \(count)")
                            print("----------------------------------------------------")
                        case .failure(let error):
                            print("[CloudKitError] FAILED TO COUNT HABIT RECORDS: \(error.localizedDescription)")
                        }
                    }
                }
                // --- END TEMPORARY --- 

            }
        }
    }
    
    // Create a test habit to verify everything works
    private func createTestHabit() {
        let testHabit = Habit(
            id: UUID(),
            title: "Test Habit",
            description: "Created to verify CloudKit integration",
            reminderTime: Date(),
            frequency: .daily,
            customDays: [1, 2, 3, 4, 5],
            emoji: "✅"
        )
        
        print("[CloudKitDebug] Creating test habit to verify CloudKit saving...")
        cloudKitManager.saveHabit(testHabit) { result in
            switch result {
            case .success(let recordID):
                print("[CloudKitDebug] Successfully saved test habit with record ID: \(recordID.recordName)")
                print("[CloudKitDebug] Using habit ID \(testHabit.id) for queries (instead of recordName)")
                
                // Try creating a habit completion for this habit
                let today = Date()
                
                // Use string status for CloudKit instead of enum
                cloudKitManager.saveHabitCompletion(habitID: testHabit.id, date: today, status: "completed") { result in
                    switch result {
                    case .success(let recordID):
                        print("[CloudKitDebug] Successfully saved test habit completion with record ID: \(recordID.recordName)")
                        print("[CloudKitDebug] Using habit ID \(testHabit.id) for queries (instead of recordName)")
                    case .failure(let error):
                        print("[CloudKitDebug] Failed to save test habit completion: \(error.localizedDescription)")
                    }
                }
                
                // Try creating a mood log for this habit
                cloudKitManager.saveMoodLog(habitID: testHabit.id, date: today, mood: "😊", notes: "Test mood log") { result in
                    switch result {
                    case .success(let recordID):
                        print("[CloudKitDebug] Successfully saved test mood log with record ID: \(recordID.recordName)")
                        print("[CloudKitDebug] Using habit ID \(testHabit.id) for queries (instead of recordName)")
                    case .failure(let error):
                        print("[CloudKitDebug] Failed to save test mood log: \(error.localizedDescription)")
                    }
                }
                
            case .failure(let error):
                print("[CloudKitDebug] Failed to save test habit: \(error.localizedDescription)")
            }
        }
    }
}
