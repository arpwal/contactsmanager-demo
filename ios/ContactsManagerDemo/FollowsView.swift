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
  @State private var isLoadingFollowers = false
  @State private var isLoadingFollowing = false
  @State private var error: Error?
  
  var body: some View {
    NavigationView {
      VStack {
        TabView(selection: $selectedTab) {
          // Followers Tab
          followersTabContent
            .tag(0)
          
          // Following Tab
          followingTabContent
            .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      }
      .navigationTitle("Social")
      .toolbar {
        ToolbarItem(placement: .principal) {
          Picker("", selection: $selectedTab) {
            Text("Followers").tag(0)
            Text("Following").tag(1)
          }
          .pickerStyle(SegmentedPickerStyle())
          .frame(width: 220)
        }
      }
      .onChange(of: selectedTab) { _ in
        if selectedTab == 0 && followers.isEmpty {
          Task { await loadFollowers() }
        } else if selectedTab == 1 && following.isEmpty {
          Task { await loadFollowing() }
        }
      }
      .onAppear {
        Task { await loadFollowers() }
      }
    }
  }
  
  // Followers tab content
  private var followersTabContent: some View {
    Group {
      if isLoadingFollowers {
        ProgressView()
          .padding()
      } else if let error = error, selectedTab == 0 {
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
      } else if followers.isEmpty {
        VStack {
          Text("No followers yet")
            .font(.headline)
          Text("Your followers will appear here")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
      } else {
        List {
          ForEach(followers) { relationship in
            if let follower = relationship.follower {
              FollowContactRow(contact: follower)
            }
          }
        }
        .listStyle(PlainListStyle())
        .refreshable {
          await loadFollowers()
        }
      }
    }
  }
  
  // Following tab content
  private var followingTabContent: some View {
    Group {
      if isLoadingFollowing {
        ProgressView()
          .padding()
      } else if let error = error, selectedTab == 1 {
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
      } else if following.isEmpty {
        VStack {
          Text("Not following anyone yet")
            .font(.headline)
          Text("Contacts you follow will appear here")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
      } else {
        List {
          ForEach(following) { relationship in
            if let followed = relationship.followed {
              FollowContactRow(contact: followed)
            }
          }
        }
        .listStyle(PlainListStyle())
        .refreshable {
          await loadFollowing()
        }
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
    .padding(.vertical, 4)
  }
}

#Preview {
  FollowsView()
} 