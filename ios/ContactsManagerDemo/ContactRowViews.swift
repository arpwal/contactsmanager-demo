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
            .foregroundColor(.primary)

          Text(recommendation.reason)
            .font(.subheadline)
            .foregroundColor(.gray)
        }

        Spacer()

        // Score indicator (now monochrome)
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
    .sheet(isPresented: $showingDetail) {
      ContactDetailView(contact: recommendation.contact)
    }
  }
} 