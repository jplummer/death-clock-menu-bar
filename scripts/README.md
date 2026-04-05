# Life expectancy bundle builder

Offline-first data for the Death Clock app: **US state period life tables** (CDC LEWK4 spreadsheets) plus **male/female life expectancy at birth** for other countries (World Bank).

## One-time setup

```bash
cd /path/to/death-clock-menu-bar
python3 -m venv .venv
source .venv/bin/activate
pip install -r scripts/requirements.txt
```

## Regenerate `life-expectancy-data.json`

Requires network access to download CDC `.xlsx` files and World Bank JSON.

```bash
source .venv/bin/activate
python3 scripts/build_life_expectancy_bundle.py
```

Output is written to `DeathClock/Resources/life-expectancy-data.json`.

### Options

- `--cache-dir PATH` — reuse downloaded CDC workbooks (default: `scripts/cache/cdc_lewk4`)
- `--skip-cdc` — only refresh World Bank country values (expects cached or existing US tables; not typical)
- `--output PATH` — override output JSON path

## Data notes

- **US states**: NCHS *U.S. Decennial Life Tables, 1999–2001*, spreadsheet release LEWK4 ([methodology page](https://www.cdc.gov/nchs/nvss/mortality/lewk4.htm)). Values are **period life tables** (not cohort forecasts).
- **Other countries**: World Bank indicators `SP.DYN.LE00.MA.IN` and `SP.DYN.LE00.FE.IN` for a fixed reference year (see `worldBankIndicatorYear` in the JSON). Remaining years at age *x* use the **US national average curve** from the same bundle, scaled so life expectancy at birth matches World Bank *e₀* for that country and sex.

Review licensing and attribution for each source before public distribution.
