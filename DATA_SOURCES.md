# Life Expectancy Data Sources

## Current Status

The app currently uses **hardcoded approximate values** in `LifeExpectancyCalculator.swift`. These are placeholder values and should be replaced with official data sources before production use.

## Recommended Data Sources

### 1. World Health Organization (WHO)
- **Source**: Global Health Observatory
- **URL**: https://www.who.int/data/gho
- **Data**: Life expectancy at birth by country, sex, and year
- **Format**: CSV/Excel downloads available
- **Update Frequency**: Annual
- **Coverage**: Global, comprehensive

### 2. Centers for Disease Control (CDC) - US Only
- **Source**: National Center for Health Statistics
- **URL**: https://www.cdc.gov/nchs/products/life_tables.htm
- **Data**: Detailed life tables by state, sex, race, and age
- **Format**: PDF, Excel, CSV
- **Update Frequency**: Annual
- **Coverage**: United States only, very detailed

### 3. World Bank
- **Source**: World Development Indicators
- **URL**: https://data.worldbank.org/indicator/SP.DYN.LE00.IN
- **Data**: Life expectancy at birth by country
- **Format**: CSV, API available
- **Update Frequency**: Annual
- **Coverage**: Global

### 4. United Nations Population Division
- **Source**: World Population Prospects
- **URL**: https://population.un.org/wpp/
- **Data**: Comprehensive demographic data including life expectancy
- **Format**: Excel, CSV
- **Update Frequency**: Biennial
- **Coverage**: Global, very detailed

## Implementation Options

### Option 1: Static JSON File (Recommended for MVP)
1. Download data from WHO/World Bank
2. Convert to JSON format (see `Resources/life-expectancy-data.json` template)
3. Load JSON file at app startup
4. Update file periodically (manual or automated)

**Pros**: Simple, fast, works offline  
**Cons**: Requires manual updates, data can become stale

### Option 2: API Integration (Recommended for Production)
1. Use World Bank API or similar
2. Fetch data on app launch or periodically
3. Cache locally for offline use
4. Update automatically

**Pros**: Always up-to-date, automated  
**Cons**: Requires internet, more complex

### Option 3: Actuarial Life Tables (Most Accurate)
1. Use official actuarial life tables (CDC for US, national stats offices for others)
2. Age-adjusted calculations
3. More accurate for older users

**Pros**: Most accurate, accounts for current age  
**Cons**: Complex, large data files, country-specific

## Next Steps

1. **Short Term**: Replace hardcoded values with data from JSON file
2. **Medium Term**: Integrate World Bank API for automatic updates
3. **Long Term**: Implement actuarial life tables for age-adjusted calculations

## Data Format Example

See `DeathClock/Resources/life-expectancy-data.json` for the expected JSON structure.

## Legal Considerations

- Check data source licensing/terms of use
- Attribute data sources appropriately
- Some sources may require attribution in app
- Ensure compliance with data usage terms

