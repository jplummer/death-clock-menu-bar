import XCTest
@testable import DeathClock

/// Exercises `LifeExpectancyDataLoader` against the real bundled JSON (DeathClock.app Resources).
/// Run with **Product → Test** (⌘U); tests are hosted in DeathClock so the resource bundle resolves.
final class LifeExpectancyDataLoaderTests: XCTestCase {

  private var loader: LifeExpectancyDataLoader { LifeExpectancyDataLoader.shared }

  func testBundledJsonLoadsWithStateTables() {
    XCTAssertGreaterThan(loader.usStatePickerOptions.count, 40, "v2 bundle should include most US states + DC")
    XCTAssertTrue(loader.hasSelectableRegions(forCountry: "United States"))
    XCTAssertFalse(loader.hasSelectableRegions(forCountry: "Japan"))
    XCTAssertFalse(loader.hasSelectableRegions(forCountry: "Canada"))
  }

  func testUSNationalRemainingLifeIsPositive() {
    let y = loader.remainingLifeExpectancyYears(
      country: "United States",
      region: nil,
      sex: .male,
      completedAgeYears: 30
    )
    XCTAssertGreaterThan(y, 5)
    XCTAssertLessThan(y, 80)
  }

  func testUSStateCanDifferFromNational() {
    let national = loader.remainingLifeExpectancyYears(
      country: "United States",
      region: nil,
      sex: .male,
      completedAgeYears: 40
    )
    let hi = loader.remainingLifeExpectancyYears(
      country: "United States",
      region: "HI",
      sex: .male,
      completedAgeYears: 40
    )
    XCTAssertGreaterThan(abs(national - hi), 0.05)
  }

  func testInternationalCountryUsesWorldBankE0Shape() {
    XCTAssertTrue(
      loader.availableCountries.contains("Japan"),
      "Sanity check: World Bank list should include Japan"
    )
    let y = loader.remainingLifeExpectancyYears(
      country: "Japan",
      region: nil,
      sex: .female,
      completedAgeYears: 55
    )
    XCTAssertGreaterThan(y, 5)
    XCTAssertLessThan(y, 50)
  }

  func testHighAgeUsesEndOfTableWithoutCrashing() {
    let y = loader.remainingLifeExpectancyYears(
      country: "United States",
      region: nil,
      sex: .female,
      completedAgeYears: 100
    )
    XCTAssertGreaterThan(y, 0)
  }

  func testLifeExpectancyAtBirthMatchesSex() {
    let m = loader.lifeExpectancyAtBirth(country: "United States", region: nil, sex: .male)
    let f = loader.lifeExpectancyAtBirth(country: "United States", region: nil, sex: .female)
    XCTAssertGreaterThan(f, m)
  }
}
