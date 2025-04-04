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

  // Grid layout
  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]

  var body: some View {
    NavigationView {
      Group {
        if isInitializing {
          ProgressView("Initializing Service...")
        } else if isLoadingInvites && isLoadingAppUsers && !initialLoadCompleted {
          ProgressView("Loading Suggestions...")
        } else {
          ScrollView {
            VStack(alignment: .leading, spacing: 24) {
              // App Users Grid Section
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Text("App Users")
                    .font(.headline)

                  Spacer()

                  Button("See All") {
                    showingAppUsersList = true
                  }
                  .font(.subheadline)
                  .foregroundColor(.gray)
                }

                if isLoadingAppUsers {
                  HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                  }
                  .frame(height: 120)
                } else if appUsers.isEmpty {
                  Text("No app users found")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                } else {
                  // 3x3 Grid of user profile pictures
                  LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(appUsers.prefix(9), id: \.contact.id) { user in
                      UserProfileCircle(appUser: user)
                        .frame(height: 90)
                    }
                  }
                }
              }

              Divider()
                .padding(.vertical, 8)

              // Recommended to Invite Section
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Text("Recommended to Invite")
                    .font(.headline)

                  Spacer()

                  Button("See All") {
                    showingRecommendedList = true
                  }
                  .font(.subheadline)
                  .foregroundColor(.gray)
                }

                if isLoadingInvites {
                  HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                  }
                  .frame(height: 60)
                } else if inviteRecommendations.isEmpty {
                  Text("No recommendations found")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                } else {
                  // List of recommended users
                  VStack(spacing: 16) {
                    ForEach(inviteRecommendations.prefix(5), id: \.contact.id) { recommendation in
                      ContactRow(contact: recommendation.contact)
                    }
                  }
                }
              }
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

// User Profile Circle view for grid
struct UserProfileCircle: View {
  let appUser: ContactRecommendation
  @State private var showingDetail = false
  @State private var showingActionSheet = false
  @State private var isFollowing = false
  @State private var isLoadingFollowStatus = false
  
  // Social service for follow/unfollow functionality
  private let socialService = SocialService()

  var body: some View {
    VStack {
      ZStack {
        Circle()
          .fill(Color(.systemGray6))

        if appUser.contact.imageDataAvailable,
          let thumbnailData = appUser.contact.thumbnailImageData,
          let uiImage = UIImage(data: thumbnailData)
        {
          Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(Circle())
        } else {
          Image(systemName: "person.fill")
            .font(.system(size: 30))
            .foregroundColor(.gray)
        }
      }
      .onTapGesture {
        showingActionSheet = true
      }

      Text(appUser.contact.displayName ?? "")
        .font(.caption)
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .sheet(isPresented: $showingDetail) {
      ContactDetailView(contact: appUser.contact)
    }
    .confirmationDialog("Contact Options", isPresented: $showingActionSheet, titleVisibility: .visible) {
      Button("Open Contact Card") {
        showingDetail = true
      }
      
      if isLoadingFollowStatus {
        Button("Loading...") {
          // Disabled placeholder button
        }
        .disabled(true)
      } else {
        Button(isFollowing ? "Unfollow" : "Follow") {
          toggleFollowStatus()
        }
      }
      
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(appUser.contact.displayName ?? "Contact")
    }
    .onAppear {
      loadFollowStatus()
    }
  }
  
  // Load current follow status
  private func loadFollowStatus() {
    guard !isLoadingFollowStatus else { return }
    isLoadingFollowStatus = true
    
    Task {
      do {
        // Use the contact's identifier directly
        guard let organizationUserId = appUser.organizationUserId else {
          return
        }
        print("Checking follow status for organization user ID: \(organizationUserId)")
        
        // Check follow status
        let response = try await socialService.isFollowingContact(followedId: organizationUserId)
        
        // Update UI on main thread
        await MainActor.run {
          isFollowing = response.isFollowing
          isLoadingFollowStatus = false
        }
      } catch {
        print("Error checking follow status: \(error.localizedDescription)")
        await MainActor.run {
          isFollowing = false
          isLoadingFollowStatus = false
        }
      }
    }
  }
  
  // Toggle follow status (follow or unfollow)
  private func toggleFollowStatus() {
    Task {
      isLoadingFollowStatus = true
      
      do {
        // Use the contact's identifier directly
        guard let organizationUserId = appUser.organizationUserId else {
          return
        }
        print("Performing follow action with contact ID: \(organizationUserId)")
        
        if isFollowing {
          // Unfollow
          let result = try await socialService.unfollowContact(followedId: organizationUserId)
          await MainActor.run {
            isFollowing = false
          }
        } else {
          // Follow
          let result = try await socialService.followContact(
            followedId: organizationUserId,
            contactId: appUser.contact.identifier
          )
          await MainActor.run {
            isFollowing = true
          }
        }
        
        await MainActor.run {
          isLoadingFollowStatus = false
        }
      } catch {
        print("Error toggling follow status: \(error.localizedDescription)")
        await MainActor.run {
          isLoadingFollowStatus = false
        }
      }
    }
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
