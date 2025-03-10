import SwiftUI
import Contacts

struct ContactCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCount = 10
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    private let contactCounts = [10, 100, 500, 1000]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select number of contacts to create")
                    .font(.headline)
                    .padding(.top)
                
                Picker("Contact Count", selection: $selectedCount) {
                    ForEach(contactCounts, id: \.self) { count in
                        Text("\(count) contacts")
                            .tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isCreating {
                    ProgressView("Creating contacts...")
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                } else {
                    Button(action: createContacts) {
                        Text("Create Contacts")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Create Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func createContacts() {
        isCreating = true
        
        Task {
            do {
                let store = CNContactStore()
                
                // Request access if needed
                let status = CNContactStore.authorizationStatus(for: .contacts)
                if status == .notDetermined {
                    let granted = try await store.requestAccess(for: .contacts)
                    if !granted {
                        throw NSError(domain: "ContactsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Contacts access denied"])
                    }
                } else if status != .authorized {
                    throw NSError(domain: "ContactsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Contacts access denied"])
                }
                
                // Create contacts in batches
                let batchSize = 50
                let totalBatches = (selectedCount + batchSize - 1) / batchSize
                
                for batch in 0..<totalBatches {
                    let startIndex = batch * batchSize
                    let endIndex = min(startIndex + batchSize, selectedCount)
                    let batchSize = endIndex - startIndex
                    
                    // Create a batch of contacts
                    for i in 0..<batchSize {
                        let contact = CNMutableContact()
                        let number = startIndex + i + 1
                        
                        // Set basic contact information
                        contact.givenName = "Contact"
                        contact.familyName = "\(number)"
                        
                        // Add a phone number
                        let phoneNumber = CNPhoneNumber(stringValue: "+1\(String(format: "%09d", number))")
                        contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: phoneNumber)]
                        
                        // Add an email
                        let email = "contact\(number)@example.com"
                        contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: email as NSString)]
                        
                        // Save the contact
                        let saveRequest = CNSaveRequest()
                        saveRequest.add(contact, toContainerWithIdentifier: nil)
                        try store.execute(saveRequest)
                    }
                    
                    // Update UI on main thread
                    await MainActor.run {
                        isCreating = true
                    }
                }
                
                // Dismiss the view on success
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ContactCreationView()
} 