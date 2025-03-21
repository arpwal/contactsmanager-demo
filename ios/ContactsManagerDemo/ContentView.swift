//
//  ContentView.swift
//  ContactsManagerDemo
//
//  Created by Arpit Agarwal on 3/5/25.
//

import Contacts
import ContactsManager
import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedContacts: [Contact] = []
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showContactCreation = false
    @State private var showDangerousActionSheet = false
    @State private var contactsAccessStatus: ContactsAccessStatus = .notDetermined
    
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
            .navigationTitle("Rolodex")
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
                Text("You'll be creating contacts on a real device, so your contact book would be messed up. Are you sure you want to continue?")
            }
            .onAppear {
                initializeContactsManager()
                updateContactsAccessStatus()
            }
            .onContactsManagerEvent(.contactsAccessChanged, identifier: "ContentView") {
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
    
    private func initializeContactsManager() {
        Task {
            do {
                // Get API key from configuration or use fallback
                // You can replace this with your actual API key if xcconfig isn't working
                let apiKey = ConfigurationManager.shared.apiKey
                
                try await ContactsService.shared.initialize(
                    withAPIKey: apiKey,
                    userId: "12345676890"
                )
            } catch let error as ContactsServiceError {
                await MainActor.run {
                    // Enhanced error message for invalid API key
                    if case .invalidAPIKey = error {
                        errorMessage = "Invalid API key. Register for free at ContactsManager.io to get your own API key."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    showError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func showContactPicker() {
        // Configure selection options
        let options = ContactSelectionOptions(
            selectionMode: .multiple,
            fieldType: .any,
            maxSelectionCount: 5
        )
        
        // Get the current window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // Present the contact picker
        ContactsManagerUI.getInstance().searchContacts(
            from: rootViewController,
            options: options
        ) { result in
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
    
    private func requestContactsAccess() {
        Task {
            if await ContactsService.shared.requestContactsAccess() {
                await MainActor.run {
                    updateContactsAccessStatus()
                }
            } else {
                await MainActor.run {
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

// Keep just the ContactRow view for displaying selected contacts
private struct ContactRow: View {
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
                    
                    if let firstPhone = contact.phoneNumbers.first?.value {
                        Text(firstPhone)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingDetail) {
            ContactDetailView(contact: contact)
        }
    }
}

#Preview {
    ContentView()
}


