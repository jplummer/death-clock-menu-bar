import Foundation
import AppKit

/// Represents the content to display in the menu bar
struct DisplayContent {
    let text: String?
    let image: NSImage?
    
    static var empty: DisplayContent {
        DisplayContent(text: nil, image: nil)
    }
    
    static func text(_ text: String) -> DisplayContent {
        DisplayContent(text: text, image: nil)
    }
    
    static func image(_ image: NSImage) -> DisplayContent {
        DisplayContent(text: nil, image: image)
    }
}

/// Handles formatting of days remaining for display in various formats
class DisplayFormatter {
    private let calculator = LifeExpectancyCalculator.shared
    
    /// Format display content based on profile, days remaining, format, and mode
    func format(profile: UserProfile, daysRemaining: Int, format: AppSettings.DisplayFormat, mode: AppSettings.MementoMode, color: NSColor = NSColor.white) -> DisplayContent {
        switch format {
        case .progressBar:
            return formatProgressBar(profile: profile, daysRemaining: daysRemaining, mode: mode, color: color)
        case .percentage:
            return formatPercentage(profile: profile, daysRemaining: daysRemaining, mode: mode)
        case .daysOnly, .yearsAndDays:
            return formatText(daysRemaining: daysRemaining, format: format, mode: mode, profile: profile)
        }
    }
    
    /// Format as text (Days Only or Years and Days)
    private func formatText(daysRemaining: Int, format: AppSettings.DisplayFormat, mode: AppSettings.MementoMode, profile: UserProfile) -> DisplayContent {
        let text: String
        switch mode {
        case .mementoMori:
            // Countdown: days remaining
            text = calculator.formatDaysRemaining(daysRemaining, format: format)
        case .mementoVivere:
            // Count-up: days lived
            let daysLived = calculator.calculateDaysLived(profile: profile)
            text = calculator.formatDaysLived(daysLived, format: format)
        }
        return .text(text)
    }
    
    /// Format as percentage
    private func formatPercentage(profile: UserProfile, daysRemaining: Int, mode: AppSettings.MementoMode) -> DisplayContent {
        guard let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) else {
            return .text("\(daysRemaining)")
        }
        let text: String
        switch mode {
        case .mementoMori:
            // Percentage remaining
            text = calculator.formatDaysRemaining(daysRemaining, format: .percentage, totalDays: totalDays)
        case .mementoVivere:
            // Percentage lived
            let daysLived = calculator.calculateDaysLived(profile: profile)
            text = calculator.formatDaysLived(daysLived, format: .percentage, totalDays: totalDays)
        }
        return .text(text)
    }
    
    /// Format as progress bar image
    private func formatProgressBar(profile: UserProfile, daysRemaining: Int, mode: AppSettings.MementoMode, color: NSColor) -> DisplayContent {
        guard let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) else {
            return .text("Error")
        }
        let daysLived = calculator.calculateDaysLived(profile: profile)
        // Same bar for both modes (solid fill through life lived, dim remainder); only the label differs
        let fillPercentage = Double(daysLived) / Double(totalDays) * 100.0
        let textPercentage: Double
        switch mode {
        case .mementoMori:
            textPercentage = calculator.calculatePercentage(daysRemaining: daysRemaining, totalDays: totalDays)
        case .mementoVivere:
            textPercentage = fillPercentage
        }
        let image = ProgressBarRenderer.render(fillPercentage: fillPercentage, textPercentage: textPercentage, color: color)
        return .image(image)
    }
    
    /// Format preview text for settings (includes progress bar as text representation)
    func formatPreview(profile: UserProfile, daysRemaining: Int, format: AppSettings.DisplayFormat, mode: AppSettings.MementoMode) -> String {
        switch format {
        case .daysOnly, .yearsAndDays:
            switch mode {
            case .mementoMori:
                return calculator.formatDaysRemaining(daysRemaining, format: format)
            case .mementoVivere:
                let daysLived = calculator.calculateDaysLived(profile: profile)
                return calculator.formatDaysLived(daysLived, format: format)
            }
        case .percentage:
            if let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) {
                switch mode {
                case .mementoMori:
                    return calculator.formatDaysRemaining(daysRemaining, format: format, totalDays: totalDays)
                case .mementoVivere:
                    let daysLived = calculator.calculateDaysLived(profile: profile)
                    return calculator.formatDaysLived(daysLived, format: format, totalDays: totalDays)
                }
            }
            return format.rawValue
        case .progressBar:
            // Text preview matches menu bar: bar fill is always lived %; label is remaining (mori) or lived (vivere)
            if let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) {
                let daysLived = calculator.calculateDaysLived(profile: profile)
                let barPercentage = Double(daysLived) / Double(totalDays) * 100.0
                let labelPercentage: Double
                switch mode {
                case .mementoMori:
                    labelPercentage = calculator.calculatePercentage(daysRemaining: daysRemaining, totalDays: totalDays)
                case .mementoVivere:
                    labelPercentage = barPercentage
                }
                let filledBlocks = Int((barPercentage / 100.0) * 8.0)
                let emptyBlocks = 8 - filledBlocks
                let filled = String(repeating: "▓", count: filledBlocks)
                let empty = String(repeating: "░", count: emptyBlocks)
                return String(format: "%@%@ %.0f%%", filled, empty, labelPercentage)
            }
            return format.rawValue
        }
    }
}

