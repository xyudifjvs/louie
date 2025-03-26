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
                    // Check iCloud account status
                    checkAccountStatus()
                }
        }
    }
    
    private func checkAccountStatus() {
        CKContainer.default().accountStatus { status, error in
            switch status {
            case .available:
                print("iCloud account available")
            case .noAccount:
                print("No iCloud account available. Please sign in to use sync features.")
            case .restricted:
                print("iCloud account restricted")
            case .couldNotDetermine:
                if let error = error {
                    print("Could not determine iCloud account status: \(error.localizedDescription)")
                }
            @unknown default:
                print("Unknown iCloud account status")
            }
        }
    }
}
