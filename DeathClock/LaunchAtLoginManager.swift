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
        return appService.status == .enabled
    }
    
    /// Applies login-item registration. Returns whether the app state matches `enabled` afterward.
    /// Skips redundant unregister/register calls. On failure, leaves system state unchanged and returns false.
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        guard let appService = appService else { return false }
        
        do {
            if enabled {
                if appService.status == .enabled {
                    UserDefaults.standard.set(true, forKey: userDefaultsKey)
                    return true
                }
                try appService.register()
                UserDefaults.standard.set(true, forKey: userDefaultsKey)
                return true
            } else {
                if appService.status == .notRegistered {
                    UserDefaults.standard.set(false, forKey: userDefaultsKey)
                    return true
                }
                try appService.unregister()
                UserDefaults.standard.set(false, forKey: userDefaultsKey)
                return true
            }
        } catch {
            // "Operation not permitted" is common for Debug/ad hoc builds run from Xcode; SMAppService expects a properly signed app.
            print("Launch at login (\(enabled ? "on" : "off")): \(error.localizedDescription)")
            return false
        }
    }
}

