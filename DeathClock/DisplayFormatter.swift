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
    
    /// Format display content based on profile, days remaining, and format
    func format(profile: UserProfile, daysRemaining: Int, format: AppSettings.DisplayFormat) -> DisplayContent {
        switch format {
        case .progressBar:
            return formatProgressBar(profile: profile, daysRemaining: daysRemaining)
        case .percentage:
            return formatPercentage(profile: profile, daysRemaining: daysRemaining)
        case .daysOnly, .yearsAndDays:
            return formatText(daysRemaining: daysRemaining, format: format)
        }
    }
    
    /// Format as text (Days Only or Years and Days)
    private func formatText(daysRemaining: Int, format: AppSettings.DisplayFormat) -> DisplayContent {
        let text = calculator.formatDaysRemaining(daysRemaining, format: format)
        return .text(text)
    }
    
    /// Format as percentage
    private func formatPercentage(profile: UserProfile, daysRemaining: Int) -> DisplayContent {
        guard let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) else {
            return .text("\(daysRemaining)")
        }
        let text = calculator.formatDaysRemaining(daysRemaining, format: .percentage, totalDays: totalDays)
        return .text(text)
    }
    
    /// Format as progress bar image
    private func formatProgressBar(profile: UserProfile, daysRemaining: Int) -> DisplayContent {
        guard let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) else {
            return .text("Error")
        }
        
        let elapsedPercentage = calculator.calculateElapsedPercentage(daysRemaining: daysRemaining, totalDays: totalDays)
        let remainingPercentage = calculator.calculatePercentage(daysRemaining: daysRemaining, totalDays: totalDays)
        let image = ProgressBarRenderer.render(fillPercentage: elapsedPercentage, textPercentage: remainingPercentage)
        return .image(image)
    }
    
    /// Format preview text for settings (includes progress bar as text representation)
    func formatPreview(profile: UserProfile, daysRemaining: Int, format: AppSettings.DisplayFormat) -> String {
        switch format {
        case .daysOnly, .yearsAndDays:
            return calculator.formatDaysRemaining(daysRemaining, format: format)
        case .percentage:
            if let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) {
                return calculator.formatDaysRemaining(daysRemaining, format: format, totalDays: totalDays)
            }
            return format.rawValue
        case .progressBar:
            // For preview, show a text representation
            if let totalDays = calculator.calculateTotalDaysFromBirth(profile: profile) {
                let percentage = calculator.calculatePercentage(daysRemaining: daysRemaining, totalDays: totalDays)
                let filledBlocks = Int((percentage / 100.0) * 8.0)
                let emptyBlocks = 8 - filledBlocks
                let filled = String(repeating: "▓", count: filledBlocks)
                let empty = String(repeating: "░", count: emptyBlocks)
                return String(format: "%@%@ %.0f%%", filled, empty, percentage)
            }
            return format.rawValue
        }
    }
}

