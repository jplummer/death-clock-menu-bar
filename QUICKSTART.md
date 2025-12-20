# Quick Start Guide

## What's Been Set Up

Your Death Clock menu bar app project is ready to go! Here's what's included:

### Project Structure
- ✅ Xcode project (`DeathClock.xcodeproj`)
- ✅ Core app files in `DeathClock/`
- ✅ Settings UI with SwiftUI
- ✅ Menu bar controller
- ✅ Life expectancy calculator
- ✅ Data persistence with UserDefaults

### Key Files

**Core Application:**
- `DeathClockApp.swift` - Main app entry point
- `MenuBarController.swift` - Manages menu bar display and interactions
- `LifeExpectancyCalculator.swift` - Calculates days remaining
- `SettingsManager.swift` - Handles data persistence
- `Models.swift` - Data structures

**User Interface:**
- `Views/SettingsView.swift` - Settings popover UI

**Documentation:**
- `README.md` - Project overview
- `PLAN.md` - Development roadmap and architecture
- `DATA_SOURCES.md` - Life expectancy data sources

## Next Steps

### 1. Open Xcode Project
```bash
cd /Users/jonplummer/Projects/death-clock-menu-bar
open DeathClock.xcodeproj
```

### 2. Configure Info.plist (Important!)
You need to set `LSUIElement` to hide the dock icon:

1. In Xcode, select the **DeathClock** target
2. Go to the **Info** tab
3. Add a new key: `Application is agent (UIElement)` = `YES`
   - Or in the Info.plist file, add: `<key>LSUIElement</key><true/>`

Alternatively, you can set this in the target's build settings:
- Search for "LSUIElement" in build settings
- Set it to `YES`

### 3. Build and Run
- Press ⌘R in Xcode
- App appears in menu bar
- Settings window opens automatically on first launch

### 4. Test It Out
1. Enter your date of birth, sex, and country
2. Choose your display format preference
3. Settings save automatically - watch the countdown appear in your menu bar!

## Current Features

✅ Menu bar display showing days remaining  
✅ Multiple display formats (Years/Days, Days Only, Percentage, Progress Bar)  
✅ Click to open settings (auto-saves)  
✅ Right-click for menu (Settings, Quit)  
✅ Data persistence  
✅ Basic life expectancy calculation  

## What's Next (Future Enhancements)

- [ ] More comprehensive life expectancy data
- [ ] Lifestyle factor adjustments
- [ ] More granular location data
- [ ] App icon design
- [ ] App Store preparation

## Troubleshooting

### App doesn't appear in menu bar
- Check that `LSUIElement` is set to `YES` in Info.plist
- Verify the app is running (check Activity Monitor)

### Settings don't save
- Check that the app has proper file permissions
- Verify UserDefaults is working

### Countdown shows "Error"
- Verify all settings are filled in correctly
- Check that the date of birth is valid
- Ensure the country is in the supported list

## Need Help?

- See `PLAN.md` for architecture and roadmap
- Check `README.md` for project overview
- See `DATA_SOURCES.md` for information about life expectancy data sources

## Notes

- The life expectancy data is currently simplified - you'll want to integrate real data sources
- The app uses basic actuarial calculations - consider more sophisticated models
- All data is stored locally (privacy-first approach)

Happy coding! 🎉

