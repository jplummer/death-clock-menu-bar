# Death Clock Menu Bar - Development Plan

## Project Overview
A macOS menu bar widget that displays the number of days remaining until the user reaches their life expectancy, with a clickable menu for settings and controls.

## Development Phases

### Phase 1: MVP ✅ (Completed)
- [x] Project setup
- [x] Basic menu bar display
- [x] Simple countdown calculation (days remaining)
- [x] Settings UI for DOB, sex, location
- [x] Basic life expectancy lookup (static data)
- [x] Menu with settings and quit options
- [x] Multiple display formats (Years/Days, Days Only, Percentage, Progress Bar)
- [x] Auto-save settings
- [x] Track on GitHub
- [x] Code review and cleanup/comment pass

### Phase 2: Enhanced Calculation (Next)
- [ ] Integrate real-time life expectancy API or official data sources
- [ ] Add more granular location data (state/province level)
- [ ] Improve accuracy with multiple data sources
- [ ] Replace hardcoded data with comprehensive data tables
- See [DATA_SOURCES.md](DATA_SOURCES.md) for data source possibilties

### Phase 3: Polish
- [x] Memento mori/vivere modes
  - [x] menu bar vector icons and spacing
  - [x] progress bar formatting
  - [x] light and dark modes
  - [x] narrower number font
- [ ] "Bonus" for living beyond expectancy
- [ ] Animations and visual polish

### Phase 4: Lifestyle Factors (Future)
- [ ] Add lifestyle questionnaire
- [ ] Implement lifestyle adjustment factors
- [ ] Store and update lifestyle data
- [ ] Recalculate based on lifestyle changes

### Phase 5: Distribution (Future)

#### 5.1 Pre-Distribution Requirements
- [x] **App Icon Design**
  - [x] Create icon set in multiple sizes (16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024)
  - [x] Add to `Assets.xcassets/AppIcon.appiconset/`
  - [-] Icon should be recognizable at small sizes (menu bar context) (nope! I have other plans for the widget itself)
  
- [ ] **Error Handling & Edge Cases**
  - [x] Handle invalid dates (future dates, dates too far in past)
  -  Handle missing country data gracefully
  - Handle edge cases in calculations (negative days, very old users)
  - Add user-friendly error messages
  - Log errors for debugging (without exposing user data)
  
- [ ] **Privacy & Permissions**
  - Review all data collection (currently: none, all local)
  - Add privacy policy if distributing publicly
  - Document what data is stored and where
  - Consider adding "Export Data" / "Delete Data" features
  
- [ ] **Version Management**
  - Set proper version numbers (`CFBundleShortVersionString` = user-facing, `CFBundleVersion` = build number)
  - Add version display in settings/about
  - Plan update mechanism (if distributing outside App Store)

#### 5.2 Code Signing & Notarization

**What is Code Signing?**
- Digital signature that proves the app comes from you
- Required for macOS to trust your app
- Uses your Apple Developer certificate
- Prevents "Unknown Developer" warnings

**What is Notarization?**
- Apple's automated security scan of your app
- Required for macOS 10.15+ (Catalina and later)
- Without it: Users get scary "app is damaged" warnings
- With it: App runs smoothly after user approval

**Steps:**
- [ ] **Join Apple Developer Program** ($99/year)
  - Required for code signing and notarization
  - Get certificates from developer.apple.com
  
- [ ] **Configure Code Signing in Xcode**
  - Select target → Signing & Capabilities
  - Enable "Automatically manage signing"
  - Select your Team
  - Xcode handles certificate management
  
- [ ] **Archive the App**
  - Product → Archive in Xcode
  - Creates signed `.xcarchive` file
  - Validates code signing before archiving
  
- [ ] **Notarize the App**
  - In Organizer window (after Archive)
  - Click "Distribute App"
  - Choose "Developer ID" (for outside App Store) or "App Store" (for App Store)
  - Xcode uploads to Apple for notarization
  - Wait for approval (usually minutes to hours)
  - Download notarized app

#### 5.3 Distribution Options

**Option A: Direct Distribution (Outside App Store)**
- [ ] **Create Distribution Package**
  - Build Release configuration
  - Create DMG (disk image) or ZIP file
  - Include app bundle
  - Optional: Include README, license, etc.
  
- [ ] **Distribution Methods**
  - Host on your website
  - GitHub Releases (free, easy)
  - Direct download link
  - No Apple review process
  
- [ ] **User Experience**
  - First launch: User must right-click → Open (first time only)
  - After notarization: Smoother experience
  - No automatic updates (you handle distribution)

**Option B: Mac App Store Distribution**
- [ ] **App Store Requirements**
  - Sandboxing (restrict app capabilities)
  - App Store guidelines compliance
  - Privacy policy required
  - Screenshots and description
  - App Store review process (1-7 days)
  
- [ ] **App Store Benefits**
  - Automatic updates
  - Easy discovery
  - User trust
  - Payment processing (if charging)
  
- [ ] **App Store Limitations**
  - Sandboxing restrictions (may limit some features)
  - Review process delays updates
  - 30% revenue share (if paid)
  - More complex setup

**Option C: Hybrid Approach**
- [ ] Distribute outside App Store for power users
- [ ] Also submit to App Store for broader reach
- [ ] Different builds may be needed (sandboxing differences)

#### 5.4 Distribution Checklist

**Before Distribution:**
- [ ] Test on clean macOS install (no dev tools)
- [ ] Test on different macOS versions (if supporting multiple)
- [ ] Verify all features work without Xcode
- [ ] Check that app launches from Applications folder
- [ ] Verify menu bar icon appears correctly
- [ ] Test first-run experience
- [ ] Verify settings persistence works
- [ ] Test quit and relaunch behavior

**Distribution Package:**
- [ ] Code signed app bundle
- [ ] Notarized by Apple
- [ ] Version number set correctly
- [ ] App icon included
- [ ] DMG or ZIP created
- [ ] README or instructions included (optional)

**Post-Distribution:**
- [ ] Monitor for crash reports (if using analytics)
- [ ] Collect user feedback
- [ ] Plan update releases
- [ ] Update documentation

#### 5.5 Technical Details

**Bundle Identifier:**
- Currently: Set in Xcode project settings
- Format: `com.yourname.deathclock` (reverse domain notation)
- Must be unique if distributing publicly
- Cannot change after first distribution

**Entitlements:**
- Currently: None required (app is simple)
- May need: `com.apple.security.app-sandbox` for App Store
- May need: Network access if adding API features later

**Hardened Runtime:**
- Required for notarization
- Can be enabled in Signing & Capabilities
- May require exceptions for certain operations
- Xcode can auto-generate exceptions if needed

**Distribution Formats:**
- **.app bundle**: The application itself
- **.dmg**: Disk image (common for macOS apps)
- **.zip**: Simple archive (GitHub Releases)
- **.pkg**: Installer package (less common for simple apps)

## Next Steps

1. ✅ Set up Xcode project structure - **Done**
2. ✅ Create basic menu bar item - **Done**
3. ✅ Implement simple countdown display - **Done**
4. ✅ Add settings persistence - **Done**
5. ✅ Integrate basic life expectancy calculation - **Done**
6. **Next**: Integrate official life expectancy data sources (see [DATA_SOURCES.md](DATA_SOURCES.md))
7. **Future**: Add lifestyle factor adjustments
8. **Future**: Prepare for App Store distribution
