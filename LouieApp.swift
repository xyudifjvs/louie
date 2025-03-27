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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitManager)
                .onAppear {
                    // Check iCloud account status and initialize CloudKit
                    initializeCloudKit()
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
                    cloudKitManager.forceSchemaInitialization()
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
}
