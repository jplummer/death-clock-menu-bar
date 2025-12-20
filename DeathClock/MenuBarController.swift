import SwiftUI
import AppKit
import Combine

class MenuBarController: NSObject, ObservableObject, NSPopoverDelegate {
    static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let settingsManager = SettingsManager.shared
    private let calculator = LifeExpectancyCalculator.shared
    
    @Published var daysRemaining: Int?
    @Published var displayText: String = "---"
    @Published var displayImage: NSImage?
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        
        setupStatusItem()
        updateDisplay()
        
        // Observe settings changes with debouncing to avoid rapid updates
        settingsManager.$settings
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDisplay()
            }
            .store(in: &cancellables)
        
        // Check if setup is needed
        if !settingsManager.hasCompletedSetup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showSettings()
            }
        }
        
        // Update display periodically
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }
    
    private func setupStatusItem() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setupStatusItem()
            }
            return
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("Warning: Failed to create status item")
            return
        }
        
        guard let button = statusItem.button else {
            print("Warning: Status item button is nil")
            return
        }
        
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        updateDisplay()
    }
    
    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            showSettings()
        }
    }
    
    private func showMenu() {
        guard let statusItem = statusItem,
              statusItem.button != nil else { return }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        if let days = daysRemaining {
            let infoItem = NSMenuItem(title: "Days Remaining: \(days)", action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc private func showSettings() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showSettings()
            }
            return
        }
        
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        // Close existing popover if open
        if let existingPopover = popover, existingPopover.isShown {
            existingPopover.performClose(nil)
        }
        
        // Create new popover
        popover = NSPopover()
        // Size to fit all content comfortably
        popover?.contentSize = NSSize(width: 400, height: 580)
        popover?.behavior = .transient // This makes it close when clicking outside
        popover?.contentViewController = NSHostingController(rootView: SettingsView())
        
        // Set delegate to handle closing behavior
        popover?.delegate = self
        
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    func updateDisplay() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateDisplay()
            }
            return
        }
        
        guard let profile = settingsManager.settings.userProfile else {
            // Show default calculation (30 years ago) instead of "Setup"
            let defaultDateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
            let defaultProfile = UserProfile(
                dateOfBirth: defaultDateOfBirth,
                sex: .male,
                location: UserProfile.Location(country: "United States", region: nil)
            )
            
            if let days = calculator.calculateDaysRemaining(profile: defaultProfile) {
                let format = settingsManager.settings.displayFormat
                if format == .progressBar {
                    if let totalDays = calculator.calculateTotalDaysFromBirth(profile: defaultProfile) {
                        let elapsedPercentage = calculator.calculateElapsedPercentage(daysRemaining: days, totalDays: totalDays)
                        let remainingPercentage = calculator.calculatePercentage(daysRemaining: days, totalDays: totalDays)
                        displayImage = createProgressBarImage(fillPercentage: elapsedPercentage, textPercentage: remainingPercentage)
                        displayText = ""
                    } else {
                        displayText = calculator.formatDaysRemaining(days, format: format)
                        displayImage = nil
                    }
                } else {
                    let totalDays = format == .percentage ? calculator.calculateTotalDaysFromBirth(profile: defaultProfile) : nil
                    displayText = calculator.formatDaysRemaining(days, format: format, totalDays: totalDays)
                    displayImage = nil
                }
            } else {
                displayText = "Setup"
                displayImage = nil
            }
            updateStatusItem()
            return
        }
        
        daysRemaining = calculator.calculateDaysRemaining(profile: profile)
        
        let format = settingsManager.settings.displayFormat
        
        if let days = daysRemaining {
            if format == .progressBar {
                // For progress bar, create an image
                if let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) {
                    // Progress bar fill shows elapsed (increasing), percentage text shows remaining
                    let elapsedPercentage = calculator.calculateElapsedPercentage(daysRemaining: days, totalDays: totalDays)
                    let remainingPercentage = calculator.calculatePercentage(daysRemaining: days, totalDays: totalDays)
                    displayImage = createProgressBarImage(fillPercentage: elapsedPercentage, textPercentage: remainingPercentage)
                    displayText = ""
                } else {
                    displayText = "Error"
                    displayImage = nil
                }
            } else {
                // For text formats, use text
                // Percentage format also needs totalDays
                let totalDays = (format == .percentage) ? calculator.calculateTotalDaysFromBirth(profile: profile) : nil
                displayText = calculator.formatDaysRemaining(days, format: format, totalDays: totalDays)
                displayImage = nil
            }
        } else {
            displayText = "Error"
            displayImage = nil
        }
        
        updateStatusItem()
    }
    
    private func updateStatusItem() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateStatusItem()
            }
            return
        }
        
        guard let statusItem = statusItem,
              let button = statusItem.button else {
            return
        }
        
        // Update image or text based on format
        if let image = displayImage {
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            if button.title != displayText {
                button.title = displayText
            }
        }
        
        let newToolTip = daysRemaining != nil ? "\(daysRemaining!) days remaining" : "Death Clock"
        if button.toolTip != newToolTip {
            button.toolTip = newToolTip
        }
    }
    
    /// Create a progress bar image for the menu bar
    /// - Parameters:
    ///   - fillPercentage: Percentage of bar to fill (elapsed time, 0-100)
    ///   - textPercentage: Percentage to display as text (remaining time, 0-100)
    private func createProgressBarImage(fillPercentage: Double, textPercentage: Double) -> NSImage {
        let width: CGFloat = 60
        let height: CGFloat = 14
        let barHeight: CGFloat = 6
        let percentageText = String(format: "%.0f%%", textPercentage)
        
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Draw background (transparent)
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: image.size).fill()
        
        // Draw progress bar background (greyscale, visible in both modes)
        let barRect = NSRect(x: 0, y: (height - barHeight) / 2, width: width - 30, height: barHeight)
        // Use a very light greyscale for the track (maximum contrast)
        NSColor(white: 0.85, alpha: 0.8).setFill()
        barRect.fill()
        
        // Draw progress bar fill (greyscale, very dark for maximum contrast)
        // Fill shows elapsed time, so it increases as days pass
        let fillWidth = (width - 30) * CGFloat(fillPercentage / 100.0)
        let fillRect = NSRect(x: 0, y: (height - barHeight) / 2, width: fillWidth, height: barHeight)
        // Use a very dark greyscale for maximum contrast against the light track
        NSColor(white: 0.05, alpha: 1.0).setFill()
        fillRect.fill()
        
        // Draw percentage text (smaller, greyscale) - shows remaining
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.labelColor // This adapts to light/dark mode automatically
        ]
        let attributedString = NSAttributedString(string: percentageText, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = NSRect(
            x: width - 28,
            y: (height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)
        
        image.unlockFocus()
        return image
    }
    
    func closePopover() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.closePopover()
            }
            return
        }
        
        guard let popover = popover, popover.isShown else { return }
        popover.performClose(nil)
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        // Clean up when popover closes
        popover = nil
    }
}

