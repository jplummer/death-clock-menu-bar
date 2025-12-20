import Foundation

/// Calculates life expectancy and days remaining based on user demographics.
///
/// **Current Data Source:**
/// - Uses hardcoded approximate values (placeholder data)
/// - Values are rough estimates based on WHO Global Health Observatory data
/// - Not suitable for production use without real data sources
///
/// **Recommended Data Sources for Production:**
/// - WHO Global Health Observatory: https://www.who.int/data/gho
/// - CDC Life Tables (US): https://www.cdc.gov/nchs/products/life_tables.htm
/// - World Bank: https://data.worldbank.org/indicator/SP.DYN.LE00.IN
/// - UN Population Division: World Population Prospects
///
/// **Future Enhancements:**
/// - Load from JSON data file (see Resources/life-expectancy-data.json)
/// - Integrate API for real-time updates
/// - Use actuarial life tables for age-adjusted calculations
class LifeExpectancyCalculator {
    static let shared = LifeExpectancyCalculator()
    
    private init() {}
    
    /// Calculate days remaining until life expectancy
    func calculateDaysRemaining(profile: UserProfile) -> Int? {
        // getLifeExpectancy returns remaining life expectancy at current age
        guard let remainingLifeExpectancyYears = getLifeExpectancy(for: profile) else {
            return nil
        }
        
        // Convert remaining life expectancy from years to days
        // Use 365.25 to account for leap years
        let remainingDays = Int(remainingLifeExpectancyYears * 365.25)
        
        return max(0, remainingDays)
    }
    
    /// Calculate total days from birth to life expectancy (for progress bar)
    func calculateTotalDaysFromBirth(profile: UserProfile) -> Int? {
        // Get base life expectancy at birth (before age adjustment)
        let baseExpectancy: Double
        
        switch profile.sex {
        case .female:
            baseExpectancy = getFemaleLifeExpectancy(country: profile.location.country)
        case .male:
            baseExpectancy = getMaleLifeExpectancy(country: profile.location.country)
        case .other:
            let male = getMaleLifeExpectancy(country: profile.location.country)
            let female = getFemaleLifeExpectancy(country: profile.location.country)
            baseExpectancy = (male + female) / 2.0
        }
        
        // Convert to total days from birth
        return Int(baseExpectancy * 365.25)
    }
    
    /// Get base life expectancy in years based on demographics
    private func getLifeExpectancy(for profile: UserProfile) -> Double? {
        // Phase 1: Use static data tables
        // This is a simplified version - in production, you'd load from a comprehensive data file
        
        // Basic life expectancy by country and sex (simplified averages)
        // These are approximate values - should be replaced with actual data tables
        let baseExpectancy: Double
        
        switch profile.sex {
        case .female:
            baseExpectancy = getFemaleLifeExpectancy(country: profile.location.country)
        case .male:
            baseExpectancy = getMaleLifeExpectancy(country: profile.location.country)
        case .other:
            // Use average of male/female for other
            let male = getMaleLifeExpectancy(country: profile.location.country)
            let female = getFemaleLifeExpectancy(country: profile.location.country)
            baseExpectancy = (male + female) / 2.0
        }
        
        // Adjust for current age (life expectancy increases as you age)
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: profile.dateOfBirth, to: Date()).year ?? 0
        
        // Simple adjustment: remaining life expectancy increases slightly with age
        // This is a simplified model - real actuarial tables are more complex
        return adjustForAge(baseExpectancy, currentAge: age)
    }
    
    func getMaleLifeExpectancy(country: String) -> Double {
        // TODO: Replace with data loaded from Resources/life-expectancy-data.json
        // TODO: Integrate official WHO/CDC/UN data sources
        // Current values are approximate placeholders
        let data: [String: Double] = [
            "United States": 76.1,
            "United Kingdom": 79.0,
            "Canada": 80.0,
            "Australia": 81.0,
            "Germany": 78.5,
            "France": 79.5,
            "Japan": 81.5,
            "China": 75.0,
            "India": 69.0,
            "Brazil": 73.0,
            "Mexico": 72.0
        ]
        return data[country] ?? 72.0 // Default fallback
    }
    
    func getFemaleLifeExpectancy(country: String) -> Double {
        // TODO: Replace with data loaded from Resources/life-expectancy-data.json
        // TODO: Integrate official WHO/CDC/UN data sources
        // Current values are approximate placeholders
        let data: [String: Double] = [
            "United States": 81.1,
            "United Kingdom": 82.9,
            "Canada": 84.0,
            "Australia": 85.0,
            "Germany": 83.0,
            "France": 85.5,
            "Japan": 87.5,
            "China": 78.0,
            "India": 71.0,
            "Brazil": 79.0,
            "Mexico": 78.0
        ]
        return data[country] ?? 77.0 // Default fallback
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

