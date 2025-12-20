import Foundation

/// Loads life expectancy data from JSON file
class LifeExpectancyDataLoader {
    static let shared = LifeExpectancyDataLoader()
    
    private var maleData: [String: Double] = [:]
    private var femaleData: [String: Double] = [:]
    private var defaultMale: Double = 72.0
    private var defaultFemale: Double = 77.0
    
    private init() {
        loadData()
    }
    
    /// Load data from JSON file
    private func loadData() {
        guard let url = Bundle.main.url(forResource: "life-expectancy-data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: [String: Double]] else {
            // Fallback to hardcoded values if JSON loading fails
            loadFallbackData()
            return
        }
        
        // Load male data
        if let maleDict = dataDict["male"] {
            maleData = maleDict
            // Calculate average for default fallback
            defaultMale = maleDict.values.reduce(0, +) / Double(maleDict.count)
        }
        
        // Load female data
        if let femaleDict = dataDict["female"] {
            femaleData = femaleDict
            // Calculate average for default fallback
            defaultFemale = femaleDict.values.reduce(0, +) / Double(femaleDict.count)
        }
    }
    
    /// Fallback to hardcoded values if JSON loading fails
    private func loadFallbackData() {
        maleData = [
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
        
        femaleData = [
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
    }
    
    /// Get male life expectancy for a country
    func getMaleLifeExpectancy(country: String) -> Double {
        return maleData[country] ?? defaultMale
    }
    
    /// Get female life expectancy for a country
    func getFemaleLifeExpectancy(country: String) -> Double {
        return femaleData[country] ?? defaultFemale
    }
    
    /// Get list of available countries
    var availableCountries: [String] {
        let allCountries = Set(maleData.keys).union(Set(femaleData.keys))
        return Array(allCountries).sorted()
    }
}

