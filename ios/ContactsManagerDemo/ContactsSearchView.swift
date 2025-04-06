import Combine
import ContactsManager
import SwiftUI

struct ContactsSearchView: View {
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
      .navigationTitle("Search Contacts")
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
        updateContactsAccessStatus()
      }
      .onContactsManagerEvent(.contactsAccessChanged, identifier: "ContactsSearchView") {
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
