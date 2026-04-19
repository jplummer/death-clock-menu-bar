# Death Clock Menu Bar - Development Plan

## Project Overview

A macOS menu bar widget that displays the number of days remaining until the user reaches their life expectancy, with a clickable menu for settings and controls.

## Development Phases

### Phase 1: MVP ✅ (Completed)

- Project setup
- Basic menu bar display
- Simple countdown calculation (days remaining)
- Settings UI for DOB, sex, location
- Basic life expectancy lookup (static data)
- Menu with settings and quit options
- Multiple display formats (Years/Days, Days Only, Percentage, Progress Bar)
- Auto-save settings
- Track on GitHub
- Code review and cleanup/comment pass

### Phase 2: Enhanced Calculation ✅ (Core complete; optional upgrades remain)

- Official data in the app bundle (no in-app network refresh; regenerate JSON with a script)
  - **`scripts/build_life_expectancy_bundle.py`** — default **`--us-source nvsr74-12`**: CDC FTP **NVSR/74-12** (`{ST}1/2/3.xlsx` = total/male/female, 2022 state period tables); optional **`--us-source lewk4`** for 1999–2001 decennial workbooks. Fetches World Bank male/female e₀ by country. Writes **`DeathClock/Resources/life-expectancy-data.json`** (schema v2; JSON includes `usTableSource`, `cdcTablePeriod`, FTP/PDF URLs).
  - **US:** period life tables by state + national average across states; **State** picker when country is United States (region row hidden for other countries)
  - **Non-US:** World Bank e₀ per country; remaining years at age use the US national **eₓ** curve scaled to that country’s e₀ (documented in `scripts/README.md`)
- **`LifeExpectancyDataLoader` / calculator** — remaining life from table **eₓ** by completed age; legacy v1 JSON still supported
- **Tests** — `LifeExpectancyDataLoaderTests` + existing date validation tests; shared **`DeathClock.xcscheme`** with `IDEPreferLogStreaming=YES` on Test (reduces logging noise)
- **Optional next (data)**
  - Point **`--us-source`** / FTP paths at newer **NVSR** releases when NCHS publishes the next state life table volume (watch `ftp.cdc.gov/.../NVSR/`)
  - **Subnational** data outside the US (province/region) where licensing and sources allow
  - Optional **in-app** refresh / API (only if product goals change; current design is bundle-first)
- See [DATA_SOURCES.md](DATA_SOURCES.md) and [scripts/README.md](scripts/README.md) for sources and regeneration

### Phase 3: Polish

- Memento mori/vivere modes
  - menu bar vector icons and spacing
  - progress bar formatting
  - light and dark modes
  - narrower number font
- "Bonus" for living beyond expectancy
- Animations and visual polish

### Phase 4: Lifestyle Factors (Future)

- Add lifestyle questionnaire
- Implement lifestyle adjustment factors
- Store and update lifestyle data
- Recalculate based on lifestyle changes

### Phase 5: Distribution (Future)

#### 5.1 Pre-Distribution Requirements

- **App Icon Design**
  - Create icon set in multiple sizes (16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024)
  - Add to `Assets.xcassets/AppIcon.appiconset/`
  - [-] Icon should be recognizable at small sizes (menu bar context) (nope! I have other plans for the widget itself)
- **Error Handling & Edge Cases**
  - Handle invalid dates (future dates, dates too far in past)
  - Basic loader tests (bundled JSON, US national vs state, international, high age)
  - Handle missing country data gracefully (user-visible copy when country not in bundle)
  - Handle edge cases in calculations (negative days, very old users) with clear behavior + tests as needed
  - Add user-friendly error messages
  - Log errors for debugging (without exposing user data)
- **Privacy & Permissions**
  - Review all data collection (currently: none, all local)
  - Add privacy policy if distributing publicly
  - Document what data is stored and where
  - Consider adding "Export Data" / "Delete Data" features
- **Version Management**
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

- **Join Apple Developer Program** ($99/year)
  - Required for code signing and notarization
  - Get certificates from developer.apple.com
- **Configure Code Signing in Xcode**
  - Select target → Signing & Capabilities
  - Enable "Automatically manage signing"
  - Select your Team
  - Xcode handles certificate management
- **Archive the App**
  - Product → Archive in Xcode
  - Creates signed `.xcarchive` file
  - Validates code signing before archiving
- **Notarize the App**
  - In Organizer window (after Archive)
  - Click "Distribute App"
  - Choose "Developer ID" (for outside App Store) or "App Store" (for App Store)
  - Xcode uploads to Apple for notarization
  - Wait for approval (usually minutes to hours)
  - Download notarized app

#### 5.3 Distribution Options

**Option A: Direct Distribution (Outside App Store)**

- **Create Distribution Package**
  - Build Release configuration
  - Create DMG (disk image) or ZIP file
  - Include app bundle
  - Optional: Include README, license, etc.
- **Distribution Methods**
  - Host on your website
  - GitHub Releases (free)
  - Direct download link
  - No Apple review process
- **User Experience**
  - First launch: User must right-click → Open (first time only)
  - After notarization: Smoother experience
  - No automatic updates (you handle distribution)

**Option B: Mac App Store Distribution**

- **App Store Requirements**
  - Sandboxing (restrict app capabilities)
  - App Store guidelines compliance
  - Privacy policy required
  - Screenshots and description
  - App Store review process (1-7 days)
- **App Store Benefits**
  - Automatic updates
  - Easy discovery
  - User trust
  - Payment processing (if charging)
- **App Store Limitations**
  - Sandboxing restrictions (may limit some features)
  - Review process delays updates
  - 30% revenue share (if paid)
  - More complex setup

**Option C: Hybrid Approach**

- Distribute outside App Store for power users
- Also submit to App Store for broader reach
- Different builds may be needed (sandboxing differences)

#### 5.4 Distribution Checklist

**Before Distribution:**

- Test on clean macOS install (no dev tools)
- Test on different macOS versions (if supporting multiple)
- Verify all features work without Xcode
- Check that app launches from Applications folder
- Verify menu bar icon appears correctly
- Test first-run experience
- Verify settings persistence works
- Test quit and relaunch behavior

**Distribution Package:**

- Code signed app bundle
- Notarized by Apple
- Version number set correctly
- App icon included
- DMG or ZIP created
- README or instructions included (optional)

**Post-Distribution:**

- Monitor for crash reports (if using analytics)
- Collect user feedback
- Plan update releases
- Update documentation

#### 5.5 Technical Details

**Bundle Identifier:**

- Currently: Set in Xcode project settings
- Format: `com.yourname.deathclock` (reverse domain notation)
- Must be unique if distributing publicly
- Cannot change after first distribution

**Entitlements:**

- Currently: None required for this minimal app
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
- **.zip**: Archive (e.g. GitHub Releases)
- **.pkg**: Installer package (less common for small apps)

## Next Steps

1. ✅ Set up Xcode project structure — **Done**
2. ✅ Create basic menu bar item — **Done**
3. ✅ Countdown display — **Done**
4. ✅ Settings persistence — **Done**
5. ✅ Life expectancy from bundled official-derived data (CDC LEWK4 + World Bank via `scripts/build_life_expectancy_bundle.py`) — **Done**
6. **Next (product):** Phase 3 — “bonus” past expectancy, animations / polish; or Phase 5.1 — missing-country UX, version in About, distribution prep
7. **Future:** Phase 4 — lifestyle factors
8. **Future:** Code signing, notarization, and distribution (Phase 5.2+)

