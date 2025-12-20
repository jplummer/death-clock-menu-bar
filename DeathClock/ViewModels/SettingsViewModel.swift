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
            dateOfBirth = profile.dateOfBirth
            selectedSex = profile.sex
            selectedCountry = profile.location.country
            region = profile.location.region ?? ""
        }
        displayFormat = settings.displayFormat
        mementoMode = settings.mementoMode
        startAtLogin = settings.startAtLogin
        
        // Sync startAtLogin with actual system state
        startAtLogin = launchAtLoginManager.isEnabled
        
        // Initial preview calculation
        updatePreview()
    }
    
    func updatePreview() {
        previewDays = calculator.calculateDaysRemaining(profile: currentProfile)
    }
    
    func formatPreview(for format: AppSettings.DisplayFormat) -> String {
        guard let days = previewDays else {
            return format.rawValue
        }
        return displayFormatter.formatPreview(profile: currentProfile, daysRemaining: days, format: format)
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
        settingsManager.settings.startAtLogin = startAtLogin
        
        // Update launch at login setting
        launchAtLoginManager.setEnabled(startAtLogin)
        
        // Update menu bar display
        MenuBarController.shared.updateDisplay()
    }
}

