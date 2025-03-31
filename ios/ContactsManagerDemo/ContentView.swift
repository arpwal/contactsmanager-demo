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
      ContactsView()
        .tabItem {
          Label("Contacts", systemImage: "person.crop.circle.fill")
        }

      RecommendationsView()
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

// Original contacts view moved to its own struct
struct ContactsView: View {
  @State private var selectedContacts: [Contact] = []
  @State private var showError = false
  @State private var errorMessage: String?
  @State private var showContactCreation = false
  @State private var showDangerousActionSheet = false
  @State private var contactsAccessStatus: ContactsAccessStatus = .notDetermined
  @State private var isInitializing = false

  // Check if running on simulator
  private var isSimulator: Bool {
    #if targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // Show authorization status if not authorized
        if contactsAccessStatus != .authorized {
          VStack(spacing: 16) {
            Text("Contacts Access Required")
              .font(.headline)

            Button(action: requestContactsAccess) {
              HStack {
                Image(systemName: "lock.open")
                Text("Request Contacts Access")
              }
              .font(.headline)
              .padding()
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .background(Color.green)
              .cornerRadius(10)
            }
            .padding(.horizontal)
          }
          .padding(.vertical, 20)
        }

        // Show selected contacts if any
        if !selectedContacts.isEmpty {
          List(selectedContacts, id: \.id) { contact in
            ContactRow(contact: contact)
          }
        } else {
          ContentUnavailableView(
            "No Contacts Selected",
            systemImage: "person.crop.circle.badge.plus",
            description: Text("Tap the button below to select contacts")
          )
        }

        // Select Contacts Button
        if contactsAccessStatus == .authorized {
          Button(action: showContactPicker) {
            HStack {
              Image(systemName: "person.crop.circle.badge.plus")
              Text("Select Contacts")
            }
            .font(.headline)
            .padding()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
          }
          .padding()
        }
      }
      .navigationTitle("Contacts")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          if contactsAccessStatus == .authorized {
            Button(action: handleCreateContactsTap) {
              Image(systemName: "person.crop.circle.badge.plus.fill")
            }
          }
        }
      }
      .alert("Error", isPresented: $showError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage ?? "An unknown error occurred")
      }
      .sheet(isPresented: $showContactCreation) {
        ContactCreationView()
      }
      .confirmationDialog(
        "Warning",
        isPresented: $showDangerousActionSheet,
        titleVisibility: .visible
      ) {
        Button("Cancel", role: .cancel) {}
        Button("I ❤️ Danger", role: .destructive) {
          showContactCreation = true
        }
      } message: {
        Text(
          "You'll be creating contacts on a real device, so your contact book would be messed up. Are you sure you want to continue?"
        )
      }
      .onAppear {
        initializeContactsManager()
        updateContactsAccessStatus()
      }
      .onContactsManagerEvent(.contactsAccessChanged, identifier: "ContentView") {
        updateContactsAccessStatus()
      }
    }
  }

  private func handleCreateContactsTap() {
    if isSimulator {
      showContactCreation = true
    } else {
      showDangerousActionSheet = true
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
      } catch let error as ContactsServiceError {
        await MainActor.run {
          if case .invalidAPIKey = error {
            errorMessage =
              "Invalid API key. Register for free at ContactsManager.io to get your own API key."
          } else {
            errorMessage = error.localizedDescription
          }
          showError = true
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          showError = true
        }
      }

      isInitializing = false
    }
  }

  private func showContactPicker() {
    Task { @MainActor in
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let rootViewController = windowScene.windows.first?.rootViewController
      else {
        return
      }

      let options = ContactSelectionOptions(
        selectionMode: .multiple,
        fieldType: .any,
        maxSelectionCount: 5
      )

      ContactsManagerUI.getInstance().searchContacts(
        from: rootViewController,
        options: options
      ) { result in
        // Always dispatch UI updates to the main queue
        DispatchQueue.main.async {
          switch result {
          case .success(let contacts):
            self.selectedContacts = contacts
          case .failure(let error):
            self.errorMessage = error.localizedDescription
            self.showError = true
          }
        }
      }
    }
  }

  private func requestContactsAccess() {
    Task {
      let accessGranted = await ContactsService.shared.requestContactsAccess()

      // Always update UI on main thread
      await MainActor.run {
        if accessGranted {
          updateContactsAccessStatus()
        } else {
          errorMessage = "Failed to get contacts access"
          showError = true
        }
      }
    }
  }

  private func updateContactsAccessStatus() {
    let newStatus = ContactsService.shared.contactsAccessStatus
    contactsAccessStatus = newStatus
  }
}

// Recommendations View
struct RecommendationsView: View {
  @State private var inviteRecommendations: [ContactRecommendation] = []
  @State private var nearbyContacts: [ContactRecommendation] = []
  @State private var appUsers: [ContactRecommendation] = []
  @State private var isLoadingInvites = false
  @State private var isLoadingNearby = false
  @State private var isLoadingAppUsers = false
  @State private var showError = false
  @State private var errorMessage: String?
  @State private var isInitializing = false

  // Track if data has been loaded at least once
  @State private var initialLoadCompleted = false

  var body: some View {
    NavigationView {
      Group {
        if isInitializing {
          ProgressView("Initializing Service...")
        } else if isLoadingInvites || isLoadingNearby || isLoadingAppUsers {
          ProgressView("Loading Recommendations...")
        } else if inviteRecommendations.isEmpty && nearbyContacts.isEmpty && appUsers.isEmpty {
          ContentUnavailableView(
            "No Recommendations",
            systemImage: "star.slash",
            description: Text("Pull to refresh to load recommendations")
          )
        } else {
          recommendationsList
        }
      }
      .navigationTitle("Recommendations")
      .refreshable {
        // Explicitly set loading states on the main actor
        await MainActor.run {
          isLoadingInvites = true
          isLoadingNearby = true
          isLoadingAppUsers = true
        }

        // Try to load recommendations
        await loadAllRecommendations()
      }
      .alert("Error", isPresented: $showError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage ?? "An unknown error occurred")
      }
      .onAppear {
        // Only load on first appearance
        if !initialLoadCompleted {
          // Create a task to load recommendations
          Task { @MainActor in
            // Explicitly set loading states
            isLoadingInvites = true
            isLoadingNearby = true
            isLoadingAppUsers = true

            // Load recommendations
            await loadAllRecommendations()

            // Mark as completed
            initialLoadCompleted = true
          }
        }
      }
    }
  }

  private var recommendationsList: some View {
    List {
      if !inviteRecommendations.isEmpty {
        Section("Recommended to Invite") {
          ForEach(inviteRecommendations, id: \.contact.id) { recommendation in
            RecommendationRow(recommendation: recommendation)
          }
        }
      }

      if !nearbyContacts.isEmpty {
        Section("Nearby Contacts") {
          ForEach(nearbyContacts, id: \.contact.id) { recommendation in
            RecommendationRow(recommendation: recommendation)
          }
        }
      }

      if !appUsers.isEmpty {
        Section("App Users") {
          ForEach(appUsers, id: \.contact.id) { recommendation in
            RecommendationRow(recommendation: recommendation)
          }
        }
      }
    }
  }

  private func loadAllRecommendations() async {
    print("Starting to load all recommendations")

    // Ensure proper initialization of ContactsService
    if !ContactsService.shared.isInitialized {
      print("ContactsService not initialized, attempting to initialize...")

      await MainActor.run {
        isInitializing = true
      }

      do {
        let apiKey = ConfigurationManager.shared.apiKey
        try await ContactsService.shared.initialize(
          withAPIKey: apiKey,
          userId: "12345676890"
        )

        await MainActor.run {
          print("ContactsService initialized successfully")
          isInitializing = false
        }
      } catch {
        print("Failed to initialize ContactsService: \(error.localizedDescription)")

        await MainActor.run {
          errorMessage = "Failed to initialize ContactsService: \(error.localizedDescription)"
          showError = true

          // Reset all loading states since we can't proceed
          isInitializing = false
          isLoadingInvites = false
          isLoadingNearby = false
          isLoadingAppUsers = false
        }
        return
      }
    }

    // Using consistent sample IDs for demo - replace with actual IDs in production
    let sampleCanonicalId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
    let sampleOrgId = UUID(uuidString: "F621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

    // Load each type of recommendation concurrently
    async let invitesTask = loadInviteRecommendations(
      canonicalId: sampleCanonicalId, orgId: sampleOrgId)
    async let nearbyTask = loadNearbyContacts()
    async let appUsersTask = loadAppUsers(orgId: sampleOrgId)

    // Wait for all tasks to complete
    await (_, _, _) = (invitesTask, nearbyTask, appUsersTask)

    await MainActor.run {
      print("All recommendation loading tasks completed")
    }
  }

  private func loadInviteRecommendations(canonicalId: UUID, orgId: UUID) async {
    print("Loading invite recommendations")

    // Set loading state on main thread
    await MainActor.run {
      isLoadingInvites = true
    }

    do {
      let recommendations = try await ContactsService.shared.getRecommendedContactsToInvite(
        canonicalContactId: canonicalId,
        organizationId: orgId,
        limit: 30
      )

      await MainActor.run {
        print("Successfully loaded \(recommendations.count) invite recommendations")
        inviteRecommendations = recommendations
        isLoadingInvites = false
      }
    } catch {
      await MainActor.run {
        print("Error loading invite recommendations: \(error.localizedDescription)")
        errorMessage = "Failed to load invite recommendations: \(error.localizedDescription)"
        showError = true
        isLoadingInvites = false
      }
    }
  }

  private func loadNearbyContacts() async {
    print("Loading nearby contacts")

    // Set loading state on main thread
    await MainActor.run {
      isLoadingNearby = true
    }

    do {
      // Sample coordinates for San Francisco - replace with actual location in production
      let contacts = try await ContactsService.shared.getNearbyContacts(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusInKm: 10,
        limit: 30
      )

      await MainActor.run {
        print("Successfully loaded \(contacts.count) nearby contacts")
        nearbyContacts = contacts
        isLoadingNearby = false
      }
    } catch {
      await MainActor.run {
        print("Error loading nearby contacts: \(error.localizedDescription)")
        errorMessage = "Failed to load nearby contacts: \(error.localizedDescription)"
        showError = true
        isLoadingNearby = false
      }
    }
  }

  private func loadAppUsers(orgId: UUID) async {
    print("Loading app users")

    // Set loading state on main thread
    await MainActor.run {
      isLoadingAppUsers = true
    }

    do {
      let users = try await ContactsService.shared.getContactsUsingApp(
        organizationId: orgId,
        limit: 30
      )

      await MainActor.run {
        print("Successfully loaded \(users.count) app users")
        appUsers = users
        isLoadingAppUsers = false
      }
    } catch {
      await MainActor.run {
        print("Error loading app users: \(error.localizedDescription)")
        errorMessage = "Failed to load app users: \(error.localizedDescription)"
        showError = true
        isLoadingAppUsers = false
      }
    }
  }
}

// Contact Row View
struct ContactRow: View {
  let contact: Contact
  @State private var showingDetail = false

  var body: some View {
    Button(action: { showingDetail = true }) {
      HStack(spacing: 16) {
        // Profile Image
        Group {
          if contact.imageDataAvailable,
            let thumbnailData = contact.thumbnailImageData,
            let uiImage = UIImage(data: thumbnailData)
          {
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Image(systemName: "person.circle.fill")
              .resizable()
              .foregroundStyle(.gray.opacity(0.8))
          }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())

        // Contact Info
        VStack(alignment: .leading, spacing: 4) {
          Text(contact.displayName ?? "No Name")
            .font(.headline)

          let info = contact.displayInfo
          Text(info)
            .font(.subheadline)
            .foregroundColor(.gray)
        }

        Spacer()
      }
    }
    .sheet(isPresented: $showingDetail) {
      ContactDetailView(contact: contact)
    }
  }
}

// Recommendation Row View
struct RecommendationRow: View {
  let recommendation: ContactRecommendation
  @State private var showingDetail = false

  var body: some View {
    Button(action: { showingDetail = true }) {
      HStack(spacing: 16) {
        // Profile Image
        Group {
          if recommendation.contact.imageDataAvailable,
            let thumbnailData = recommendation.contact.thumbnailImageData,
            let uiImage = UIImage(data: thumbnailData)
          {
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Image(systemName: "person.circle.fill")
              .resizable()
              .foregroundStyle(.gray.opacity(0.8))
          }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())

        // Contact Info
        VStack(alignment: .leading, spacing: 4) {
          Text(recommendation.contact.displayName ?? "No Name")
            .font(.headline)

          Text(recommendation.reason)
            .font(.subheadline)
            .foregroundColor(.gray)
        }

        Spacer()

        // Score indicator
        ZStack {
          Circle()
            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            .frame(width: 40, height: 40)

          Text(String(format: "%.1f", recommendation.score * 10))
            .font(.system(.caption, design: .rounded))
            .bold()
        }
      }
    }
    .sheet(isPresented: $showingDetail) {
      ContactDetailView(contact: recommendation.contact)
    }
  }
}

#Preview {
  ContentView()
}
