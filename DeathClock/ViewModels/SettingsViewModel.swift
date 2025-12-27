import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    private let settingsManager = SettingsManager.shared
    private let calculator = LifeExpectancyCalculator.shared
    private let displayFormatter = DisplayFormatter()
    private let launchAtLoginManager = LaunchAtLoginManager.shared
    
    @Published var dateOfBirth: Date = UserProfile.default.dateOfBirth
    @Published var selectedSex: UserProfile.Sex = .male
    @Published var selectedCountry: String = "United States"
    @Published var region: String = ""
    @Published var displayFormat: AppSettings.DisplayFormat = .yearsAndDays
    @Published var mementoMode: AppSettings.MementoMode = .mementoMori
    @Published var showIcon: Bool = false
    @Published var startAtLogin: Bool = false
    @Published var previewDays: Int?
    
    private var saveTask: DispatchWorkItem?
    
    var countries: [String] {
        LifeExpectancyDataLoader.shared.availableCountries
    }
    
    var currentProfile: UserProfile {
        UserProfile(
            dateOfBirth: dateOfBirth,
            sex: selectedSex,
            location: UserProfile.Location(
                country: selectedCountry,
                region: region.isEmpty ? nil : region
            )
        )
    }
    
    init() {
        // Initialize with existing settings if available
        let settings = settingsManager.settings
        if let profile = settings.userProfile {
            dateOfBirth = normalizeDate(profile.dateOfBirth)
            selectedSex = profile.sex
            selectedCountry = profile.location.country
            region = profile.location.region ?? ""
        }
        displayFormat = settings.displayFormat
        mementoMode = settings.mementoMode
        showIcon = settings.showIcon
        startAtLogin = settings.startAtLogin
        
        // Sync startAtLogin with actual system state
        startAtLogin = launchAtLoginManager.isEnabled
        
        // Initial preview calculation
        updatePreview()
    }
    
    func updatePreview() {
        previewDays = calculator.calculateDaysRemaining(profile: currentProfile)
    }
    
    /// Normalize date to nearest valid year if invalid
    /// - Parameter date: The date to validate
    /// - Returns: The same date in the nearest valid year
    func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // If date is in the future, move to same date in current year
        if date > now {
            let components = calendar.dateComponents([.month, .day], from: date)
            var currentYearComponents = calendar.dateComponents([.year], from: now)
            currentYearComponents.month = components.month
            currentYearComponents.day = components.day
            if let normalized = calendar.date(from: currentYearComponents), normalized <= now {
                return normalized
            }
            // If that date is still in the future (e.g., Dec 31), use yesterday
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
        
        // If date is too far in the past, move to same date in the minimum valid year
        let minValidDate = Constants.DateValidation.minValidDate
        // Compare dates at start of day to avoid time component issues
        let dateStartOfDay = calendar.startOfDay(for: date)
        let minValidStartOfDay = calendar.startOfDay(for: minValidDate)
        
        if dateStartOfDay < minValidStartOfDay {
            let components = calendar.dateComponents([.month, .day], from: date)
            var minYearComponents = calendar.dateComponents([.year], from: minValidDate)
            minYearComponents.month = components.month
            minYearComponents.day = components.day
            if let normalized = calendar.date(from: minYearComponents) {
                let normalizedStartOfDay = calendar.startOfDay(for: normalized)
                if normalizedStartOfDay >= minValidStartOfDay {
                    return normalized
                }
            }
            // If normalized date is still before minValidDate (e.g., June 15 vs Dec 25 in same year),
            // use minValidDate itself
            return minValidDate
        }
        
        // Date is valid
        return date
    }
    
    func formatPreview(for format: AppSettings.DisplayFormat) -> String {
        guard let days = previewDays else {
            return format.rawValue
        }
        return displayFormatter.formatPreview(profile: currentProfile, daysRemaining: days, format: format, mode: mementoMode)
    }
    
    func debouncedSave() {
        // Cancel any pending save
        saveTask?.cancel()
        
        // Create a new save task with a small delay
        let task = DispatchWorkItem { [weak self] in
            self?.saveSettings()
        }
        saveTask = task
        
        // Dispatch after a short delay to debounce rapid changes
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.UpdateInterval.settingsSaveDelay, execute: task)
    }
    
    private func saveSettings() {
        // Update settings
        settingsManager.settings.userProfile = currentProfile
        settingsManager.settings.displayFormat = displayFormat
        settingsManager.settings.mementoMode = mementoMode
        settingsManager.settings.showIcon = showIcon
        settingsManager.settings.startAtLogin = startAtLogin
        
        // Update launch at login setting
        launchAtLoginManager.setEnabled(startAtLogin)
        
        // Update menu bar display
        MenuBarController.shared.updateDisplay()
    }
}

