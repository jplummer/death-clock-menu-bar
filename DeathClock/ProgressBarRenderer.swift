import AppKit

/// Renders progress bar images for the menu bar
class ProgressBarRenderer {
    /// Create a progress bar image for the menu bar
    /// - Parameters:
    ///   - fillPercentage: Percentage of bar to fill (elapsed time, 0-100)
    ///   - textPercentage: Percentage to display as text (remaining time, 0-100)
    static func render(fillPercentage: Double, textPercentage: Double) -> NSImage {
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
}

