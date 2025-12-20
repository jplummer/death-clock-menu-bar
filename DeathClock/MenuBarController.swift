import SwiftUI
import AppKit
import Combine

@MainActor
class MenuBarController: NSObject, ObservableObject, NSPopoverDelegate {
    static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private let settingsManager = SettingsManager.shared
    private let calculator = LifeExpectancyCalculator.shared
    private let displayFormatter = DisplayFormatter()
    
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
            .debounce(for: .seconds(Constants.UpdateInterval.settingsDebounce), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDisplay()
            }
            .store(in: &cancellables)
        
        // Check if setup is needed
        if !settingsManager.hasCompletedSetup {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Constants.UpdateInterval.initialSettingsDelay * 1_000_000_000))
                showSettings()
            }
        }
        
        // Update display periodically
        Timer.scheduledTimer(withTimeInterval: Constants.UpdateInterval.hourly, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [self] in
                self.updateDisplay()
            }
        }
    }
    
    private func setupStatusItem() {
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
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        // Close existing popover if open
        if let existingPopover = popover, existingPopover.isShown {
            existingPopover.performClose(nil)
        }
        
        // Create new popover
        popover = NSPopover()
        popover?.behavior = .transient // This makes it close when clicking outside
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        // Wrap in container with proper margins
        let containerView = NSView()
        // Ensure container doesn't interfere with popover's click-outside detection
        containerView.wantsLayer = false
        containerView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        hostingController.view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hostingController.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        hostingController.view.setContentCompressionResistancePriority(.required, for: .horizontal)
        hostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let containerController = NSViewController()
        containerController.view = containerView
        popover?.contentViewController = containerController
        
        // Set delegate BEFORE showing to ensure proper click-outside detection
        popover?.delegate = self
        
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Add event monitor to detect clicks outside popover (even when controls have focus)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self,
                  let popover = self.popover,
                  popover.isShown,
                  let popoverWindow = popover.contentViewController?.view.window else {
                return event
            }
            
            let clickedWindow = event.window
            
            // If click is in a different window, close the popover
            if clickedWindow != popoverWindow {
                self.closePopover()
                return nil // Consume the event
            }
            
            // Click is in the popover window - check if it's outside the content view
            if let contentView = popover.contentViewController?.view {
                let locationInWindow = event.locationInWindow
                let pointInContentView = contentView.convert(locationInWindow, from: nil)
                if !contentView.bounds.contains(pointInContentView) {
                    self.closePopover()
                    return nil // Consume the event
                }
            }
            
            return event
        }
    }
    
    func updateDisplay() {
        // Use user profile or default
        let profile = settingsManager.settings.userProfile ?? .default
        let format = settingsManager.settings.displayFormat
        
        // Calculate days remaining
        guard let days = calculator.calculateDaysRemaining(profile: profile) else {
            displayText = "Setup"
            displayImage = nil
            daysRemaining = nil
            updateStatusItem()
            return
        }
        
        daysRemaining = days
        
        // Format display content
        let content = displayFormatter.format(profile: profile, daysRemaining: days, format: format)
        displayText = content.text ?? ""
        displayImage = content.image
        
        updateStatusItem()
    }
    
    private func updateStatusItem() {
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
    
    func closePopover() {
        guard let popover = popover, popover.isShown else { return }
        popover.performClose(nil)
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        // Remove event monitor when popover closes
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        // Clean up when popover closes
        popover = nil
    }
}

