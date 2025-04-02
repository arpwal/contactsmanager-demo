import Combine
import ContactsManager
import SwiftUI

struct ContactsSuggestionsView: View {
  @State private var inviteRecommendations: [ContactRecommendation] = []
  @State private var appUsers: [ContactRecommendation] = []
  @State private var isLoadingInvites = false
  @State private var isLoadingAppUsers = false
  @State private var showError = false
  @State private var errorMessage: String?
  @State private var isInitializing = false
  
  // Track if data has been loaded at least once
  @State private var initialLoadCompleted = false
  
  // States for navigation
  @State private var showingAppUsersList = false
  @State private var showingRecommendedList = false
  
  var body: some View {
    NavigationView {
      Group {
        if isInitializing {
          ProgressView("Initializing Service...")
        } else if isLoadingInvites && isLoadingAppUsers && !initialLoadCompleted {
          ProgressView("Loading Suggestions...")
        } else {
          ScrollView {
            VStack(spacing: 20) {
              // App Users Card
              RecommendationCard(
                title: "App Users",
                description: "Contacts also using ContactsManager",
                icon: "person.2.fill",
                isLoading: isLoadingAppUsers,
                isEmpty: appUsers.isEmpty,
                items: appUsers.prefix(3).map { $0.contact.displayName ?? "No Name" },
                action: { showingAppUsersList = true }
              )
              
              // Recommended to Invite Card
              RecommendationCard(
                title: "Recommended to Invite",
                description: "People you might want to invite",
                icon: "envelope.fill",
                isLoading: isLoadingInvites,
                isEmpty: inviteRecommendations.isEmpty,
                items: inviteRecommendations.prefix(3).map { $0.contact.displayName ?? "No Name" },
                action: { showingRecommendedList = true }
              )
            }
            .padding()
          }
          .refreshable {
            // Explicitly set loading states
            await MainActor.run {
              isLoadingInvites = true
              isLoadingAppUsers = true
            }
            // Try to load recommendations
            await loadAllRecommendations()
          }
        }
      }
      .navigationTitle("Suggestions")
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
            isLoadingAppUsers = true
            
            // Load recommendations
            await loadAllRecommendations()
            
            // Mark as completed
            initialLoadCompleted = true
          }
        }
      }
      .sheet(isPresented: $showingAppUsersList) {
        RecommendationListView(
          title: "App Users",
          recommendations: appUsers
        )
      }
      .sheet(isPresented: $showingRecommendedList) {
        RecommendationListView(
          title: "Recommended to Invite",
          recommendations: inviteRecommendations
        )
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
        // Use UserManager to get the user ID
        let userId = UserManager.shared.getUserId() ?? UUID().uuidString
        
        try await ContactsService.shared.initialize(
          withAPIKey: apiKey,
          userId: userId
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
          isLoadingAppUsers = false
        }
        return
      }
    }
    
    // Load each type of recommendation concurrently
    async let invitesTask = loadInviteRecommendations()
    async let appUsersTask = loadAppUsers()
    
    // Wait for all tasks to complete
    await (_, _) = (invitesTask, appUsersTask)
    
    await MainActor.run {
      print("All recommendation loading tasks completed")
    }
  }
  
  private func loadInviteRecommendations() async {
    print("Loading invite recommendations")
    
    // Set loading state on main thread
    await MainActor.run {
      isLoadingInvites = true
    }
    
    do {
      let recommendations = try await ContactsService.shared.getSharedContactsByUsersToInvite(
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
  
  private func loadAppUsers() async {
    print("Loading app users")
    
    // Set loading state on main thread
    await MainActor.run {
      isLoadingAppUsers = true
    }
    
    do {
      let users = try await ContactsService.shared.getContactsUsingApp(
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

// Card view for each recommendation type
struct RecommendationCard: View {
  let title: String
  let description: String
  let icon: String
  let isLoading: Bool
  let isEmpty: Bool
  let items: [String]
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 12) {
        // Header with icon
        HStack {
          Image(systemName: icon)
            .font(.title2)
            .foregroundColor(.blue)
          
          Text(title)
            .font(.headline)
          
          Spacer()
          
          Image(systemName: "chevron.right")
            .foregroundColor(.gray)
        }
        
        Text(description)
          .font(.subheadline)
          .foregroundColor(.gray)
        
        // Content preview
        if isLoading {
          HStack {
            ProgressView()
            Text("Loading...")
              .font(.caption)
              .foregroundColor(.gray)
          }
          .frame(height: 70)
        } else if isEmpty {
          Text("No items available")
            .font(.caption)
            .foregroundColor(.gray)
            .frame(height: 70)
        } else {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
              HStack {
                Image(systemName: "person.circle")
                  .foregroundColor(.gray)
                Text(item)
                  .font(.callout)
              }
            }
            
            if items.count < 3 {
              Spacer()
            }
          }
          .frame(minHeight: 70, alignment: .leading)
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// View for displaying a full list of recommendations
struct RecommendationListView: View {
  let title: String
  let recommendations: [ContactRecommendation]
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      if recommendations.isEmpty {
        ContentUnavailableView(
          "No Recommendations",
          systemImage: "star.slash",
          description: Text("No \(title.lowercased()) available at this time")
        )
        .navigationTitle(title)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        }
      } else {
        List {
          ForEach(recommendations, id: \.contact.id) { recommendation in
            RecommendationRow(recommendation: recommendation)
          }
        }
        .navigationTitle(title)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        }
      }
    }
  }
} 
