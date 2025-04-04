import SwiftUI
import ContactsManager

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