import Foundation

class ConfigurationManager {
  static let shared = ConfigurationManager()

  private init() {}

  // Set your API key here directly if you're having trouble with xcconfig files
  // IMPORTANT: Replace this with your actual API key for production
  private let directAPIKey = "demo_api_key_12345678901234567890123456789012"

  // API configuration
  var apiKey: String {
    // 1. Try to get from Info.plist
    if let value = Bundle.main.infoDictionary?["API_KEY"] as? String,
      !value.isEmpty,
      !value.contains("$(") {
      return value
    }

    // 2. Try environment variables
    if let envValue = ProcessInfo.processInfo.environment["API_KEY"],
      !envValue.isEmpty {
      return envValue
    }

    // 3. Use direct API key as fallback
    #if DEBUG
      print(
        "⚠️ Using fallback API key. For production, replace with your actual key in ConfigurationManager.swift"
      )
    #endif

    return directAPIKey
  }
}
