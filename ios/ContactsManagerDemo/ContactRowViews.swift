import ContactsManager
import SwiftUI

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
            let uiImage = UIImage(data: thumbnailData) {
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
            .foregroundColor(.primary)

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
  @State private var isFollowing = false
  @State private var isLoadingFollowStatus = false
  @State private var isPerformingFollowAction = false

  // Social service for follow/unfollow functionality
  private let socialService = SocialService()

  var body: some View {
    Button(action: { showingDetail = true }) {
      HStack(spacing: 16) {
        // Profile Image
        Group {
          if recommendation.contact.imageDataAvailable,
            let thumbnailData = recommendation.contact.thumbnailImageData,
            let uiImage = UIImage(data: thumbnailData) {
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
            .foregroundColor(.primary)

          Text(recommendation.reason)
            .font(.subheadline)
            .foregroundColor(.gray)
        }

        Spacer()

        // Different UI elements based on recommendation type
        if recommendation.type == .appUsers {
          // Follow/Unfollow button for app users
          if isLoadingFollowStatus || isPerformingFollowAction {
            ProgressView()
              .frame(width: 30, height: 30)
          } else {
            Button(action: {
              handleFollowAction()
            }) {
              Text(isFollowing ? "Unfollow" : "Follow")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isFollowing ? Color.gray.opacity(0.2) : Color.blue)
                .foregroundColor(isFollowing ? .primary : .white)
                .clipShape(Capsule())
            }
            .buttonStyle(BorderlessButtonStyle()) // Prevent the outer button from capturing this tap
          }
        } else {
          // Score indicator (for invite recommendations)
          Text(String(format: "%.1f", recommendation.score * 10))
            .font(.caption2)
            .foregroundColor(.gray)
            .padding(8)
            .background(
              Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .background(Circle().fill(Color(.systemGray6)))
            )
            .frame(width: 36)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .sheet(isPresented: $showingDetail) {
      ContactDetailView(contact: recommendation.contact)
    }
    .onAppear {
      if recommendation.type == .appUsers {
        loadFollowStatus()
      }
    }
  }

  // Load current follow status
  private func loadFollowStatus() {
    guard !isLoadingFollowStatus else { return }
    isLoadingFollowStatus = true

    Task {
      do {
        // Use the contact's identifier directly
        guard let organizationUserId = recommendation.organizationUserId else {
          print("No organization user ID found for contact ID: \(recommendation.contact.identifier)")
          return
        }
        print("Checking follow status for contact ID: \(organizationUserId)")

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

  // Handle follow/unfollow action
  private func handleFollowAction() {
    guard !isPerformingFollowAction else { return }
    isPerformingFollowAction = true

    Task {
      do {
        // Use the contact's identifier directly
        guard let organizationUserId = recommendation.organizationUserId else {
          print("No organization user ID found for contact ID: \(recommendation.contact.identifier)")
          return
        }
        print("Performing follow action with contact ID: \(organizationUserId)")

        // Execute follow or unfollow
        if isFollowing {
          let result = try await socialService.unfollowContact(followedId: organizationUserId)
          await MainActor.run {
            isFollowing = false
          }
        } else {
          let result = try await socialService.followContact(
            followedId: organizationUserId,
            contactId: recommendation.contact.identifier
          )
          await MainActor.run {
            isFollowing = true
          }
        }

        await MainActor.run {
          isPerformingFollowAction = false
        }
      } catch {
        print("Error performing follow action: \(error.localizedDescription)")
        await MainActor.run {
          isPerformingFollowAction = false
        }
      }
    }
  }
}
