import ContactsManager
import SwiftUI

struct UserRegistrationView: View {
  @State private var selectedType: UserRegistrationType = .email
  @State private var contactValue: String = ""
  @State private var showError = false
  @State private var errorMessage: String = ""
  @State private var isRegistering = false
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
            if isRegistering {
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
    if isRegistering { return false }

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

    // Simulate network call with a small delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      UserManager.shared.registerUser(contactValue: contactValue, type: selectedType)
      isRegistered = true
      isRegistering = false
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
