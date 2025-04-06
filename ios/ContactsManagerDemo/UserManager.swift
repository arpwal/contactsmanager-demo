import Foundation
import ContactsManager
import SwiftUI

enum UserRegistrationType {
  case email
  case phoneNumber
}

class UserManager {
  static let shared = UserManager()

  private let userIdKey = "com.contactsmanager.userId"
  private let userContactKey = "com.contactsmanager.userContact"
  private let userTypeKey = "com.contactsmanager.userType"
  private let userInfoKey = "com.contactsmanager.userInfo"

  private init() {}

  var isRegistered: Bool {
    getUserId() != nil && getUserContact() != nil
  }

  func getUserId() -> String? {
    UserDefaults.standard.string(forKey: userIdKey)
  }

  func getUserContact() -> String? {
    UserDefaults.standard.string(forKey: userContactKey)
  }

  func getUserType() -> UserRegistrationType {
    let typeRawValue = UserDefaults.standard.integer(forKey: userTypeKey)
    return typeRawValue == 0 ? .email : .phoneNumber
  }

  func setUserInfo(_ userInfo: UserInfo) {
    do {
      let userInfoData = try JSONEncoder().encode(userInfo)
      UserDefaults.standard.set(userInfoData, forKey: userInfoKey)
    } catch {
      print("Error encoding user info: \(error)")
    }
  }

  func getUserInfo() -> UserInfo? {
    guard let userInfoData = UserDefaults.standard.data(forKey: userInfoKey) else {
      return nil
    }
    return try? JSONDecoder().decode(UserInfo.self, from: userInfoData)
  }

  func registerUser(contactValue: String, type: UserRegistrationType) {
    // Generate a random UUID for the user
    let userId = UUID().uuidString

    // Store values in UserDefaults
    UserDefaults.standard.set(userId, forKey: userIdKey)
    UserDefaults.standard.set(contactValue, forKey: userContactKey)
    UserDefaults.standard.set(type == .email ? 0 : 1, forKey: userTypeKey)

    // Notify observers that user registration changed
    NotificationCenter.default.post(name: .userRegistrationChanged, object: nil)
  }

  func clearRegistration() {
    // Remove all user registration data from UserDefaults
    UserDefaults.standard.removeObject(forKey: userIdKey)
    UserDefaults.standard.removeObject(forKey: userContactKey)
    UserDefaults.standard.removeObject(forKey: userTypeKey)

    // Notify observers that user registration changed
    NotificationCenter.default.post(name: .userRegistrationChanged, object: nil)
  }

  func isValidEmail(_ email: String) -> Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: email)
  }

  func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
    // Simple validation - at least 10 digits
    let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted)
      .joined()
    return digitsOnly.count >= 10
  }
}

// Add a notification name for user registration changes
extension Notification.Name {
  static let userRegistrationChanged = Notification.Name("userRegistrationChanged")
}
