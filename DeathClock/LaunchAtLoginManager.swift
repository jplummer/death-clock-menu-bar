import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private let userDefaultsKey = "launchAtLoginEnabled"
    private var appService: SMAppService?
    
    private init() {
        // Initialize the app service
        appService = SMAppService.mainApp
    }
    
    var isEnabled: Bool {
        // Check the actual system state using SMAppService
        return appService?.status == .enabled
    }
    
    func setEnabled(_ enabled: Bool) {
        // Save preference
        UserDefaults.standard.set(enabled, forKey: userDefaultsKey)
        
        guard let appService = appService else { return }
        
        do {
            if enabled {
                try appService.register()
            } else {
                try appService.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            // Note: This may require user to grant permission in System Settings
        }
    }
}

