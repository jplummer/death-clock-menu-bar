import Foundation

/// Calculates life expectancy and days remaining based on user demographics.
///
/// **Data:** Bundled `life-expectancy-data.json` (see `scripts/build_life_expectancy_bundle.py`).
/// Schema v2 uses CDC LEWK4 state period life tables plus World Bank e₀ for other countries.
class LifeExpectancyCalculator {
    static let shared = LifeExpectancyCalculator()
    
    private let dataLoader = LifeExpectancyDataLoader.shared
    
    private init() {}
    
    /// Calculate days remaining until life expectancy
    func calculateDaysRemaining(profile: UserProfile) -> Int? {
        // getLifeExpectancy returns remaining life expectancy at current age
        let remainingLifeExpectancyYears = getLifeExpectancy(for: profile)
        let remainingDays = Int(remainingLifeExpectancyYears * Constants.LifeExpectancy.daysPerYear)
        
        return max(0, remainingDays)
    }
    
    /// Calculate days lived since birth (for memento vivere mode)
    func calculateDaysLived(profile: UserProfile) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let daysLived = calendar.dateComponents([.day], from: profile.dateOfBirth, to: now).day ?? 0
        return max(0, daysLived)
    }
    
    /// Calculate total days from birth to life expectancy (for progress bar)
    func calculateTotalDaysFromBirth(profile: UserProfile) -> Int? {
        let baseExpectancy = getBaseLifeExpectancy(profile: profile)
        return Int(baseExpectancy * Constants.LifeExpectancy.daysPerYear)
    }
    
    private func getLifeExpectancy(for profile: UserProfile) -> Double {
        let calendar = Calendar.current
        let ageYears = max(0, calendar.dateComponents([.year], from: profile.dateOfBirth, to: Date()).year ?? 0)
        return dataLoader.remainingLifeExpectancyYears(
            country: profile.location.country,
            region: profile.location.region,
            sex: profile.sex,
            completedAgeYears: ageYears
        )
    }
    
    private func getBaseLifeExpectancy(profile: UserProfile) -> Double {
        dataLoader.lifeExpectancyAtBirth(
            country: profile.location.country,
            region: profile.location.region,
            sex: profile.sex
        )
    }
    
    func getMaleLifeExpectancy(country: String) -> Double {
        return dataLoader.getMaleLifeExpectancy(country: country)
    }
    
    func getFemaleLifeExpectancy(country: String) -> Double {
        return dataLoader.getFemaleLifeExpectancy(country: country)
    }
    
    /// Format days remaining as a display string
    func formatDaysRemaining(_ days: Int, format: AppSettings.DisplayFormat = .yearsAndDays, totalDays: Int? = nil) -> String {
        switch format {
        case .daysOnly:
            return "\(days)"
        case .yearsAndDays:
            if days >= 1000 {
                let years = days / 365
                let remainingDays = days % 365
                return "\(years)y \(remainingDays)d"
            } else {
                return "\(days)"
            }
        case .percentage:
            guard let totalDays = totalDays, totalDays > 0 else {
                return "\(days)"
            }
            // Show percentage remaining (not elapsed)
            let percentage = Double(days) / Double(totalDays) * 100.0
            return String(format: "%.0f%%", percentage)
        case .progressBar:
            // Progress bar uses image, not text
            return ""
        }
    }
    
    /// Format days lived as a display string (for memento vivere mode)
    func formatDaysLived(_ days: Int, format: AppSettings.DisplayFormat = .yearsAndDays, totalDays: Int? = nil) -> String {
        switch format {
        case .daysOnly:
            return "\(days)"
        case .yearsAndDays:
            if days >= 1000 {
                let years = days / 365
                let remainingDays = days % 365
                return "\(years)y \(remainingDays)d"
            } else {
                return "\(days)"
            }
        case .percentage:
            guard let totalDays = totalDays, totalDays > 0 else {
                return "\(days)"
            }
            // Show percentage lived
            let percentage = Double(days) / Double(totalDays) * 100.0
            return String(format: "%.0f%%", percentage)
        case .progressBar:
            // Progress bar uses image, not text
            return ""
        }
    }
    
    /// Calculate percentage remaining for progress bar
    func calculatePercentage(daysRemaining: Int, totalDays: Int) -> Double {
        guard totalDays > 0 else { return 0.0 }
        // Return percentage remaining (not elapsed)
        return Double(daysRemaining) / Double(totalDays) * 100.0
    }
    
    /// Calculate percentage elapsed (for progress bar fill)
    func calculateElapsedPercentage(daysRemaining: Int, totalDays: Int) -> Double {
        guard totalDays > 0 else { return 0.0 }
        // Return percentage elapsed (for visual fill)
        let daysElapsed = totalDays - daysRemaining
        return Double(daysElapsed) / Double(totalDays) * 100.0
    }
}

