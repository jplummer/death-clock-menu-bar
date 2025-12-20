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

### Phase 2: Enhanced Calculation (Next)
- [ ] Integrate real-time life expectancy API or official data sources
- [ ] Add more granular location data (state/province level)
- [ ] Improve accuracy with multiple data sources
- [ ] Replace hardcoded data with comprehensive data tables
- See [DATA_SOURCES.md](DATA_SOURCES.md) for data source possibilties

### Phase 3: Lifestyle Factors (Future)
- [ ] Add lifestyle questionnaire
- [ ] Implement lifestyle adjustment factors
- [ ] Store and update lifestyle data
- [ ] Recalculate based on lifestyle changes

### Phase 4: Polish & Distribution (Future)
- [ ] App icon design
- [ ] Animations and visual polish
- [ ] Error handling and edge cases
- [ ] App Store preparation
- [ ] Notarization for distribution

## Next Steps

1. ✅ Set up Xcode project structure - **Done**
2. ✅ Create basic menu bar item - **Done**
3. ✅ Implement simple countdown display - **Done**
4. ✅ Add settings persistence - **Done**
5. ✅ Integrate basic life expectancy calculation - **Done**
6. **Next**: Integrate official life expectancy data sources (see [DATA_SOURCES.md](DATA_SOURCES.md))
7. **Future**: Add lifestyle factor adjustments
8. **Future**: Prepare for App Store distribution
