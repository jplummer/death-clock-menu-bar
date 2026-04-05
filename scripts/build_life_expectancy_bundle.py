#!/usr/bin/env python3
"""
Build DeathClock/Resources/life-expectancy-data.json from:
  - CDC LEWK4 state life table workbooks (male5 / female5 / total5 sheets)
  - World Bank male/female life expectancy at birth by country

Run from repo root:  python3 scripts/build_life_expectancy_bundle.py
"""

from __future__ import annotations

import argparse
import json
import re
import ssl
import sys
import urllib.error
import urllib.request
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

try:
  import certifi
except ImportError:
  certifi = None

try:
  from openpyxl import load_workbook
except ImportError:
  print('Missing openpyxl. Run: pip install -r scripts/requirements.txt', file=sys.stderr)
  sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUT = REPO_ROOT / 'DeathClock' / 'Resources' / 'life-expectancy-data.json'
CDC_INDEX = 'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Publications/NVSR/60_09/'
CDC_TABLE_PERIOD = '1999-2001'
WB_YEAR = 2022
WB_MALE = f'https://api.worldbank.org/v2/country/all/indicator/SP.DYN.LE00.MA.IN?format=json&date={WB_YEAR}:{WB_YEAR}&per_page=20000'
WB_FEMALE = f'https://api.worldbank.org/v2/country/all/indicator/SP.DYN.LE00.FE.IN?format=json&date={WB_YEAR}:{WB_YEAR}&per_page=20000'

# USPS code -> display name (for settings picker)
US_STATE_NAMES: dict[str, str] = {
  'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California',
  'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware', 'DC': 'District of Columbia',
  'FL': 'Florida', 'GA': 'Georgia', 'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois',
  'IN': 'Indiana', 'IA': 'Iowa', 'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana',
  'ME': 'Maine', 'MD': 'Maryland', 'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota',
  'MS': 'Mississippi', 'MO': 'Missouri', 'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada',
  'NH': 'New Hampshire', 'NJ': 'New Jersey', 'NM': 'New Mexico', 'NY': 'New York',
  'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio', 'OK': 'Oklahoma', 'OR': 'Oregon',
  'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina', 'SD': 'South Dakota',
  'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont', 'VA': 'Virginia',
  'WA': 'Washington', 'WV': 'West Virginia', 'WI': 'Wisconsin', 'WY': 'Wyoming',
}

SLUG_TO_CODE: dict[str, str] = {name.lower().replace(' ', '_'): code for code, name in US_STATE_NAMES.items()}
SLUG_TO_CODE['district_of_columbia'] = 'DC'


def ssl_context() -> ssl.SSLContext:
  if certifi:
    return ssl.create_default_context(cafile=certifi.where())
  return ssl.create_default_context()


def http_get(url: str) -> bytes:
  req = urllib.request.Request(url, headers={'User-Agent': 'death-clock-bundle/1.0'})
  with urllib.request.urlopen(req, context=ssl_context(), timeout=120) as resp:
    return resp.read()


def list_cdc_lewk4_xlsx() -> list[str]:
  html = http_get(CDC_INDEX).decode('utf-8', errors='replace')
  return sorted(set(re.findall(r'(lewk4_[a-z0-9_]+\.xlsx)', html, flags=re.I)))


def slug_from_filename(name: str) -> str:
  base = name.lower().replace('.xlsx', '')
  if base.startswith('lewk4_'):
    base = base[6:]
  return base


def parse_age_start(cell) -> int | None:
  if cell is None:
    return None
  s = str(cell).strip()
  if re.match(r'^\d+\s*-\s*\d+', s):
    return int(s.split('-')[0].strip())
  if s.isdigit():
    return int(s)
  return None


def sheet_ex_series(ws, ex_col: int = 6) -> dict[int, float]:
  """Map exact age x -> expectation of life e_x from a LEWK4 sheet."""
  out: dict[int, float] = {}
  for row in ws.iter_rows(min_row=1, values_only=True):
    if not row:
      continue
    age = parse_age_start(row[0])
    if age is None:
      continue
    if ex_col >= len(row):
      continue
    ex = row[ex_col]
    if ex is None:
      continue
    try:
      out[age] = float(ex)
    except (TypeError, ValueError):
      continue
  return out


def dense_curve(points: dict[int, float], max_age: int = 100) -> list[float]:
  if not points:
    raise ValueError('empty life table')
  arr: list[float] = []
  last = points[0]
  for a in range(max_age + 1):
    if a in points:
      last = points[a]
    arr.append(last)
  return arr


def life_table_sheet_triplet(wb) -> tuple[str, str, str]:
  """LEWK4 workbooks use total{n}/male{n}/female{n} with varying n per file."""
  pat = re.compile(r'^(male|female|total)(\d+)$', re.I)
  by_num: dict[str, dict[str, str]] = defaultdict(dict)
  for name in wb.sheetnames:
    m = pat.match(name)
    if not m:
      continue
    kind, num = m.group(1).lower(), m.group(2)
    by_num[num][kind] = name
  for num in sorted(by_num.keys(), key=lambda x: int(x)):
    b = by_num[num]
    if all(k in b for k in ('male', 'female', 'total')):
      return b['male'], b['female'], b['total']
  raise ValueError(f'No male/female/total sheet triplet in {wb.sheetnames}')


def parse_state_workbook(path: Path) -> dict[str, list[float]]:
  wb = load_workbook(path, data_only=True, read_only=True)
  try:
    sm, sf, st = life_table_sheet_triplet(wb)
    male = dense_curve(sheet_ex_series(wb[sm]))
    female = dense_curve(sheet_ex_series(wb[sf]))
    total = dense_curve(sheet_ex_series(wb[st]))
  finally:
    wb.close()
  return {'male': male, 'female': female, 'total': total}


def average_curves(curves: list[list[float]]) -> list[float]:
  if not curves:
    raise ValueError('no curves')
  n = min(len(c) for c in curves)
  return [sum(c[i] for c in curves) / len(curves) for i in range(n)]


def fetch_world_bank_e0(base_url: str) -> dict[str, float]:
  """Country display name -> value (merges all API pages)."""
  out: dict[str, float] = {}
  page = 1
  while True:
    sep = '&' if '?' in base_url else '?'
    url = f'{base_url}{sep}page={page}'
    raw = json.loads(http_get(url))
    if not isinstance(raw, list) or len(raw) < 2:
      break
    meta, rows = raw[0], raw[1]
    if not isinstance(rows, list):
      break
    for row in rows:
      if not isinstance(row, dict):
        continue
      iso = (row.get('countryiso3code') or '').strip()
      if not iso:
        continue
      val = row.get('value')
      if val is None:
        continue
      country = row.get('country') or {}
      name = country.get('value') if isinstance(country, dict) else None
      if not name:
        continue
      try:
        out[str(name)] = float(val)
      except (TypeError, ValueError):
        continue
    pages = meta.get('pages', 1) if isinstance(meta, dict) else 1
    if page >= pages:
      break
    page += 1
  return out


def build_json(cdc_dir: Path) -> dict:
  files = sorted(cdc_dir.glob('lewk4_*.xlsx'))
  if not files:
    raise SystemExit(f'No lewk4_*.xlsx in {cdc_dir}. Run without --skip-cdc or check download.')

  by_code: dict[str, dict[str, list[float]]] = {}
  for path in files:
    slug = slug_from_filename(path.name)
    code = SLUG_TO_CODE.get(slug)
    if not code:
      print(f'  skip unknown file {path.name}', file=sys.stderr)
      continue
    by_code[code] = parse_state_workbook(path)

  if len(by_code) < 50:
    print(f'  warning: only {len(by_code)} state tables parsed', file=sys.stderr)

  male_avg = average_curves([v['male'] for v in by_code.values()])
  female_avg = average_curves([v['female'] for v in by_code.values()])
  total_avg = average_curves([v['total'] for v in by_code.values()])

  male_wb = fetch_world_bank_e0(WB_MALE)
  female_wb = fetch_world_bank_e0(WB_FEMALE)

  countries: dict[str, dict[str, float]] = {}
  for name, m in male_wb.items():
    f = female_wb.get(name)
    if f is None:
      continue
    if name == 'United States':
      continue
    countries[name] = {'maleE0': round(m, 4), 'femaleE0': round(f, 4)}

  labels = {code: US_STATE_NAMES[code] for code in by_code if code in US_STATE_NAMES}

  return {
    'schemaVersion': 2,
    'generatedAt': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'cdcTablePeriod': CDC_TABLE_PERIOD,
    'cdcSourceUrl': 'https://www.cdc.gov/nchs/nvss/mortality/lewk4.htm',
    'cdcDataNote': (
      'State tables are NCHS LEWK4 decennial period life tables (1999–2001). '
      'They are older than World Bank e0; US remaining-life uses these tables directly.'
    ),
    'worldBankIndicatorYear': WB_YEAR,
    'worldBankSourceUrl': 'https://data.worldbank.org/',
    'usNationalAverage': {
      'male': male_avg,
      'female': female_avg,
      'total': total_avg,
    },
    'usRegionLabels': labels,
    'usRegions': by_code,
    'countries': countries,
  }


def download_cdc(cache_dir: Path) -> None:
  cache_dir.mkdir(parents=True, exist_ok=True)
  names = list_cdc_lewk4_xlsx()
  print(f'CDC: {len(names)} workbooks listed')
  for name in names:
    dest = cache_dir / name
    if dest.exists() and dest.stat().st_size > 1000:
      print(f'  cached {name}')
      continue
    url = CDC_INDEX.rstrip('/') + '/' + name
    print(f'  fetch {name}')
    data = http_get(url)
    dest.write_bytes(data)


def main() -> None:
  parser = argparse.ArgumentParser(description='Build life-expectancy-data.json')
  parser.add_argument('--output', type=Path, default=DEFAULT_OUT)
  parser.add_argument('--cache-dir', type=Path, default=REPO_ROOT / 'scripts' / 'cache' / 'cdc_lewk4')
  parser.add_argument('--skip-cdc', action='store_true', help='Use existing cache only; no CDC download')
  args = parser.parse_args()

  if not args.skip_cdc:
    download_cdc(args.cache_dir)
  else:
    if not args.cache_dir.exists():
      print('--skip-cdc but cache dir missing', file=sys.stderr)
      sys.exit(1)

  bundle = build_json(args.cache_dir)
  args.output.parent.mkdir(parents=True, exist_ok=True)
  args.output.write_text(json.dumps(bundle, indent=2) + '\n', encoding='utf-8')
  print(f'Wrote {args.output} ({args.output.stat().st_size // 1024} KB)')


if __name__ == '__main__':
  main()
