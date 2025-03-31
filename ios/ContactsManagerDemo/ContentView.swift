//
//  ContentView.swift
//  ContactsManagerDemo
//
//  Created by Arpit Agarwal on 3/5/25.
//

import Combine
import ContactsManager
import SwiftUI

// Main tab view
struct ContentView: View {
  @State private var isInitializing = false

  var body: some View {
    TabView {
      ContactsSearchView()
        .tabItem {
          Label("Contacts", systemImage: "person.crop.circle.fill")
        }

      ContactsRecommendationsView()
        .tabItem {
          Label("Recommendations", systemImage: "star.fill")
        }
    }
    .onAppear {
      // Initialize ContactsService once for the entire app
      if !ContactsService.shared.isInitialized {
        initializeContactsManager()
      }
    }
  }

  private func initializeContactsManager() {
    Task { @MainActor in
      isInitializing = true

      do {
        // Only initialize if not already initialized
        if !ContactsService.shared.isInitialized {
          let apiKey = ConfigurationManager.shared.apiKey
          try await ContactsService.shared.initialize(
            withAPIKey: apiKey,
            userId: "12345676890"
          )
        }
        print("ContactsService initialized successfully in ContentView")
      } catch {
        print("Error initializing ContactsService in ContentView: \(error.localizedDescription)")
      }

      isInitializing = false
    }
  }
}

#Preview {
  ContentView()
}
