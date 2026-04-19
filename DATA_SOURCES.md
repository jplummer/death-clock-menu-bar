# Life Expectancy Data Sources

## Current Status

Bundled `DeathClock/Resources/life-expectancy-data.json` is produced by **`scripts/build_life_expectancy_bundle.py`** (see `scripts/README.md`). By default, schema v2 uses **NCHS NVSR vol. 74 no. 12** (U.S. State Life Tables, **2022**) spreadsheets from CDC FTP plus **World Bank** male/female life expectancy at birth for other countries. Use **`--us-source lewk4`** to rebuild from legacy LEWK4 (1999–2001) instead. Regenerate when you want newer CDC vintages (new NVSR folders on FTP) or refreshed World Bank figures.

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

**Pros**: Fast, works offline after bundling  
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

1. **Current**: Regenerate JSON with `scripts/build_life_expectancy_bundle.py` (NVSR 2022 state tables + World Bank e₀ in the build script).
2. **Later**: New NVSR FTP releases for updated US state tables; optional in-app refresh remains a product decision.

## Data Format Example

See `DeathClock/Resources/life-expectancy-data.json` for the expected JSON structure.

## Legal Considerations

- Check data source licensing/terms of use
- Attribute data sources appropriately
- Some sources may require attribution in app
- Ensure compliance with data usage terms

