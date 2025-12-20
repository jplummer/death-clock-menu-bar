import Foundation

struct UserProfile: Codable {
    var dateOfBirth: Date
    var sex: Sex
    var location: Location
    
    enum Sex: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
    
    struct Location: Codable {
        var country: String
        var region: String? // State, province, etc.
    }
}

extension UserProfile {
    /// Default profile for display when user hasn't completed setup
    static var `default`: UserProfile {
        UserProfile(
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
            sex: .male,
            location: Location(country: "United States", region: nil)
        )
    }
}

struct LifeExpectancyData: Codable {
    let baseLifeExpectancy: Double // In years
    let country: String
    let sex: UserProfile.Sex
    let source: String
    let lastUpdated: Date
}

struct AppSettings: Codable {
    var userProfile: UserProfile?
    var showNotifications: Bool = false
    var updateFrequency: UpdateFrequency = .daily
    var displayFormat: DisplayFormat = .yearsAndDays
    var mementoMode: MementoMode = .mementoMori
    var startAtLogin: Bool = false
    
    enum UpdateFrequency: String, Codable, CaseIterable {
        case hourly = "Hourly"
        case daily = "Daily"
        case weekly = "Weekly"
    }
    
    enum DisplayFormat: String, Codable, CaseIterable {
        case yearsAndDays = "Years and Days"
        case daysOnly = "Days Only"
        case percentage = "Percentage"
        case progressBar = "Progress Bar"
    }
    
    enum MementoMode: String, Codable, CaseIterable {
        case mementoMori = "Memento Mori"
        case mementoVivere = "Memento Vivere"
    }
}

