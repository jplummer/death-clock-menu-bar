# Death Clock Menu Bar

A macOS menu bar widget that displays the number of days remaining until you reach your life expectancy based on statistical averages.

## Features

- **Menu Bar Display**: Shows days remaining in your Mac's menu bar
- **Click to Configure**: Click the menu bar item to open settings
- **Demographic-Based Calculation**: Uses date of birth, sex, and location for life expectancy estimates
- **Privacy-First**: All data stored locally on your Mac

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for development)

## Setup & Development

See [QUICKSTART.md](QUICKSTART.md) for detailed setup instructions.

### Quick Start

1. **Open in Xcode**:
   ```bash
   open DeathClock.xcodeproj
   ```

2. **Build and Run**:
   - In Xcode, select Product → Build (⌘B)
   - Then Product → Run (⌘R)
   - The app will appear in your menu bar

### Project Structure

```
death-clock-menu-bar/
├── DeathClock/                      # Xcode project source files
│   ├── DeathClockApp.swift          # Main app entry point
│   ├── MenuBarController.swift      # Menu bar management
│   ├── LifeExpectancyCalculator.swift # Calculation logic
│   ├── SettingsManager.swift        # Data persistence
│   ├── Models.swift                 # Data models
│   ├── Views/
│   │   └── SettingsView.swift       # Settings UI
│   └── Resources/
│       └── life-expectancy-data.json
├── DeathClock.xcodeproj/            # Xcode project
└── [documentation files]
```

## Usage

1. **First Launch**: The settings window will appear automatically
2. **Enter Information**:
   - Your date of birth
   - Sex
   - Country (and optional region)
   - Display format preference
3. **Auto-Save**: Settings save automatically as you change them
4. **View Countdown**: The days remaining will appear in your menu bar
5. **Update Settings**: Click the menu bar item to modify settings

## Life Expectancy Data

Currently uses simplified static data tables. Future versions will include:
- More comprehensive country/region data
- Real-time API integration
- Lifestyle factor adjustments

## Future Enhancements

- [ ] Enhanced life expectancy calculation with lifestyle factors
- [ ] More granular location data (state/province level)
- [ ] Historical trends and projections
- [ ] Optional notifications
- [ ] App Store distribution

## Development Roadmap

See [PLAN.md](PLAN.md) for detailed development phases and architecture.

## Contributing

This is a personal project, but suggestions and improvements are welcome! Totally vibe oded with Cursor. I asked questions and gave instructions, read code but didn't write or edit any.

## License

MIT License - feel free to use and modify as needed.

