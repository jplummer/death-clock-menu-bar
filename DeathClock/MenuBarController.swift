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
        let mode = settingsManager.settings.mementoMode
        
        // Calculate days remaining (for mori mode) or days lived (for vivere mode)
        guard let days = calculator.calculateDaysRemaining(profile: profile) else {
            displayText = "Setup"
            displayImage = nil
            daysRemaining = nil
            updateStatusItem()
            return
        }
        
        daysRemaining = days
        
        // Get color from button to match other menu bar items
        let color: NSColor
        if let button = statusItem?.button, let tintColor = button.contentTintColor {
            color = tintColor
        } else {
            // Fallback: use white (typical menu bar color)
            color = NSColor.white
        }
        
        // Format display content
        let content = displayFormatter.format(profile: profile, daysRemaining: days, format: format, mode: mode, color: color)
        displayText = content.text ?? ""
        displayImage = content.image
        
        updateStatusItem()
    }
    
    private func updateStatusItem() {
        guard let statusItem = statusItem,
              let button = statusItem.button else {
            return
        }
        
        let settings = settingsManager.settings
        let mode = settings.mementoMode
        
        // Determine if we should show an icon
        var iconImage: NSImage?
        if settings.showIcon {
            if mode == .mementoMori {
                iconImage = loadSVGIcon(named: "tombstone")
            } else if mode == .mementoVivere {
                iconImage = loadSVGIcon(named: "tree")
            }
        }
        
        // Update image or text based on format
        if let image = displayImage {
            // Progress bar format uses image (icons not shown in progress bar mode)
            button.image = image
            button.title = ""
        } else {
            // Text format - combine icon with text if icon is enabled
            if let icon = iconImage {
                // Create combined image with icon and text
                let combinedImage = createIconTextImage(icon: icon, text: displayText)
                button.image = combinedImage
                button.title = ""
            } else {
                button.image = nil
                // Use attributed string with condensed font for menu bar text
                // Don't set foregroundColor - let the system use the default menu bar text color
                let font = getCondensedMenuBarFont()
                let attributedTitle = NSAttributedString(string: displayText, attributes: [
                    .font: font
                ])
                button.attributedTitle = attributedTitle
            }
        }
        
        // Update tooltip based on mode
        let newToolTip: String
        if let days = daysRemaining {
            switch mode {
            case .mementoMori:
                newToolTip = "\(days) days remaining"
            case .mementoVivere:
                let daysLived = calculator.calculateDaysLived(profile: settings.userProfile ?? .default)
                newToolTip = "\(daysLived) days lived"
            }
        } else {
            newToolTip = "Death Clock"
        }
        
        if button.toolTip != newToolTip {
            button.toolTip = newToolTip
        }
    }
    
    /// Load icon image from Resources (SVG) or create programmatically
    private func loadSVGIcon(named: String) -> NSImage? {
        // Try to load and render SVG from Resources first
        // Try with subdirectory first
        if let svgURL = Bundle.main.url(forResource: named, withExtension: "svg", subdirectory: "Resources") {
            if let svgData = try? Data(contentsOf: svgURL),
               let svgString = String(data: svgData, encoding: .utf8) {
                // Try to render the SVG (smaller size)
                if let renderedImage = renderSVG(svgString: svgString, size: NSSize(width: 13, height: 13)) {
                    return renderedImage
                }
            }
        }
        
        // Try without subdirectory (in case files are at bundle root)
        if let svgURL = Bundle.main.url(forResource: named, withExtension: "svg") {
            if let svgData = try? Data(contentsOf: svgURL),
               let svgString = String(data: svgData, encoding: .utf8) {
                // Try to render the SVG (smaller size)
                if let renderedImage = renderSVG(svgString: svgString, size: NSSize(width: 13, height: 13)) {
                    return renderedImage
                }
            }
        }
        
        // Debug: Check if files exist in bundle
        // Note: SVG files must be added to Xcode project and included in target
        // If SVG files aren't found, we'll fall back to programmatic icons below
        
        // Fallback to programmatic creation if SVG loading/rendering failed
        switch named {
        case "tombstone":
            return createTombstoneIcon()
        case "tree":
            return createTreeIcon()
        default:
            // Final fallback to SF Symbol
            if named == "tombstone" {
                return NSImage(systemSymbolName: "tombstone.fill", accessibilityDescription: "Tombstone")
            } else if named == "tree" {
                return NSImage(systemSymbolName: "tree.fill", accessibilityDescription: "Tree")
            }
            return nil
        }
    }
    
    /// Render SVG string to NSImage with appropriate color for light/dark mode
    private func renderSVG(svgString: String, size: NSSize) -> NSImage? {
        // Get color from status item button to match other menu bar items
        let strokeColor: NSColor
        if let button = statusItem?.button, let tintColor = button.contentTintColor {
            strokeColor = tintColor
        } else {
            // Fallback: use white (typical menu bar color)
            strokeColor = NSColor.white
        }
        
        // Replace white with system color in SVG
        var modifiedSVG = svgString
        let hexColor = strokeColor.usingColorSpace(.deviceRGB)?.hexString ?? "#000000"
        // Replace stroke="white" with the system color
        modifiedSVG = modifiedSVG.replacingOccurrences(of: "stroke=\"white\"", with: "stroke=\"\(hexColor)\"")
        // Replace fill="white" with the system color
        modifiedSVG = modifiedSVG.replacingOccurrences(of: "fill=\"white\"", with: "fill=\"\(hexColor)\"")
        
        // Use Core Graphics to render SVG
        // Create a web view or use a simpler approach with path parsing
        return renderSVGWithPaths(svgString: modifiedSVG, size: size, strokeColor: strokeColor)
    }
    
    /// Render SVG by parsing paths and drawing with NSBezierPath
    private func renderSVGWithPaths(svgString: String, size: NSSize, strokeColor: NSColor) -> NSImage? {
        let image = NSImage(size: size)
        image.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        // Scale from 128x128 viewBox to target size
        let scale = size.width / 128.0
        
        // Create transform: scale, then flip Y-axis (SVG has Y=0 at top, AppKit has Y=0 at bottom)
        let transform = NSAffineTransform()
        transform.scale(by: scale)
        transform.translateX(by: 0, yBy: 128.0) // Move to top
        transform.scaleX(by: 1.0, yBy: -1.0) // Flip Y-axis
        transform.concat()
        
        strokeColor.setStroke()
        strokeColor.setFill()
        
        // Parse path elements from SVG
        let nsString = svgString as NSString
        var pathsRendered = false
        
        // First, find the range of any <mask> tags to exclude paths inside them
        var maskRanges: [NSRange] = []
        let maskPattern = #"<mask[^>]*>.*?</mask>"#
        if let maskRegex = try? NSRegularExpression(pattern: maskPattern, options: [.dotMatchesLineSeparators]) {
            let maskMatches = maskRegex.matches(in: svgString, options: [], range: NSRange(location: 0, length: nsString.length))
            maskRanges = maskMatches.map { $0.range }
        }
        
        // Match all path elements (more flexible pattern - handles multiline)
        let pathPattern = #"<path[^>]*d="([^"]*)"[^>]*/?>"#
        if let regex = try? NSRegularExpression(pattern: pathPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: svgString, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if match.numberOfRanges >= 2 {
                    let pathString = nsString.substring(with: match.range(at: 1))
                    let fullMatch = nsString.substring(with: match.range)
                    
                    // Skip paths that are inside mask definitions
                    let isInMask = maskRanges.contains { maskRange in
                        NSIntersectionRange(match.range, maskRange).length > 0
                    }
                    if isInMask {
                        continue
                    }
                    
                    // Parse stroke-width if present
                    var strokeWidth: CGFloat = 8.0 * scale // Default
                    let strokeWidthPattern = #"stroke-width="(\d+)""#
                    if let strokeWidthRegex = try? NSRegularExpression(pattern: strokeWidthPattern, options: []) {
                        let strokeWidthMatches = strokeWidthRegex.matches(in: fullMatch, options: [], range: NSRange(location: 0, length: (fullMatch as NSString).length))
                        if let strokeWidthMatch = strokeWidthMatches.first, strokeWidthMatch.numberOfRanges >= 2 {
                            let strokeWidthRange = strokeWidthMatch.range(at: 1)
                            let strokeWidthString = (fullMatch as NSString).substring(with: strokeWidthRange)
                            if let width = Double(strokeWidthString) {
                                strokeWidth = CGFloat(width) * scale
                            }
                        }
                    }
                    // Ensure minimum stroke width for visibility in menu bar
                    // For 16x16 icons, we want thicker strokes (2-2.5 points) to match the visual weight of filled shapes
                    if strokeWidth < 2.0 {
                        strokeWidth = 2.0
                    }
                    
                    // Check if path has stroke or fill (use fullMatch from modified SVG which has color replacements)
                    let hasStroke = fullMatch.contains("stroke=") && !fullMatch.contains("stroke=\"none\"")
                    let hasFill = fullMatch.contains("fill=") && !fullMatch.contains("fill=\"none\"")
                    
                    if let path = parseSVGPathData(pathString) {
                        if hasStroke {
                            // Ensure stroke color is set (might have been overridden)
                            strokeColor.setStroke()
                            path.lineWidth = strokeWidth
                            // Ensure minimum stroke width for visibility (at least 0.5 points)
                            if path.lineWidth < 0.5 {
                                path.lineWidth = 0.5
                            }
                            // Check for stroke-linecap
                            if fullMatch.contains("stroke-linecap=\"round\"") {
                                path.lineCapStyle = .round
                            }
                            path.stroke()
                            pathsRendered = true
                        }
                        if hasFill {
                            // Ensure fill color is set
                            strokeColor.setFill()
                            path.fill()
                            pathsRendered = true
                        }
                    }
                }
            }
        }
        
        image.unlockFocus()
        
        // Only return image if we actually rendered something
        if pathsRendered {
            image.isTemplate = false // We're handling colors ourselves
            return image
        }
        
        return nil
    }
    
    /// Parse SVG path data (compact format like "M64 4C89.4051 4...")
    private func parseSVGPathData(_ pathData: String) -> NSBezierPath? {
        let path = NSBezierPath()
        var currentPoint = NSPoint.zero
        var i = pathData.startIndex
        
        while i < pathData.endIndex {
            let char = pathData[i]
            
            // Skip whitespace and commas
            if char.isWhitespace || char == "," {
                i = pathData.index(after: i)
                continue
            }
            
            // Parse command and coordinates
            if char.isLetter {
                let command = char
                i = pathData.index(after: i)
                
                // Parse numbers for this command
                var numbers: [Double] = []
                while i < pathData.endIndex {
                    // Skip whitespace and commas
                    if pathData[i].isWhitespace || pathData[i] == "," {
                        i = pathData.index(after: i)
                        continue
                    }
                    
                    // Check if next character is a letter (new command)
                    if pathData[i].isLetter {
                        break
                    }
                    
                    // Parse number
                    var numberEnd = i
                    while numberEnd < pathData.endIndex && 
                          (pathData[numberEnd].isNumber || pathData[numberEnd] == "." || pathData[numberEnd] == "-" || pathData[numberEnd] == "e" || pathData[numberEnd] == "E" || pathData[numberEnd] == "+") {
                        numberEnd = pathData.index(after: numberEnd)
                    }
                    
                    if let number = Double(String(pathData[i..<numberEnd])) {
                        numbers.append(number)
                    }
                    i = numberEnd
                }
                
                // Execute command
                switch command {
                case "M", "m": // Move to
                    if numbers.count >= 2 {
                        let x = command == "M" ? numbers[0] : currentPoint.x + numbers[0]
                        let y = command == "M" ? numbers[1] : currentPoint.y + numbers[1]
                        currentPoint = NSPoint(x: x, y: y)
                        path.move(to: currentPoint)
                        // Handle multiple coordinates (implicit L commands)
                        var idx = 2
                        while idx < numbers.count {
                            if idx + 1 < numbers.count {
                                let x = command == "M" ? numbers[idx] : currentPoint.x + numbers[idx]
                                let y = command == "M" ? numbers[idx + 1] : currentPoint.y + numbers[idx + 1]
                                currentPoint = NSPoint(x: x, y: y)
                                path.line(to: currentPoint)
                                idx += 2
                            } else {
                                break
                            }
                        }
                    }
                case "L", "l": // Line to
                    var idx = 0
                    while idx < numbers.count {
                        if idx + 1 < numbers.count {
                            let x = command == "L" ? numbers[idx] : currentPoint.x + numbers[idx]
                            let y = command == "L" ? numbers[idx + 1] : currentPoint.y + numbers[idx + 1]
                            currentPoint = NSPoint(x: x, y: y)
                            path.line(to: currentPoint)
                            idx += 2
                        } else {
                            break
                        }
                    }
                case "H", "h": // Horizontal line
                    for number in numbers {
                        let x = command == "H" ? number : currentPoint.x + number
                        currentPoint = NSPoint(x: x, y: currentPoint.y)
                        path.line(to: currentPoint)
                    }
                case "V", "v": // Vertical line
                    for number in numbers {
                        let y = command == "V" ? number : currentPoint.y + number
                        currentPoint = NSPoint(x: currentPoint.x, y: y)
                        path.line(to: currentPoint)
                    }
                case "C", "c": // Cubic bezier
                    var idx = 0
                    while idx < numbers.count {
                        if idx + 5 < numbers.count {
                            let x1 = command == "C" ? numbers[idx] : currentPoint.x + numbers[idx]
                            let y1 = command == "C" ? numbers[idx + 1] : currentPoint.y + numbers[idx + 1]
                            let x2 = command == "C" ? numbers[idx + 2] : currentPoint.x + numbers[idx + 2]
                            let y2 = command == "C" ? numbers[idx + 3] : currentPoint.y + numbers[idx + 3]
                            let x = command == "C" ? numbers[idx + 4] : currentPoint.x + numbers[idx + 4]
                            let y = command == "C" ? numbers[idx + 5] : currentPoint.y + numbers[idx + 5]
                            path.curve(to: NSPoint(x: x, y: y),
                                      controlPoint1: NSPoint(x: x1, y: y1),
                                      controlPoint2: NSPoint(x: x2, y: y2))
                            currentPoint = NSPoint(x: x, y: y)
                            idx += 6
                        } else {
                            break
                        }
                    }
                case "Z", "z": // Close path
                    path.close()
                default:
                    break
                }
            } else {
                i = pathData.index(after: i)
            }
        }
        
        return path.isEmpty ? nil : path
    }
    
    /// Create tombstone icon programmatically (based on SVG design)
    private func createTombstoneIcon() -> NSImage {
        // Get color from status item button to match other menu bar items
        let strokeColor: NSColor
        if let button = statusItem?.button, let tintColor = button.contentTintColor {
            strokeColor = tintColor
        } else {
            // Fallback: use white (typical menu bar color)
            strokeColor = NSColor.white
        }
        
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        strokeColor.setFill()
        strokeColor.setStroke()
        
        // Tombstone base (rounded rectangle) - scaled from 128x128 to 16x16
        let baseRect = NSRect(x: 4, y: 10, width: 8, height: 4)
        let basePath = NSBezierPath(roundedRect: baseRect, xRadius: 0.5, yRadius: 0.5)
        basePath.fill()
        
        // Tombstone top (arched/triangular) - scaled from SVG
        let topPath = NSBezierPath()
        topPath.move(to: NSPoint(x: 5, y: 10))
        // Create a curved top (simplified arch)
        topPath.curve(to: NSPoint(x: 8, y: 2.5), controlPoint1: NSPoint(x: 6, y: 6), controlPoint2: NSPoint(x: 7, y: 4))
        topPath.line(to: NSPoint(x: 11, y: 10))
        topPath.close()
        topPath.fill()
        
        // Cross - use opposite color for contrast (or same color, depending on design)
        // For now, use the same color but could use opposite for better visibility
        let crossLine1 = NSBezierPath()
        crossLine1.lineWidth = 0.5
        crossLine1.move(to: NSPoint(x: 8, y: 6))
        crossLine1.line(to: NSPoint(x: 8, y: 8))
        crossLine1.stroke()
        
        let crossLine2 = NSBezierPath()
        crossLine2.lineWidth = 0.5
        crossLine2.move(to: NSPoint(x: 7, y: 7))
        crossLine2.line(to: NSPoint(x: 9, y: 7))
        crossLine2.stroke()
        
        image.unlockFocus()
        image.isTemplate = false // We're handling colors ourselves
        return image
    }
    
    /// Create tree icon programmatically (based on SVG design)
    private func createTreeIcon() -> NSImage {
        // Get color from status item button to match other menu bar items
        let strokeColor: NSColor
        if let button = statusItem?.button, let tintColor = button.contentTintColor {
            strokeColor = tintColor
        } else {
            // Fallback: use white (typical menu bar color)
            strokeColor = NSColor.white
        }
        
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        strokeColor.setStroke()
        // Use thicker stroke width to match visual weight (2 points for 16x16 icon)
        let strokeWidth: CGFloat = 2.0
        
        // Tree foliage (main shape) - use stroke like the SVG
        // Parse the SVG path data or create a simplified version
        // For now, create a simplified tree with stroke
        let treePath = NSBezierPath()
        // Simplified tree shape with stroke
        treePath.move(to: NSPoint(x: 8, y: 2))
        treePath.curve(to: NSPoint(x: 3, y: 8), controlPoint1: NSPoint(x: 5, y: 4), controlPoint2: NSPoint(x: 3, y: 6))
        treePath.curve(to: NSPoint(x: 13, y: 8), controlPoint1: NSPoint(x: 3, y: 8), controlPoint2: NSPoint(x: 8, y: 8))
        treePath.curve(to: NSPoint(x: 8, y: 2), controlPoint1: NSPoint(x: 13, y: 8), controlPoint2: NSPoint(x: 11, y: 4))
        treePath.close()
        treePath.lineWidth = strokeWidth
        treePath.stroke()
        
        // Tree trunk
        let trunkPath = NSBezierPath()
        trunkPath.move(to: NSPoint(x: 7, y: 8))
        trunkPath.line(to: NSPoint(x: 7, y: 14))
        trunkPath.line(to: NSPoint(x: 9, y: 14))
        trunkPath.line(to: NSPoint(x: 9, y: 8))
        trunkPath.close()
        trunkPath.lineWidth = strokeWidth
        trunkPath.stroke()
        
        image.unlockFocus()
        image.isTemplate = false // We're handling colors ourselves
        return image
    }
    
    /// Get condensed font for menu bar text
    private func getCondensedMenuBarFont() -> NSFont {
        let baseFont = NSFont.menuBarFont(ofSize: 0)
        // Make font a bit smaller
        let fontSize = max(baseFont.pointSize - 1, 10)
        
        // Try to get condensed variant using font descriptor
        let descriptor = baseFont.fontDescriptor
        let condensedTraits = NSFontDescriptor.SymbolicTraits([.condensed])
        let condensedDescriptor = descriptor.withSymbolicTraits(condensedTraits)
        if let condensedFont = NSFont(descriptor: condensedDescriptor, size: fontSize) {
            return condensedFont
        }
        
        // Try using NSFontManager to get condensed variant
        let fontManager = NSFontManager.shared
        let condensedFont = fontManager.convert(baseFont, toHaveTrait: .condensedFontMask)
        // Check if the conversion actually changed the font
        if condensedFont.fontName != baseFont.fontName {
            return condensedFont
        }
        
        // Fall back to regular menu bar font
        return baseFont
    }
    
    /// Create a combined image with icon and text for menu bar display
    private func createIconTextImage(icon: NSImage, text: String) -> NSImage {
        // Use condensed font for numbers
        let font = getCondensedMenuBarFont()
        
        // Get text color from button to match other menu bar items
        let textColor: NSColor
        if let button = statusItem?.button, let tintColor = button.contentTintColor {
            textColor = tintColor
        } else {
            // Fallback: use white (typical menu bar color)
            textColor = NSColor.white
        }
        
        // Create attributed string for text (no leading space)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        
        // Icon size - make it a bit smaller
        let iconSize: CGFloat = 13
        let spacing: CGFloat = 2 // Reduced spacing to bring icon closer to text
        let totalWidth = iconSize + spacing + textSize.width
        let totalHeight = max(iconSize, textSize.height)
        
        // Create image
        let image = NSImage(size: NSSize(width: totalWidth, height: totalHeight))
        image.lockFocus()
        
        // Draw icon
        let iconRect = NSRect(x: 0, y: (totalHeight - iconSize) / 2, width: iconSize, height: iconSize)
        icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        // Draw text
        let textRect = NSRect(x: iconSize + spacing, y: (totalHeight - textSize.height) / 2, width: textSize.width, height: textSize.height)
        attributedText.draw(in: textRect)
        
        image.unlockFocus()
        return image
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

// MARK: - NSColor Extension
extension NSColor {
    var hexString: String {
        guard let rgbColor = self.usingColorSpace(.deviceRGB) else {
            return "#000000"
        }
        let r = Int(round(rgbColor.redComponent * 255))
        let g = Int(round(rgbColor.greenComponent * 255))
        let b = Int(round(rgbColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

