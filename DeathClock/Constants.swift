import Foundation

/// Application-wide constants
enum Constants {
    /// UserDefaults key for settings
    static let settingsKey = "com.deathclock.settings"
    
    /// Display update intervals
    enum UpdateInterval {
        static let hourly: TimeInterval = 3600
        static let settingsDebounce: TimeInterval = 0.1 // 100ms
        static let settingsSaveDelay: TimeInterval = 0.3
        static let initialSettingsDelay: TimeInterval = 0.5
    }
    
    /// UI dimensions
    enum UI {
        static let popoverWidth: CGFloat = 400
        static let popoverHeight: CGFloat = 420
    }
    
    /// Life expectancy calculation
    enum LifeExpectancy {
        static let daysPerYear: Double = 365.25
    }
}

