# Date Validation Testing Guide

## Quick Manual Testing

Test these cases in the app's DatePicker:

### Test Cases

1. **Future Date (Tomorrow)**
   - Select tomorrow's date
   - Expected: Should move to today or yesterday

2. **Future Date (Next Year)**
   - Select a date in next year (e.g., same month/day next year)
   - Expected: Should move to same month/day in current year

3. **Future Date (Far Future)**
   - Select Dec 31, 2030
   - Expected: Should move to yesterday (since Dec 31 this year is still in future)

4. **Past Date (Too Old)**
   - Select a date from 1800
   - Expected: Should move to same month/day, 150 years ago

5. **Valid Date**
   - Select a date from 1990
   - Expected: Should remain unchanged

6. **Edge Case: Leap Day**
   - Select Feb 29, 2020 (valid leap year)
   - Then try Feb 29, 2021 (invalid - not a leap year)
   - Expected: Should handle gracefully

## Automated Unit Tests

### Setting Up Unit Tests (First Time)

1. In Xcode, go to **File → New → Target**
2. Select **macOS → Unit Testing Bundle**
3. Name it `DeathClockTests`
4. Make sure it targets the `DeathClock` app
5. Add the test file `DeathClockTests/SettingsViewModelDateValidationTests.swift` to the test target

### Running Tests

- Press `⌘U` in Xcode to run all tests
- Or click the diamond icon next to individual test methods

### Test File

See `DeathClockTests/SettingsViewModelDateValidationTests.swift` for comprehensive unit tests covering:
- Future date normalization
- Past date normalization  
- Valid date preservation
- Edge cases (leap days, boundaries)

