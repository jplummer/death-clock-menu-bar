import XCTest
@testable import DeathClock

@MainActor
final class SettingsViewModelDateValidationTests: XCTestCase {
    var viewModel: SettingsViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = SettingsViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Future Date Tests
    
    func testNormalizeDate_FutureDate_MovesToCurrentYear() {
        let calendar = Calendar.current
        let now = Date()
        
        // Create a date in the future (same month/day, next year)
        if let futureDate = calendar.date(byAdding: .year, value: 1, to: now) {
            let normalized = viewModel.normalizeDate(futureDate)
            
            // Should be same month/day but in current year
            let futureComponents = calendar.dateComponents([.month, .day], from: futureDate)
            let normalizedComponents = calendar.dateComponents([.month, .day, .year], from: normalized)
            let nowComponents = calendar.dateComponents([.year], from: now)
            
            XCTAssertEqual(normalizedComponents.month, futureComponents.month)
            XCTAssertEqual(normalizedComponents.day, futureComponents.day)
            XCTAssertEqual(normalizedComponents.year, nowComponents.year)
            XCTAssertLessThanOrEqual(normalized, now, "Normalized date should not be in the future")
        }
    }
    
    func testNormalizeDate_FutureDateAtEndOfYear_MovesToYesterday() {
        let calendar = Calendar.current
        let now = Date()
        
        // Create Dec 31 in future year
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.year = (components.year ?? 0) + 1
        components.month = 12
        components.day = 31
        
        if let futureDate = calendar.date(from: components) {
            let normalized = viewModel.normalizeDate(futureDate)
            
            // Should be yesterday (since Dec 31 this year is still in future)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            let normalizedDay = calendar.dateComponents([.year, .month, .day], from: normalized)
            let yesterdayDay = calendar.dateComponents([.year, .month, .day], from: yesterday)
            
            XCTAssertEqual(normalizedDay.year, yesterdayDay.year)
            XCTAssertEqual(normalizedDay.month, yesterdayDay.month)
            XCTAssertEqual(normalizedDay.day, yesterdayDay.day)
        }
    }
    
    // MARK: - Past Date Tests
    
    func testNormalizeDate_DateTooFarInPast_MovesToMinValidYear() {
        let calendar = Calendar.current
        let minValidDate = Constants.DateValidation.minValidDate
        
        // Create a date from 1800
        var components = DateComponents()
        components.year = 1800
        components.month = 6
        components.day = 15
        
        if let oldDate = calendar.date(from: components) {
            let normalized = viewModel.normalizeDate(oldDate)
            
            // Normalized date should be >= minValidDate
            // It might preserve month/day if that date is >= minValidDate,
            // or it might be minValidDate itself if the preserved date would be too early
            let normalizedComponents = calendar.dateComponents([.year, .month, .day], from: normalized)
            
            // Check that normalized date is >= minValidDate (ignoring time)
            let normalizedDateOnly = calendar.dateComponents([.year, .month, .day], from: normalized)
            let minValidDateOnlyComponents = calendar.dateComponents([.year, .month, .day], from: minValidDate)
            if let normalizedDate = calendar.date(from: normalizedDateOnly),
               let minValidDateOnly = calendar.date(from: minValidDateOnlyComponents) {
                XCTAssertGreaterThanOrEqual(normalizedDate, minValidDateOnly, "Normalized date should not be before minimum valid date")
            }
            
            // If the preserved month/day in the min year would be valid, it should be preserved
            let oldComponents = calendar.dateComponents([.month, .day], from: oldDate)
            var testComponents = calendar.dateComponents([.year], from: minValidDate)
            testComponents.month = oldComponents.month
            testComponents.day = oldComponents.day
            if let testDate = calendar.date(from: testComponents),
               testDate >= minValidDate {
                // If preserving month/day would be valid, it should be preserved
                XCTAssertEqual(normalizedComponents.month, oldComponents.month)
                XCTAssertEqual(normalizedComponents.day, oldComponents.day)
            }
            // Otherwise, it should be minValidDate or later
        }
    }
    
    // MARK: - Valid Date Tests
    
    func testNormalizeDate_ValidDate_Unchanged() {
        let calendar = Calendar.current
        let now = Date()
        
        // Create a valid date (30 years ago)
        if let validDate = calendar.date(byAdding: .year, value: -30, to: now) {
            let normalized = viewModel.normalizeDate(validDate)
            
            // Should be exactly the same
            XCTAssertEqual(normalized, validDate, "Valid dates should remain unchanged")
        }
    }
    
    func testNormalizeDate_DateAtMinBoundary_Unchanged() {
        let calendar = Calendar.current
        // Capture minValidDate once to avoid recalculation differences
        let minValidDate = Constants.DateValidation.minValidDate
        let minValidDateComponents = calendar.dateComponents([.year, .month, .day], from: minValidDate)
        
        let normalized = viewModel.normalizeDate(minValidDate)
        
        // Since minValidDate is already valid (not < minValidDate), it should be returned unchanged
        // Compare dates ignoring time components since time might differ slightly
        let normalizedComponents = calendar.dateComponents([.year, .month, .day], from: normalized)
        
        // The normalized date should be >= minValidDate (should be equal or same day since input is already valid)
        XCTAssertGreaterThanOrEqual(normalized, minValidDate, "Normalized date should be >= minValidDate")
        
        // And the date components should match (same day)
        XCTAssertEqual(normalizedComponents.year, minValidDateComponents.year, "Year should match")
        XCTAssertEqual(normalizedComponents.month, minValidDateComponents.month, "Month should match")
        XCTAssertEqual(normalizedComponents.day, minValidDateComponents.day, "Day should match - date at minimum boundary should remain unchanged")
    }
    
    func testNormalizeDate_DateAtMaxBoundary_Unchanged() {
        let now = Date()
        let normalized = viewModel.normalizeDate(now)
        
        XCTAssertEqual(normalized, now, "Date at maximum boundary (today) should remain unchanged")
    }
    
    // MARK: - Edge Cases
    
    func testNormalizeDate_LeapDay_HandlesGracefully() {
        let calendar = Calendar.current
        
        // Feb 29, 2020 (valid leap year)
        var leapComponents = DateComponents()
        leapComponents.year = 2020
        leapComponents.month = 2
        leapComponents.day = 29
        
        if let leapDate = calendar.date(from: leapComponents) {
            let normalized = viewModel.normalizeDate(leapDate)
            
            // Should not crash and should produce a valid date
            XCTAssertNotNil(normalized)
            let normalizedComponents = calendar.dateComponents([.month, .day], from: normalized)
            // Should be Feb 28 or 29 depending on the target year
            XCTAssertEqual(normalizedComponents.month, 2)
            XCTAssertLessThanOrEqual(normalizedComponents.day ?? 0, 29)
        }
    }
}

