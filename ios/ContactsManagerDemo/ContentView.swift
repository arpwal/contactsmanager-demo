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
  @State private var isRegistered = false

  var body: some View {
    ZStack {
      if isRegistered {
        // Main tab view - only shown when registered
        TabView {
          HomeFeedView()
            .tabItem {
              Label("Home", systemImage: "house.fill")
            }

          FollowsView()
            .tabItem {
              Label("Profile", systemImage: "person.fill")
            }

          ContactsSearchView()
            .tabItem {
              Label("Search", systemImage: "magnifyingglass")
            }

          ContactsSuggestionsView()
            .tabItem {
              Label("Suggestions", systemImage: "star.fill")
            }
        }
        .onAppear {
          // Initialize ContactsService once for the entire app
          if !ContactsService.shared.isInitialized {
            initializeContactsManager()
          }
        }
      } else {
        // Show registration view when not registered
        UserRegistrationView(isRegistered: $isRegistered)
      }
    }
    .onAppear {
      // Check if user is already registered
      isRegistered = UserManager.shared.isRegistered
    }
    .onReceive(NotificationCenter.default.publisher(for: .userRegistrationChanged)) { _ in
      // Re-check registration status when it changes
      isRegistered = UserManager.shared.isRegistered

      // Re-initialize contact manager with new user ID
      if isRegistered && !ContactsService.shared.isInitialized {
        initializeContactsManager()
      }
    }
  }

  private func initializeContactsManager() {
    Task { @MainActor in
      isInitializing = true

      // Create a Task to handle async initialization
      do {
        // Only initialize if not already initialized
        if let userInfo = UserManager.shared.getUserInfo() {
          let apiKey = ConfigurationManager.shared.apiKey
          try await ContactsService.shared.initialize(
            withAPIKey: apiKey,
            userInfo: userInfo
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
