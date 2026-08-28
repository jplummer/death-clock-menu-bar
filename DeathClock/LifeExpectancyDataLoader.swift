import Foundation

/// Loads life expectancy data from bundled JSON (schema v2 preferred; v1 legacy supported).
final class LifeExpectancyDataLoader {
  static let shared = LifeExpectancyDataLoader()

  /// Bundle that contains `life-expectancy-data.json` (app target). Using this instead of `Bundle.main` lets unit tests load the same resource when hosted in DeathClock.app.
  private static let resourcesBundle = Bundle(for: LifeExpectancyDataLoader.self)

  private struct SexCurves: Codable {
    let male: [Double]
    let female: [Double]
    let total: [Double]
  }

  private struct CountryE0Row: Codable {
    let maleE0: Double
    let femaleE0: Double
  }

  private struct BundleV2: Codable {
    let schemaVersion: Int
    let usNationalAverage: SexCurves
    let usRegionLabels: [String: String]?
    let usRegions: [String: SexCurves]
    let countries: [String: CountryE0Row]
  }

  private var v2: BundleV2?
  private var legacyMale: [String: Double] = [:]
  private var legacyFemale: [String: Double] = [:]
  private var defaultMale: Double = 72.0
  private var defaultFemale: Double = 77.0

  private init() {
    loadData()
  }

  private func loadData() {
    guard let url = Self.resourcesBundle.url(forResource: "life-expectancy-data", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
      loadFallbackData()
      return
    }

    if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let ver = obj["schemaVersion"] as? Int, ver >= 2,
       let parsed = try? JSONDecoder().decode(BundleV2.self, from: data) {
      v2 = parsed
      return
    }

    loadLegacyV1(data: data)
  }

  private func loadLegacyV1(data: Data) {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let dataDict = json["data"] as? [String: [String: Double]] else {
      loadFallbackData()
      return
    }
    if let maleDict = dataDict["male"] {
      legacyMale = maleDict
      defaultMale = maleDict.values.reduce(0, +) / Double(maleDict.count)
    }
    if let femaleDict = dataDict["female"] {
      legacyFemale = femaleDict
      defaultFemale = femaleDict.values.reduce(0, +) / Double(femaleDict.count)
    }
  }

  private func loadFallbackData() {
    legacyMale = [
      "United States": 76.1, "United Kingdom": 79.0, "Canada": 80.0, "Australia": 81.0,
      "Germany": 78.5, "France": 79.5, "Japan": 81.5, "China": 75.0, "India": 69.0,
      "Brazil": 73.0, "Mexico": 72.0
    ]
    legacyFemale = [
      "United States": 81.1, "United Kingdom": 82.9, "Canada": 84.0, "Australia": 85.0,
      "Germany": 83.0, "France": 85.5, "Japan": 87.5, "China": 78.0, "India": 71.0,
      "Brazil": 79.0, "Mexico": 78.0
    ]
    defaultMale = legacyMale.values.reduce(0, +) / Double(legacyMale.count)
    defaultFemale = legacyFemale.values.reduce(0, +) / Double(legacyFemale.count)
  }

  /// Whether settings should offer a region control (today: US state picker when v2 state tables exist).
  func hasSelectableRegions(forCountry country: String) -> Bool {
    let c = country.trimmingCharacters(in: .whitespacesAndNewlines)
    return c == "United States" && !usStatePickerOptions.isEmpty
  }

  /// Sorted country names for the settings picker (includes United States when using v2).
  var availableCountries: [String] {
    if let v2 {
      var names = Array(v2.countries.keys)
      names.append("United States")
      return names.sorted()
    }
    let all = Set(legacyMale.keys).union(Set(legacyFemale.keys))
    return Array(all).sorted()
  }

  /// USPS code and display name for US region picker; sorted by name.
  var usStatePickerOptions: [(code: String, name: String)] {
    guard let v2 else { return [] }
    let labels = v2.usRegionLabels ?? [:]
    return v2.usRegions.keys.compactMap { code in
      let name = labels[code] ?? code
      return (code, name)
    }
    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  func getMaleLifeExpectancy(country: String) -> Double {
    if v2 != nil {
      return lifeExpectancyAtBirth(country: country, region: nil, sex: .male)
    }
    return legacyMale[country] ?? defaultMale
  }

  func getFemaleLifeExpectancy(country: String) -> Double {
    if v2 != nil {
      return lifeExpectancyAtBirth(country: country, region: nil, sex: .female)
    }
    return legacyFemale[country] ?? defaultFemale
  }

  /// Life expectancy at birth (e₀) in years for progress bar denominators.
  func lifeExpectancyAtBirth(country: String, region: String?, sex: UserProfile.Sex) -> Double {
    let curve = expectancyCurve(country: country, region: region, sex: sex)
    return curve.first ?? fallbackE0(sex: sex)
  }

  /// Remaining life expectancy in years at completed age (period table interpretation).
  func remainingLifeExpectancyYears(
    country: String,
    region: String?,
    sex: UserProfile.Sex,
    completedAgeYears: Int
  ) -> Double {
    let curve = expectancyCurve(country: country, region: region, sex: sex)
    guard !curve.isEmpty else { return max(1, fallbackE0(sex: sex)) }
    let age = max(0, completedAgeYears)
    let idx = min(age, curve.count - 1)
    return max(curve[idx], 0.01)
  }

  private func fallbackE0(sex: UserProfile.Sex) -> Double {
    switch sex {
    case .male: return defaultMale
    case .female: return defaultFemale
    case .other: return (defaultMale + defaultFemale) / 2
    }
  }

  private func expectancyCurve(country: String, region: String?, sex: UserProfile.Sex) -> [Double] {
    let c = country.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let v2 else {
      let e0: Double
      switch sex {
      case .male: e0 = legacyMale[c] ?? legacyMale[country] ?? defaultMale
      case .female: e0 = legacyFemale[c] ?? legacyFemale[country] ?? defaultFemale
      case .other:
        let m = legacyMale[c] ?? legacyMale[country] ?? defaultMale
        let f = legacyFemale[c] ?? legacyFemale[country] ?? defaultFemale
        e0 = (m + f) / 2
      }
      return legacySyntheticCurve(e0: e0)
    }

    if c == "United States" {
      let r = region?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if !r.isEmpty, let regional = v2.usRegions[r] {
        return curveForSex(regional, sex: sex)
      }
      return curveForSex(v2.usNationalAverage, sex: sex)
    }

    guard let row = v2.countries[c] ?? v2.countries[country] else {
      return curveForSex(v2.usNationalAverage, sex: sex)
    }
    let e0: Double
    switch sex {
    case .male: e0 = row.maleE0
    case .female: e0 = row.femaleE0
    case .other: e0 = (row.maleE0 + row.femaleE0) / 2
    }
    let ref = curveForSex(v2.usNationalAverage, sex: sex)
    return scaleCurveToE0(ref, targetE0: e0)
  }

  private func curveForSex(_ curves: SexCurves, sex: UserProfile.Sex) -> [Double] {
    switch sex {
    case .male: return curves.male
    case .female: return curves.female
    case .other: return curves.total
    }
  }

  /// Scale a reference e_x curve so e₀ matches World Bank while preserving age shape.
  private func scaleCurveToE0(_ reference: [Double], targetE0: Double) -> [Double] {
    guard let base = reference.first, base > 0.01 else { return reference }
    let factor = targetE0 / base
    return reference.map { max(0.01, $0 * factor) }
  }

  /// Remaining-years approximation when only legacy e₀ exists (no v2 bundle).
  private func legacySyntheticCurve(e0: Double) -> [Double] {
    (0...100).map { age in max(0.5, e0 - Double(age)) }
  }
}
