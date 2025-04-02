//
//  HomeFeedView.swift
//  ContactsManagerDemo
//
//  Created by Arpit Agarwal on 4/2/25.
//

import ContactsManager
import SwiftUI

// Home Feed View displaying events
struct HomeFeedView: View {
  @State private var events: [SocialEvent] = []
  @State private var isLoading = false
  @State private var error: Error?
  @State private var feedMode: FeedMode = .following

  enum FeedMode: String, CaseIterable, Identifiable {
    case following = "Following"
    case forYou = "For You"

    var id: String { self.rawValue }
  }

  var body: some View {
    NavigationView {
      VStack {
        if isLoading {
          ProgressView()
            .padding()
        } else if let error = error {
          VStack {
            Text("Error loading events")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.subheadline)
              .foregroundColor(.secondary)
            Button("Try Again") {
              Task {
                await loadEvents()
              }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
          }
          .padding()
        } else if events.isEmpty {
          VStack {
            Text(
              feedMode == .following ? "No events from your followers yet" : "No events available"
            )
            .font(.headline)
            Text("Events will appear here when available")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding()
        } else {
          List {
            ForEach(events) { event in
              EventRow(event: event)
            }
          }
          .listStyle(PlainListStyle())
          .refreshable {
            await loadEvents()
          }
        }
      }
      .navigationTitle("Events")
      .toolbar {
        ToolbarItem(placement: .principal) {
          Picker("Feed Type", selection: $feedMode) {
            ForEach(FeedMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(SegmentedPickerStyle())
          .frame(width: 220)
          .onChange(of: feedMode) { _ in
            Task {
              await loadEvents()
            }
          }
        }
      }
      .onAppear {
        Task {
          await loadEvents()
        }
      }
    }
  }

  private func loadEvents() async {
    guard !isLoading else { return }

    isLoading = true
    error = nil

    do {
      let service = SocialService()
      let result: PaginatedEventList

      if feedMode == .following {
        result = try await service.getFeed()
        print("Got \(result.items.count) events for Following feed")
      } else {
        result = try await service.getForYouFeed()
        print("Got \(result.items.count) events for For You feed")
      }

      await MainActor.run {
        self.events = result.items
        self.isLoading = false
      }
    } catch let fetchError {
      print("Error loading events: \(fetchError)")
      await MainActor.run {
        self.error = fetchError
        self.isLoading = false
      }
    }
  }
}

// Row for displaying an event
struct EventRow: View {
  let event: SocialEvent

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(event.title)
          .font(.headline)
        Spacer()
        Text(event.eventType)
          .font(.subheadline)
          .padding(4)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.blue.opacity(0.2))
          )
      }

      if let description = event.description, !description.isEmpty {
        Text(description)
          .font(.body)
          .lineLimit(3)
      }

      if let location = event.location, !location.isEmpty {
        HStack {
          Image(systemName: "location.fill")
            .foregroundColor(.secondary)
          Text(location)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }

      if let startTime = event.startTime {
        HStack {
          Image(systemName: "calendar")
            .foregroundColor(.secondary)
          Text(formatDate(startTime))
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(.vertical, 8)
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

#Preview {
  HomeFeedView()
}
