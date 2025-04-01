//
//  ContactsManagerDemoApp.swift
//  ContactsManagerDemo
//
//  Created by Arpit Agarwal on 3/5/25.
//

import SwiftUI
import ContactsManager

@main
struct ContactsManagerDemoApp: App {
    // Initialize app
    init() {
        // OPTIONAL: Enable background sync only if your app needs it
        // Uncomment the line below to enable background contact synchronization
         ContactsService.shared.enableBackgroundSync()
        // Note: The app works perfectly without background sync enabled!
        
        // Force load UserManager
        _ = UserManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
