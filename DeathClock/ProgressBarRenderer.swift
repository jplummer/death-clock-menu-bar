import AppKit

/// Renders progress bar images for the menu bar
class ProgressBarRenderer {
    /// Create a progress bar image for the menu bar
    /// - Parameters:
    ///   - fillPercentage: Portion of the bar filled (days lived / total span, 0-100)
    ///   - textPercentage: Percentage shown next to the bar (remaining or lived, depending on mode)
    ///   - color: Color to use for the bar and text (defaults to white for menu bar)
    static func render(fillPercentage: Double, textPercentage: Double, color: NSColor = NSColor.white) -> NSImage {
        let width: CGFloat = 60
        let height: CGFloat = 14
        let barHeight: CGFloat = 6
        let percentageText = String(format: "%.0f%%", textPercentage)
        
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Draw background (transparent)
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: image.size).fill()
        
        let barRect = NSRect(x: 0, y: (height - barHeight) / 2, width: width - 30, height: barHeight)
        let fillWidth = (width - 30) * CGFloat(fillPercentage / 100.0)
        
        // Solid fill for lived portion, unfilled track at 50% opacity
        let unfilledColor = color.withAlphaComponent(0.5)
        unfilledColor.setFill()
        barRect.fill()
        
        let fillRect = NSRect(x: 0, y: (height - barHeight) / 2, width: fillWidth, height: barHeight)
        color.setFill()
        fillRect.fill()
        
        // Get condensed font for text (same as menu bar)
        let baseFont = NSFont.menuBarFont(ofSize: 0)
        let fontSize = max(baseFont.pointSize - 1, 10)
        let descriptor = baseFont.fontDescriptor
        let condensedTraits = NSFontDescriptor.SymbolicTraits([.condensed])
        let condensedDescriptor = descriptor.withSymbolicTraits(condensedTraits)
        let font: NSFont
        if let condensedFont = NSFont(descriptor: condensedDescriptor, size: fontSize) {
            font = condensedFont
        } else {
            let fontManager = NSFontManager.shared
            let condensedFont = fontManager.convert(baseFont, toHaveTrait: .condensedFontMask)
            font = condensedFont.fontName != baseFont.fontName ? condensedFont : baseFont
        }
        
        // Draw percentage text with condensed font and system color
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
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

