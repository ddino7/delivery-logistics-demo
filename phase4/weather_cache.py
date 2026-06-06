import requests
import json
import os
import time
from collections import defaultdict
from datetime import date, timedelta

ARCHIVE_URL  = "https://archive-api.open-meteo.com/v1/archive"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
PARAMS       = "temperature_2m,precipitation,windspeed_10m,weathercode,visibility"

LOCATIONS = {
    "Zagreb":         {"lat": 45.8150, "lon": 15.9819},
    "Split":          {"lat": 43.5081, "lon": 16.4402},
    "Rijeka":         {"lat": 45.3271, "lon": 14.4419},
    "Osijek":         {"lat": 45.5550, "lon": 18.6955},
    "Karlovac":       {"lat": 45.4870, "lon": 15.5478},
    "Zadar":          {"lat": 44.1194, "lon": 15.2314},
    "Pula":           {"lat": 44.8666, "lon": 13.8496},
    "Dubrovnik":      {"lat": 42.6507, "lon": 18.0944},
    "Sibenik":        {"lat": 43.7350, "lon": 15.8952},
    "Varazdin":       {"lat": 46.3059, "lon": 16.3366},
    "Slavonski Brod": {"lat": 45.1600, "lon": 18.0158},
}


class WeatherCache:
    

    def __init__(self, cache_dir: str):
        self.cache_dir = cache_dir
        os.makedirs(cache_dir, exist_ok=True)

    def _cache_path(self, city: str, date_str: str) -> str:
        safe_city = city.replace(" ", "_")
        return os.path.join(self.cache_dir, f"{safe_city}_{date_str}.json")

    def _load(self, city: str, date_str: str) -> dict | None:
        path = self._cache_path(city, date_str)
        if os.path.exists(path):
            try:
                with open(path) as f:
                    return json.load(f)
            except Exception:
                return None
        return None

    def _save(self, city: str, date_str: str, data: dict):
        path = self._cache_path(city, date_str)
        with open(path, "w") as f:
            json.dump(data, f)

    def get(self, city: str, target_date: date, hour: int) -> dict | None:
        """Returns single-hour weather dict or None."""
        date_str = target_date.isoformat()
        daily    = self._load(city, date_str)
        if daily is None:
            daily = self._fetch_day(city, target_date)
            if daily:
                self._save(city, date_str, daily)
        if not daily:
            return None
        return daily.get(str(hour))

    def _fetch_day(self, city: str, target_date: date) -> dict | None:
        """Fetch a single day — fallback used by get() on cache miss."""
        coords = LOCATIONS.get(city)
        if not coords:
            return None

        today      = date.today()
        days_ahead = (target_date - today).days

        try:
            if days_ahead < 0:
                url    = ARCHIVE_URL
                params = {
                    "latitude":   coords["lat"],
                    "longitude":  coords["lon"],
                    "start_date": target_date.isoformat(),
                    "end_date":   target_date.isoformat(),
                    "hourly":     PARAMS,
                    "timezone":   "Europe/Zagreb",
                }
            else:
                url    = FORECAST_URL
                params = {
                    "latitude":      coords["lat"],
                    "longitude":     coords["lon"],
                    "hourly":        PARAMS,
                    "forecast_days": min(days_ahead + 1, 16),
                    "timezone":      "Europe/Zagreb",
                }

            resp = None
            for attempt in range(4):
                resp = requests.get(url, params=params, timeout=60)
                if resp.status_code == 429:
                    time.sleep(2 ** attempt)
                    continue
                break
            resp.raise_for_status()
            raw = resp.json()

            times   = raw["hourly"]["time"]
            temps   = raw["hourly"]["temperature_2m"]
            precips = raw["hourly"]["precipitation"]
            winds   = raw["hourly"]["windspeed_10m"]
            codes   = raw["hourly"]["weathercode"]
            viss    = raw["hourly"]["visibility"]

            date_prefix = target_date.isoformat()
            result = {}
            for i, t in enumerate(times):
                if t.startswith(date_prefix):
                    h = int(t[11:13])
                    result[str(h)] = {
                        "temperature_c":    round(temps[i]   or 15.0, 1),
                        "precipitation_mm": round(precips[i] or 0.0,  2),
                        "windspeed_kmh":    round(winds[i]   or 0.0,  1),
                        "weather_code":     int(codes[i]     or 0),
                        "visibility_m":     round(viss[i]    or 10000, 0),
                    }
            return result if result else None

        except Exception as e:
            print(f"  [WeatherCache] Error fetching {city} {target_date}: {e}")
            return None

    def _fetch_range(self, city: str, start_date: date, end_date: date) -> dict[str, dict] | None:
        """
        Fetch entire date range in a single API call.
        Returns dict keyed by date string: {"2023-01-01": {"0": {...}, "1": {...}, ...}, ...}
        """
        coords = LOCATIONS.get(city)
        if not coords:
            return None

        params = {
            "latitude":   coords["lat"],
            "longitude":  coords["lon"],
            "start_date": start_date.isoformat(),
            "end_date":   end_date.isoformat(),
            "hourly":     PARAMS,
            "timezone":   "Europe/Zagreb",
        }

        try:
            resp = None
            for attempt in range(4):
                resp = requests.get(ARCHIVE_URL, params=params, timeout=120)
                if resp.status_code == 429:
                    wait = 2 ** attempt
                    print(f"  [WeatherCache] 429 — waiting {wait}s…")
                    time.sleep(wait)
                    continue
                break
            resp.raise_for_status()
            raw = resp.json()

            times   = raw["hourly"]["time"]
            temps   = raw["hourly"]["temperature_2m"]
            precips = raw["hourly"]["precipitation"]
            winds   = raw["hourly"]["windspeed_10m"]
            codes   = raw["hourly"]["weathercode"]
            viss    = raw["hourly"]["visibility"]

            by_day = defaultdict(dict)
            for i, t in enumerate(times):
                day_str = t[:10]        
                hour    = str(int(t[11:13]))
                by_day[day_str][hour] = {
                    "temperature_c":    round(temps[i]   or 15.0, 1),
                    "precipitation_mm": round(precips[i] or 0.0,  2),
                    "windspeed_kmh":    round(winds[i]   or 0.0,  1),
                    "weather_code":     int(codes[i]     or 0),
                    "visibility_m":     round(viss[i]    or 10000, 0),
                }
            return dict(by_day)

        except Exception as e:
            print(f"  [WeatherCache] Error fetching range {city} {start_date}→{end_date}: {e}")
            return None

    def prefill(self, start_date: date, end_date: date, **kwargs):
        """
        Pre-fetch all city/date combinations using one API call per city.
        8041 requests → 22 requests (one per city per year, or one per city for full range).
        """
        years = sorted({start_date.year, end_date.year})

        total_cities  = len(LOCATIONS)
        total_chunks  = total_cities * len(years)
        done_chunks   = 0
        total_days    = 0
        skipped_days  = 0

        print(f"[WeatherCache] Fetching {total_cities} cities × {len(years)} year(s) "
              f"= {total_chunks} API calls…")

        for year in years:
            y_start = max(start_date, date(year, 1, 1))
            y_end   = min(end_date,   date(year, 12, 31))

            for city in LOCATIONS:
                missing = []
                d = y_start
                while d <= y_end:
                    if not os.path.exists(self._cache_path(city, d.isoformat())):
                        missing.append(d)
                    d += timedelta(days=1)

                if not missing:
                    print(f"  [{city} {year}] already cached — skipping.")
                    skipped_days += (y_end - y_start).days + 1
                    done_chunks  += 1
                    continue

                print(f"  [{city} {year}] fetching {len(missing)} missing days…", end=" ", flush=True)

                by_day = self._fetch_range(city, y_start, y_end)
                done_chunks += 1

                if not by_day:
                    print("FAILED")
                    continue

                saved = 0
                for date_str, day_data in by_day.items():
                    if day_data:
                        self._save(city, date_str, day_data)
                        saved += 1
                        total_days += 1

                print(f"saved {saved} days  ({done_chunks}/{total_chunks} chunks)")

        print(f"\n[WeatherCache] Pre-fill complete. "
              f"days_saved={total_days}, skipped={skipped_days}")


def get_route_weather(locations: list, target_date: date,
                      hour: int, cache: WeatherCache) -> dict:
    """
    Aggregate worst-case weather across all route nodes.
    locations — list of city name strings or dicts with 'city' key.
    """
    readings = []
    for loc in locations:
        city = loc if isinstance(loc, str) else loc.get("city", "")
        w = cache.get(city, target_date, hour)
        if w:
            readings.append(w)

    if not readings:
        return _default_weather()

    return {
        "max_precipitation_mm": round(max(r["precipitation_mm"] for r in readings), 2),
        "max_windspeed_kmh":    round(max(r["windspeed_kmh"]    for r in readings), 1),
        "min_visibility_m":     round(min(r["visibility_m"]     for r in readings), 0),
        "max_weather_code":     int(max(r["weather_code"]       for r in readings)),
        "bad_weather_nodes":    sum(1 for r in readings if r["weather_code"] >= 61),
        "avg_temperature_c":    round(sum(r["temperature_c"]    for r in readings) / len(readings), 1),
        "num_nodes_checked":    len(readings),
    }


def _default_weather() -> dict:
    return {
        "max_precipitation_mm": 0.0,
        "max_windspeed_kmh":    5.0,
        "min_visibility_m":     10000,
        "max_weather_code":     0,
        "bad_weather_nodes":    0,
        "avg_temperature_c":    15.0,
        "num_nodes_checked":    0,
    }