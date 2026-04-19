# Life expectancy bundle builder

Offline-first data for the Death Clock app: **US state period life tables** from CDC spreadsheets plus **male/female life expectancy at birth** for other countries (World Bank).

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

- **`--us-source nvsr74-12`** (default) — NCHS **U.S. State Life Tables, 2022** (NVSR vol. 74, no. 12). Cache: `scripts/cache/cdc_nvsr_74_12/`. FTP: [NVSR/74-12](https://ftp.cdc.gov/pub/health_statistics/nchs/Publications/NVSR/74-12/) — files `{ST}1.xlsx` (total), `{ST}2.xlsx` (male), `{ST}3.xlsx` (female); `{ST}4.xlsx` is standard errors and is skipped.
- **`--us-source lewk4`** — Legacy **LEWK4** decennial tables (1999–2001). Cache: `scripts/cache/cdc_lewk4/`.
- `--cache-dir PATH` — override the cache directory for the chosen `--us-source`.
- `--skip-cdc` — reuse cached CDC files; still fetches World Bank (requires network).
- `--output PATH` — override output JSON path.

## Data notes

- **US states (default):** NCHS *U.S. State Life Tables, 2022* ([NVSR 74-12 PDF](https://www.cdc.gov/nchs/data/nvsr/nvsr74/nvsr74-12.pdf)), **period** life tables. Machine-readable workbooks on CDC FTP under `NVSR/74-12/`.
- **US states (legacy):** LEWK4 (1999–2001); see [LEWK4 methodology](https://www.cdc.gov/nchs/nvss/mortality/lewk4.htm).
- **Other countries:** World Bank indicators `SP.DYN.LE00.MA.IN` and `SP.DYN.LE00.FE.IN` for a fixed reference year (see `worldBankIndicatorYear` in the JSON). Remaining years at age *x* use the **US national average** *eₓ* curve from the same bundle, scaled so life expectancy at birth matches World Bank *e₀* for that country and sex.

Review licensing and attribution for each source before public distribution.
