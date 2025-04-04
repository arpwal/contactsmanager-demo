//
//  FollowsView.swift
//  ContactsManagerDemo
//
//  Created by Arpit Agarwal on 4/2/25.
//

import SwiftUI
import ContactsManager

// View for displaying followers and following
struct FollowsView: View {
  @State private var selectedTab: Int = 0
  @State private var followers: [FollowRelationship] = []
  @State private var following: [FollowRelationship] = []
  @State private var events: [SocialEvent] = []
  @State private var isLoadingFollowers = false
  @State private var isLoadingFollowing = false
  @State private var isLoadingEvents = false
  @State private var error: Error?
  
  // User profile data
  @State private var userName: String = ""
  @State private var userContact: String = ""
  @State private var userId: String = ""
  
  // Event creation states
  @State private var showCreateEventSheet = false
  @State private var isPostingEvent = false
  
  // For scroll coordination
  @State private var scrollOffset: CGFloat = 0
  
  var body: some View {
    NavigationView {
      ZStack {
        // Main ScrollView for the entire content
        ScrollView {
          VStack(spacing: 0) {
            // User Profile Section
            VStack(spacing: 16) {
              // Avatar
              ZStack {
                Circle()
                  .fill(Color(.systemGray6))
                  .frame(width: 100, height: 100)
                
                Image(systemName: "person.circle.fill")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 80, height: 80)
                  .foregroundColor(.gray)
              }
              .padding(.top, 20)
              
              // User Information
              VStack(spacing: 8) {
                Text(userName.isEmpty ? "User Profile" : userName)
                  .font(.title2)
                  .fontWeight(.bold)
                
                if !userContact.isEmpty {
                  Text(userContact)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Text("ID: \(userId)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              .padding(.horizontal)
              
              // Tab Selector
              Picker("", selection: $selectedTab) {
                Text("Events").tag(0)
                Text("Followers").tag(1)
                Text("Following").tag(2)
              }
              .pickerStyle(SegmentedPickerStyle())
              .frame(width: 280)
              .padding(.vertical, 16)
            }
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
            
            // Content for selected tab
            VStack {
              if selectedTab == 0 {
                eventsContent
              } else if selectedTab == 1 {
                followersContent
              } else {
                followingContent
              }
            }
            .padding(.top, 8)
          }
        }
        .refreshable {
          if selectedTab == 0 {
            await loadEvents()
          } else if selectedTab == 1 {
            await loadFollowers()
          } else {
            await loadFollowing()
          }
        }
        
        // Floating action button for creating events (only visible in Events tab)
        if selectedTab == 0 {
          VStack {
            Spacer()
            HStack {
              Spacer()
              Button(action: {
                showCreateEventSheet = true
              }) {
                Image(systemName: "plus")
                  .font(.title)
                  .foregroundColor(.white)
                  .frame(width: 55, height: 55)
                  .background(Color.blue)
                  .clipShape(Circle())
                  .shadow(radius: 4)
              }
              .padding(.trailing, 20)
              .padding(.bottom, 20)
            }
          }
        }
      }
      .navigationTitle("Social")
      .onChange(of: selectedTab) { _ in
        if selectedTab == 0 && events.isEmpty {
          Task { await loadEvents() }
        } else if selectedTab == 1 && followers.isEmpty {
          Task { await loadFollowers() }
        } else if selectedTab == 2 && following.isEmpty {
          Task { await loadFollowing() }
        }
      }
      .onAppear {
        // Load user profile data
        loadUserProfile()
        // Load events first since it's the default tab
        Task { await loadEvents() }
      }
      .sheet(isPresented: $showCreateEventSheet) {
        CreateEventSheet(isPresented: $showCreateEventSheet, isPosting: $isPostingEvent) { eventText in
          Task {
            await createEvent(text: eventText)
          }
        }
      }
    }
  }
  
  // Events content
  private var eventsContent: some View {
    Group {
      if isLoadingEvents {
        ProgressView()
          .padding()
          .frame(minHeight: 300)
      } else if let error = error, selectedTab == 0 {
        VStack {
          Text("Error loading events")
            .font(.headline)
          Text(error.localizedDescription)
            .font(.subheadline)
            .foregroundColor(.secondary)
          Button("Try Again") {
            Task { await loadEvents() }
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
        .padding()
        .frame(minHeight: 300)
      } else if events.isEmpty {
        VStack {
          Text("No events yet")
            .font(.headline)
          Text("Your created events will appear here")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(minHeight: 300)
      } else {
        LazyVStack(spacing: 16) {
          ForEach(events) { event in
            EventRow(event: event)
              .padding(.horizontal)
          }
        }
        .padding(.vertical)
      }
    }
  }
  
  // Followers content
  private var followersContent: some View {
    Group {
      if isLoadingFollowers {
        ProgressView()
          .padding()
          .frame(minHeight: 300)
      } else if let error = error, selectedTab == 1 {
        VStack {
          Text("Error loading followers")
            .font(.headline)
          Text(error.localizedDescription)
            .font(.subheadline)
            .foregroundColor(.secondary)
          Button("Try Again") {
            Task { await loadFollowers() }
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
        .padding()
        .frame(minHeight: 300)
      } else if followers.isEmpty {
        VStack {
          Text("No followers yet")
            .font(.headline)
          Text("Your followers will appear here")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(minHeight: 300)
      } else {
        LazyVStack(spacing: 8) {
          ForEach(followers) { relationship in
            if let follower = relationship.follower {
              FollowContactRow(contact: follower)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
            }
          }
        }
        .padding(.vertical)
      }
    }
  }
  
  // Following content
  private var followingContent: some View {
    Group {
      if isLoadingFollowing {
        ProgressView()
          .padding()
          .frame(minHeight: 300)
      } else if let error = error, selectedTab == 2 {
        VStack {
          Text("Error loading following")
            .font(.headline)
          Text(error.localizedDescription)
            .font(.subheadline)
            .foregroundColor(.secondary)
          Button("Try Again") {
            Task { await loadFollowing() }
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
        .padding()
        .frame(minHeight: 300)
      } else if following.isEmpty {
        VStack {
          Text("Not following anyone yet")
            .font(.headline)
          Text("Contacts you follow will appear here")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(minHeight: 300)
      } else {
        LazyVStack(spacing: 8) {
          ForEach(following) { relationship in
            if let followed = relationship.followed {
              FollowContactRow(contact: followed)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
            }
          }
        }
        .padding(.vertical)
      }
    }
  }
  
  // Load user profile data from UserManager
  private func loadUserProfile() {
    // Get user data from UserManager
    if let contactValue = UserManager.shared.getUserContact() {
      userContact = contactValue
      
      // Determine if it's an email or phone number
      let type = UserManager.shared.getUserType()
      userName = type == .email ? "Email User" : "Phone User"
    }
    
    // Get the user ID
    if let id = UserManager.shared.getUserId() {
      userId = id
    } else {
      userId = "Unknown ID"
    }
  }
  
  // Load events created by the current user
  private func loadEvents() async {
    guard !isLoadingEvents else { return }
    
    isLoadingEvents = true
    error = nil
    
    do {
      let service = SocialService()
      let result = try await service.getContactEvents()
      
      await MainActor.run {
        self.events = result.items
        self.isLoadingEvents = false
      }
    } catch let fetchError {
      await MainActor.run {
        self.error = fetchError
        self.isLoadingEvents = false
      }
    }
  }
  
  private func loadFollowers() async {
    guard !isLoadingFollowers else { return }
    
    isLoadingFollowers = true
    error = nil
    
    do {
      let service = SocialService()
      let result = try await service.getFollowers()
      
      await MainActor.run {
        self.followers = result.items
        self.isLoadingFollowers = false
      }
    } catch let fetchError {
      await MainActor.run {
        self.error = fetchError
        self.isLoadingFollowers = false
      }
    }
  }
  
  private func loadFollowing() async {
    guard !isLoadingFollowing else { return }
    
    isLoadingFollowing = true
    error = nil
    
    do {
      let service = SocialService()
      let result = try await service.getFollowing()
      
      await MainActor.run {
        self.following = result.items
        self.isLoadingFollowing = false
      }
    } catch let fetchError {
      await MainActor.run {
        self.error = fetchError
        self.isLoadingFollowing = false
      }
    }
  }
  
  // Create a new event
  private func createEvent(text: String) async {
    guard !text.isEmpty else { return }
    
    isPostingEvent = true
    
    do {
      let service = SocialService()
      
      // Create a simple post request with just the fields we need
      let postRequest = CreateEventRequest(
        eventType: "post",
        title: text,
        description: "",
        isPublic: true
      )
      
      // Use the service to create the event
      let result = try await service.createEvent(eventData: postRequest)
      
      await MainActor.run {
        isPostingEvent = false
        error = nil
        showCreateEventSheet = false
      }
      
      // After successful creation, refresh the events
      await loadEvents()
      
    } catch let createError {
      print("Error creating event: \(createError)")
      
      await MainActor.run {
        // Get a user-friendly error message
        if let apiError = createError as? APIError {
          switch apiError {
          case .serverError(_, let message):
            self.error = NSError(
              domain: "EventCreationError",
              code: 422,
              userInfo: [NSLocalizedDescriptionKey: "Could not create post: \(message)"]
            )
          default:
            self.error = apiError
          }
        } else {
          self.error = createError
        }
        
        isPostingEvent = false
      }
    }
  }
}

// Row for displaying an event like a Twitter post
struct EventRow: View {
  let event: SocialEvent
  
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header with event type and visibility
      HStack {
        Text(event.eventType.capitalized)
          .font(.headline)
          .foregroundColor(.primary)
        
        Spacer()
        
        HStack(spacing: 4) {
          Image(systemName: event.isPublic ? "globe" : "lock")
            .font(.footnote)
          Text(event.isPublic ? "Public" : "Private")
            .font(.footnote)
        }
        .foregroundColor(.secondary)
      }
      
      // Event title
      Text(event.title)
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
      
      // Event description if available
      if let description = event.description, !description.isEmpty {
        Text(description)
          .font(.body)
          .foregroundColor(.primary)
          .fixedSize(horizontal: false, vertical: true)
      }
      
      // Event details
      VStack(alignment: .leading, spacing: 6) {
        // Location if available
        if let location = event.location, !location.isEmpty {
          HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
              .foregroundColor(.red)
            Text(location)
              .font(.subheadline)
          }
        }
        
        // Date and time if available
        if let startTime = event.startTime {
          HStack(spacing: 6) {
            Image(systemName: "calendar")
              .foregroundColor(.blue)
            Text(dateFormatter.string(from: startTime))
              .font(.subheadline)
            
            if let endTime = event.endTime {
              Text("to")
                .font(.subheadline)
                .foregroundColor(.secondary)
              Text(dateFormatter.string(from: endTime))
                .font(.subheadline)
            }
          }
        }
      }
      
      // Footer with metadata
      HStack {
        Text("Created: \(dateFormatter.string(from: event.createdAt))")
          .font(.caption)
          .foregroundColor(.secondary)
        
        Spacer()
        
        // Add interaction buttons later
        Button(action: {
          // Share action
        }) {
          Image(systemName: "square.and.arrow.up")
        }
        .buttonStyle(.borderless)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(10)
    .shadow(color: Color(.systemGray5), radius: 3, x: 0, y: 1)
  }
}

// Row for displaying a follower/following contact
struct FollowContactRow: View {
  let contact: CanonicalContact
  
  var body: some View {
    HStack(spacing: 12) {
      if let avatarUrl = contact.avatarUrl, !avatarUrl.isEmpty {
        AsyncImage(url: URL(string: avatarUrl)) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray)
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
      } else {
        Image(systemName: "person.circle.fill")
          .resizable()
          .frame(width: 40, height: 40)
          .foregroundColor(.gray)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text(contact.fullName ?? "Unknown Contact")
          .font(.headline)
        
        if let email = contact.email, !email.isEmpty {
          Text(email)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
      
      Spacer()
    }
  }
}

#Preview {
  FollowsView()
} 
