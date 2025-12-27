import Foundation

/// Calculates life expectancy and days remaining based on user demographics.
///
/// **Data Source:**
/// - Loads from Resources/life-expectancy-data.json
/// - Falls back to hardcoded values if JSON loading fails
/// - Values are approximate estimates based on WHO Global Health Observatory data
///
/// **Recommended Data Sources for Production:**
/// - WHO Global Health Observatory: https://www.who.int/data/gho
/// - CDC Life Tables (US): https://www.cdc.gov/nchs/products/life_tables.htm
/// - World Bank: https://data.worldbank.org/indicator/SP.DYN.LE00.IN
/// - UN Population Division: World Population Prospects
///
/// **Future Enhancements:**
/// - Integrate API for real-time updates
/// - Use actuarial life tables for age-adjusted calculations
class LifeExpectancyCalculator {
    static let shared = LifeExpectancyCalculator()
    
    private let dataLoader = LifeExpectancyDataLoader.shared
    
    private init() {}
    
    /// Calculate days remaining until life expectancy
    func calculateDaysRemaining(profile: UserProfile) -> Int? {
        // getLifeExpectancy returns remaining life expectancy at current age
        guard let remainingLifeExpectancyYears = getLifeExpectancy(for: profile) else {
            return nil
        }
        
        // Convert remaining life expectancy from years to days
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
    
    /// Get base life expectancy in years based on demographics
    private func getLifeExpectancy(for profile: UserProfile) -> Double? {
        let baseExpectancy = getBaseLifeExpectancy(profile: profile)
        
        // Adjust for current age (life expectancy increases as you age)
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: profile.dateOfBirth, to: Date()).year ?? 0
        
        return adjustForAge(baseExpectancy, currentAge: age)
    }
    
    /// Get base life expectancy at birth (before age adjustment)
    private func getBaseLifeExpectancy(profile: UserProfile) -> Double {
        switch profile.sex {
        case .female:
            return getFemaleLifeExpectancy(country: profile.location.country)
        case .male:
            return getMaleLifeExpectancy(country: profile.location.country)
        case .other:
            let male = getMaleLifeExpectancy(country: profile.location.country)
            let female = getFemaleLifeExpectancy(country: profile.location.country)
            return (male + female) / 2.0
        }
    }
    
    func getMaleLifeExpectancy(country: String) -> Double {
        return dataLoader.getMaleLifeExpectancy(country: country)
    }
    
    func getFemaleLifeExpectancy(country: String) -> Double {
        return dataLoader.getFemaleLifeExpectancy(country: country)
    }
    
    private func adjustForAge(_ baseExpectancy: Double, currentAge: Int) -> Double {
        // Calculate remaining life expectancy at current age
        // This is a simplified model - real actuarial tables are more complex
        
        if currentAge <= 0 {
            return baseExpectancy
        }
        
        // If age is already past base expectancy, use a conservative estimate
        if Double(currentAge) >= baseExpectancy {
            // For people who've exceeded base expectancy, estimate 5-10 more years
            // This is a rough approximation - real actuarial data would be better
            return max(5.0, 10.0 - (Double(currentAge) - baseExpectancy) * 0.1)
        }
        
        // Simple model: remaining expectancy decreases more slowly than linearly
        // As you survive longer, your remaining expectancy increases slightly
        let yearsPast = Double(currentAge)
        let remaining = baseExpectancy - yearsPast
        
        // Add bonus for surviving (simplified actuarial adjustment)
        // Each decade survived adds a small bonus to remaining expectancy
        let decadeBonus = Double(currentAge / 10) * 0.3
        
        // Ensure we always return a reasonable positive value
        return max(remaining + decadeBonus, 1.0)
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

