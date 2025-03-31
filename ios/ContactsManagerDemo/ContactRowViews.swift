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