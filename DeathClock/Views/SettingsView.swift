import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var selectedSex: UserProfile.Sex = .male
    @State private var selectedCountry: String = "United States"
    @State private var region: String = ""
    @State private var displayFormat: AppSettings.DisplayFormat = .yearsAndDays
    @State private var mementoMode: AppSettings.MementoMode = .mementoMori
    @State private var startAtLogin: Bool = false
    @State private var previewDays: Int?
    @State private var saveTask: DispatchWorkItem?
    
    private let countries = [
        "United States", "United Kingdom", "Canada", "Australia",
        "Germany", "France", "Japan", "China", "India", "Brazil", "Mexico"
    ]
    
    init() {
        // Initialize with existing settings if available
        let settings = SettingsManager.shared.settings
        if let profile = settings.userProfile {
            _dateOfBirth = State(initialValue: profile.dateOfBirth)
            _selectedSex = State(initialValue: profile.sex)
            _selectedCountry = State(initialValue: profile.location.country)
            _region = State(initialValue: profile.location.region ?? "")
        }
        _displayFormat = State(initialValue: settings.displayFormat)
        _mementoMode = State(initialValue: settings.mementoMode)
        _startAtLogin = State(initialValue: settings.startAtLogin)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Death Clock Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    MenuBarController.shared.closePopover()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.bottom, 10)
                
                GroupBox("Personal Information") {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Date of Birth")
                                .font(.headline)
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Sex")
                                .font(.headline)
                            Picker("", selection: $selectedSex) {
                                ForEach(UserProfile.Sex.allCases, id: \.self) { sex in
                                    Text(sex.rawValue).tag(sex)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Country")
                                .font(.headline)
                            Picker("", selection: $selectedCountry) {
                                ForEach(countries, id: \.self) { country in
                                    Text(country).tag(country)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Region (Optional)")
                                .font(.headline)
                            TextField("State, Province, etc.", text: $region)
                        }
                    }
                    .padding()
                }
                
                GroupBox("Display Options") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Display Format")
                            .font(.headline)
                        Picker("", selection: $displayFormat) {
                            ForEach(AppSettings.DisplayFormat.allCases, id: \.self) { format in
                                Text(formatPreview(for: format)).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text(formatDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Memento Mode")
                                .font(.headline)
                            Picker("", selection: $mementoMode) {
                                ForEach(AppSettings.MementoMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding()
                }
            
            GroupBox("General") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Start at Login", isOn: $startAtLogin)
                        .onChange(of: startAtLogin) { debouncedSave() }
                }
                .padding()
            }
            
            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            updatePreview()
            // Sync startAtLogin with actual system state
            startAtLogin = LaunchAtLoginManager.shared.isEnabled
        }
        .onChange(of: dateOfBirth) { 
            updatePreview()
            debouncedSave() 
        }
        .onChange(of: selectedSex) { 
            updatePreview()
            debouncedSave() 
        }
        .onChange(of: selectedCountry) { 
            updatePreview()
            debouncedSave() 
        }
        .onChange(of: region) { debouncedSave() }
        .onChange(of: displayFormat) { debouncedSave() }
        .onChange(of: mementoMode) { debouncedSave() }
    }
    
    private func updatePreview() {
        let profile = UserProfile(
            dateOfBirth: dateOfBirth,
            sex: selectedSex,
            location: UserProfile.Location(
                country: selectedCountry,
                region: region.isEmpty ? nil : region
            )
        )
        previewDays = LifeExpectancyCalculator.shared.calculateDaysRemaining(profile: profile)
    }
    
    private func formatPreview(for format: AppSettings.DisplayFormat) -> String {
        guard let days = previewDays else {
            return format.rawValue
        }
        
        let calculator = LifeExpectancyCalculator.shared
        let profile = UserProfile(
            dateOfBirth: dateOfBirth,
            sex: selectedSex,
            location: UserProfile.Location(
                country: selectedCountry,
                region: region.isEmpty ? nil : region
            )
        )
        
        switch format {
        case .daysOnly:
            return calculator.formatDaysRemaining(days, format: format)
        case .yearsAndDays:
            return calculator.formatDaysRemaining(days, format: format)
        case .percentage:
            if let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) {
                return calculator.formatDaysRemaining(days, format: format, totalDays: totalDays)
            }
            return format.rawValue
        case .progressBar:
            // For progress bar, show a text representation (percentage remaining)
            if let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) {
                let percentage = calculator.calculatePercentage(daysRemaining: days, totalDays: totalDays)
                // Show progress bar with remaining percentage
                // More filled = more remaining
                let filledBlocks = Int((percentage / 100.0) * 8.0)
                let emptyBlocks = 8 - filledBlocks
                let filled = String(repeating: "▓", count: filledBlocks)
                let empty = String(repeating: "░", count: emptyBlocks)
                return String(format: "%@%@ %.0f%%", filled, empty, percentage)
            }
            return format.rawValue
        }
    }
    
    private func debouncedSave() {
        // Cancel any pending save
        saveTask?.cancel()
        
        // Create a new save task with a small delay
        let task = DispatchWorkItem {
            self.saveSettings()
        }
        saveTask = task
        
        // Dispatch after a short delay to debounce rapid changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
    
    private var formatDescription: String {
        switch displayFormat {
        case .daysOnly:
            return "Shows total days (e.g., 8724)"
        case .yearsAndDays:
            return "Shows years and days (e.g., 23y 224d)"
        case .percentage:
            return "Shows percentage of life remaining (e.g., 55%)"
        case .progressBar:
            return "Shows visual progress bar with remaining percentage"
        }
    }
    
    private func saveSettings() {
        // Prevent recursive updates by checking if we're already saving
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.saveSettings()
            }
            return
        }
        
        let profile = UserProfile(
            dateOfBirth: dateOfBirth,
            sex: selectedSex,
            location: UserProfile.Location(
                country: selectedCountry,
                region: region.isEmpty ? nil : region
            )
        )
        
        // Update settings without triggering view updates
        settingsManager.updateUserProfile(profile)
        settingsManager.settings.displayFormat = displayFormat
        settingsManager.settings.mementoMode = mementoMode
        settingsManager.settings.startAtLogin = startAtLogin
        
        // Update launch at login setting
        LaunchAtLoginManager.shared.setEnabled(startAtLogin)
        
        // Update menu bar display on next run loop to avoid layout recursion
        DispatchQueue.main.async {
            MenuBarController.shared.updateDisplay()
        }
    }
}

