import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    private init() {
        self.settings = Self.loadSettings()
    }
    
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: Constants.settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: Constants.settingsKey)
        }
    }
    
    var hasCompletedSetup: Bool {
        settings.userProfile != nil
    }
}

