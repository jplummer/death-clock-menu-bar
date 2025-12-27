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
    var showIcon: Bool = false
    var startAtLogin: Bool = false
    
    // Migration: Keep old properties for decoding, but don't encode them
    private var showTombstoneIcon: Bool?
    private var showTreeIcon: Bool?
    
    enum CodingKeys: String, CodingKey {
        case userProfile
        case showNotifications
        case updateFrequency
        case displayFormat
        case mementoMode
        case showIcon
        case startAtLogin
        case showTombstoneIcon // For migration
        case showTreeIcon // For migration
    }
    
    init() {
        // Default initializer
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userProfile = try container.decodeIfPresent(UserProfile.self, forKey: .userProfile)
        showNotifications = try container.decodeIfPresent(Bool.self, forKey: .showNotifications) ?? false
        updateFrequency = try container.decodeIfPresent(UpdateFrequency.self, forKey: .updateFrequency) ?? .daily
        displayFormat = try container.decodeIfPresent(DisplayFormat.self, forKey: .displayFormat) ?? .yearsAndDays
        mementoMode = try container.decodeIfPresent(MementoMode.self, forKey: .mementoMode) ?? .mementoMori
        startAtLogin = try container.decodeIfPresent(Bool.self, forKey: .startAtLogin) ?? false
        
        // Migration: If old settings exist, migrate to new setting
        let oldTombstone = try container.decodeIfPresent(Bool.self, forKey: .showTombstoneIcon) ?? false
        let oldTree = try container.decodeIfPresent(Bool.self, forKey: .showTreeIcon) ?? false
        if container.contains(.showIcon) {
            showIcon = try container.decode(Bool.self, forKey: .showIcon)
        } else {
            // Migrate from old settings
            showIcon = oldTombstone || oldTree
        }
        
        showTombstoneIcon = nil
        showTreeIcon = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userProfile, forKey: .userProfile)
        try container.encode(showNotifications, forKey: .showNotifications)
        try container.encode(updateFrequency, forKey: .updateFrequency)
        try container.encode(displayFormat, forKey: .displayFormat)
        try container.encode(mementoMode, forKey: .mementoMode)
        try container.encode(showIcon, forKey: .showIcon)
        try container.encode(startAtLogin, forKey: .startAtLogin)
        // Don't encode old properties
    }
    
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

