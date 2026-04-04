import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private let userDefaultsKey = "launchAtLoginEnabled"
    private var appService: SMAppService?
    
    private init() {
        appService = SMAppService.mainApp
    }
    
    var isEnabled: Bool {
        guard let appService = appService else { return false }
        switch appService.status {
        case .enabled:
            return true
        case .requiresApproval, .notRegistered:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Applies login-item registration. Returns whether the app state matches `enabled` afterward.
    /// Skips redundant unregister/register calls. On failure, leaves system state unchanged and returns false.
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        guard let appService = appService else { return false }
        
        do {
            if enabled {
                switch appService.status {
                case .enabled:
                    UserDefaults.standard.set(true, forKey: userDefaultsKey)
                    return true
                case .requiresApproval, .notRegistered:
                    try appService.register()
                    UserDefaults.standard.set(true, forKey: userDefaultsKey)
                    return true
                @unknown default:
                    try appService.register()
                    UserDefaults.standard.set(true, forKey: userDefaultsKey)
                    return true
                }
            } else {
                switch appService.status {
                case .notRegistered:
                    UserDefaults.standard.set(false, forKey: userDefaultsKey)
                    return true
                case .enabled, .requiresApproval:
                    try appService.unregister()
                    UserDefaults.standard.set(false, forKey: userDefaultsKey)
                    return true
                @unknown default:
                    try appService.unregister()
                    UserDefaults.standard.set(false, forKey: userDefaultsKey)
                    return true
                }
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            return false
        }
    }
}

