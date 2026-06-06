import requests
import json
import os
from datetime import date

NAGER_URL = "https://date.nager.at/api/v3/PublicHolidays/{year}/HR"


def load_holidays(cache_dir: str, years: list[int]) -> dict:
    """
    Returns {date_str: holiday_name} for all requested years.
    Fetches from Nager.Date if not cached, saves to disk.
    """
    os.makedirs(cache_dir, exist_ok=True)
    all_holidays = {}

    for year in years:
        cache_path = os.path.join(cache_dir, f"holidays_{year}.json")

        if os.path.exists(cache_path):
            with open(cache_path) as f:
                year_data = json.load(f)
        else:
            print(f"[Holidays] Fetching {year} from Nager.Date…")
            try:
                resp = requests.get(NAGER_URL.format(year=year), timeout=10)
                resp.raise_for_status()
                items = resp.json()
                year_data = {item["date"]: item["localName"] for item in items}
                with open(cache_path, "w", encoding="utf-8") as f:
                    json.dump(year_data, f, ensure_ascii=False, indent=2)
                print(f"  → {len(year_data)} holidays cached for {year}")
            except Exception as e:
                print(f"  [Holidays] Error fetching {year}: {e}")
                year_data = {}

        all_holidays.update(year_data)

    return all_holidays


def check_holiday(holidays: dict, target_date: date) -> tuple[bool, str | None]:
    date_str = target_date.isoformat()
    name = holidays.get(date_str)
    return (True, name) if name else (False, None)
