import ContactsManager
import SwiftUI

struct UserRegistrationView: View {
  @State private var selectedType: UserRegistrationType = .email
  @State private var contactValue: String = ""
  @State private var showError = false
  @State private var errorMessage: String = ""
  @State private var isRegistering = false
  @State private var isInitializing = false
  @State private var contactsAccessStatus: ContactsAccessStatus = .notDetermined

  @Binding var isRegistered: Bool

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        // Header
        Text("Welcome to Contacts Manager")
          .font(.largeTitle)
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
          .padding(.top, 40)

        Text("Please register to continue")
          .font(.headline)
          .foregroundColor(.secondary)

        // Registration form
        VStack(alignment: .leading, spacing: 20) {
          Picker("Registration Type", selection: $selectedType) {
            Text("Email").tag(UserRegistrationType.email)
            Text("Phone Number").tag(UserRegistrationType.phoneNumber)
          }
          .pickerStyle(SegmentedPickerStyle())
          .padding(.vertical)

          if selectedType == .email {
            TextField("Enter your email", text: $contactValue)
              .textContentType(.emailAddress)
              .keyboardType(.emailAddress)
              .autocapitalization(.none)
              .disableAutocorrection(true)
          } else {
            TextField("Enter your phone number", text: $contactValue)
              .textContentType(.telephoneNumber)
              .keyboardType(.phonePad)
          }

          // Contacts access section
          VStack(alignment: .leading, spacing: 12) {
            Text("Contacts Access")
              .font(.headline)

            Text(
              "We need access to your contacts to provide recommendations and contact management features."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)

            HStack {
              if contactsAccessStatus == .authorized {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
                Text("Contacts access granted")
                  .foregroundColor(.green)
              } else {
                Button(action: requestContactsAccess) {
                  HStack {
                    Image(systemName: "lock.open")
                    Text("Grant Contacts Access")
                  }
                  .font(.headline)
                  .padding()
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .background(Color.blue)
                  .cornerRadius(10)
                }
              }
            }
          }
          .padding(.vertical)

          // Register button
          Button(action: registerUser) {
            if isRegistering || isInitializing {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
              Text("Register")
                .font(.headline)
            }
          }
          .padding()
          .frame(maxWidth: .infinity)
          .background(canRegister ? Color.green : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(10)
          .disabled(!canRegister)
        }
        .padding()

        Spacer()
      }
      .padding()
      .navigationBarHidden(true)
      .alert(isPresented: $showError) {
        Alert(
          title: Text("Error"),
          message: Text(errorMessage),
          dismissButton: .default(Text("OK"))
        )
      }
      .onAppear {
        updateContactsAccessStatus()
      }
    }
  }

  private var canRegister: Bool {
    if isRegistering || isInitializing { return false }

    if contactsAccessStatus != .authorized { return false }

    if contactValue.isEmpty { return false }

    if selectedType == .email {
      return UserManager.shared.isValidEmail(contactValue)
    } else {
      return UserManager.shared.isValidPhoneNumber(contactValue)
    }
  }

  private func registerUser() {
    guard canRegister else { return }

    isRegistering = true
    
    // Step 1: First initialize ContactsService
    Task {
      do {
        isInitializing = true
        
        // Register the user
        UserManager.shared.registerUser(contactValue: contactValue, type: selectedType)
        
        // Get API key and user ID
        let apiKey = ConfigurationManager.shared.apiKey
        let userId = UserManager.shared.getUserId() ?? UUID().uuidString
        
        // Create UserInfo with the required fields
        let userInfo = UserInfo(
          userId: userId,
          email: selectedType == .email ? contactValue : nil,
          phone: selectedType == .phoneNumber ? contactValue : nil
        )
        
        UserManager.shared.setUserInfo(userInfo)
        
        // Initialize ContactsService with the UserInfo
        try await ContactsService.shared.initialize(
          withAPIKey: apiKey,
          userInfo: userInfo
        )
        
        print("ContactsService initialized successfully in UserRegistrationView")
        
        // Update UI on main thread
        await MainActor.run {
          isInitializing = false
          isRegistering = false
          isRegistered = true
        }
      } catch {
        // Handle initialization error
        print("Error initializing ContactsService: \(error.localizedDescription)")
        
        await MainActor.run {
          errorMessage = "Failed to initialize service: \(error.localizedDescription)"
          showError = true
          isInitializing = false
          isRegistering = false
          
          // Rollback registration since initialization failed
          UserManager.shared.clearRegistration()
        }
      }
    }
  }

  private func requestContactsAccess() {
    Task {
      let accessGranted = await ContactsService.shared.requestContactsAccess()

      await MainActor.run {
        if accessGranted {
          updateContactsAccessStatus()
        } else {
          errorMessage = "Failed to get contacts access. Please enable access in Settings."
          showError = true
        }
      }
    }
  }

  private func updateContactsAccessStatus() {
    contactsAccessStatus = ContactsService.shared.contactsAccessStatus
  }
}

struct UserRegistrationView_Previews: PreviewProvider {
  static var previews: some View {
    UserRegistrationView(isRegistered: .constant(false))
  }
}
