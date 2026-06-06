import requests
from datetime import datetime, date, timedelta
import json
import os


OPEN_METEO_FORECAST_URL  = "https://api.open-meteo.com/v1/forecast"
OPEN_METEO_ARCHIVE_URL   = "https://archive-api.open-meteo.com/v1/archive"
NAGER_DATE_URL           = "https://date.nager.at/api/v3/PublicHolidays/{year}/HR"
SUNRISE_SUNSET_URL       = "https://api.sunrise-sunset.org/json"

WEATHER_PARAMS = "temperature_2m,precipitation,windspeed_10m,weathercode,visibility"

_BASE_DIR      = os.path.dirname(os.path.abspath(__file__))
_HOLIDAY_CACHE = os.path.join(_BASE_DIR, "holiday_cache.json")



def _load_holiday_cache() -> dict:
    if os.path.exists(_HOLIDAY_CACHE):
        with open(_HOLIDAY_CACHE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def _save_holiday_cache(cache: dict):
    with open(_HOLIDAY_CACHE, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)


def get_holidays(year: int) -> dict:

    cache = _load_holiday_cache()
    key = str(year)

    if key in cache:
        return cache[key]

    try:
        url = NAGER_DATE_URL.format(year=year)
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        holidays = {item["date"]: item["localName"] for item in data}
        cache[key] = holidays
        _save_holiday_cache(cache)
        return holidays
    except Exception as e:
        print(f"[WeatherService] Could not fetch holidays for {year}: {e}")
        return {}


def check_holiday(departure_date: date) -> tuple:
    
    holidays = get_holidays(departure_date.year)
    date_str = departure_date.strftime("%Y-%m-%d")
    if date_str in holidays:
        return True, holidays[date_str]
    return False, None


# ── Sunrise / Sunset ───────────────────────────────────────────────────────────

def get_sun_times(lat: float, lng: float, target_date: date) -> dict:
 
    try:
        params = {
            "lat": lat,
            "lng": lng,
            "date": target_date.strftime("%Y-%m-%d"),
            "formatted": 0
        }
        resp = requests.get(SUNRISE_SUNSET_URL, params=params, timeout=10)
        resp.raise_for_status()
        results = resp.json().get("results", {})

        sunrise_utc = datetime.fromisoformat(results["sunrise"].replace("Z", "+00:00"))
        sunset_utc  = datetime.fromisoformat(results["sunset"].replace("Z", "+00:00"))

        offset = 2 if 3 < target_date.month < 11 else 1
        sunrise_local = sunrise_utc.hour + sunrise_utc.minute / 60 + offset
        sunset_local  = sunset_utc.hour  + sunset_utc.minute  / 60 + offset

        return {"sunrise_hour": round(sunrise_local, 2), "sunset_hour": round(sunset_local, 2)}
    except Exception as e:
        print(f"[WeatherService] Sunrise-Sunset API error: {e}")
        return {"sunrise_hour": 6.5, "sunset_hour": 18.5}


def compute_night_driving(departure_hour: float, duration_hours: float,
                           sunrise_hour: float, sunset_hour: float) -> dict:
  
    arrival_hour = departure_hour + duration_hours

    night_hours = 0.0
    steps = int(duration_hours * 60)
    steps = max(steps, 1)

    for i in range(steps):
        h = departure_hour + i / 60
        h_mod = h % 24
        if h_mod < sunrise_hour or h_mod > sunset_hour:
            night_hours += 1 / 60

    ratio = round(min(night_hours / duration_hours, 1.0), 3) if duration_hours > 0 else 0.0
    is_dark = departure_hour % 24 > sunset_hour or departure_hour % 24 < sunrise_hour

    return {"night_driving_ratio": ratio, "is_dark_departure": is_dark}



def _fetch_forecast(lat: float, lng: float, target_date: date, hour: int) -> dict | None:
    """Fetch weather for a future date (up to 16 days ahead) using forecast endpoint."""
    try:
        params = {
            "latitude": lat,
            "longitude": lng,
            "hourly": WEATHER_PARAMS,
            "forecast_days": 16,
            "timezone": "Europe/Zagreb"
        }
        resp = requests.get(OPEN_METEO_FORECAST_URL, params=params, timeout=15)
        resp.raise_for_status()
        data = resp.json()
        return _extract_hour(data, target_date, hour)
    except Exception as e:
        print(f"[WeatherService] Forecast API error for ({lat},{lng}): {e}")
        return None


def _fetch_historical(lat: float, lng: float, target_date: date, hour: int) -> dict | None:
    """Fetch real measured weather for a past date using archive endpoint."""
    try:
        date_str = target_date.strftime("%Y-%m-%d")
        params = {
            "latitude": lat,
            "longitude": lng,
            "start_date": date_str,
            "end_date": date_str,
            "hourly": WEATHER_PARAMS,
            "timezone": "Europe/Zagreb"
        }
        resp = requests.get(OPEN_METEO_ARCHIVE_URL, params=params, timeout=15)
        resp.raise_for_status()
        data = resp.json()
        return _extract_hour(data, target_date, hour)
    except Exception as e:
        print(f"[WeatherService] Archive API error for ({lat},{lng}): {e}")
        return None


def _extract_hour(data: dict, target_date: date, hour: int) -> dict | None:
    """Extract single-hour values from Open-Meteo hourly response."""
    try:
        times = data["hourly"]["time"]
        target_str = f"{target_date.strftime('%Y-%m-%d')}T{hour:02d}:00"

        if target_str not in times:
            for candidate in [target_str.replace(f"T{hour:02d}:00", f"T{h:02d}:00") for h in range(24)]:
                if candidate in times:
                    target_str = candidate
                    break
            else:
                return None

        idx = times.index(target_str)
        hourly = data["hourly"]

        return {
            "temperature_c":  round(hourly["temperature_2m"][idx] or 0, 1),
            "precipitation_mm": round(hourly["precipitation"][idx] or 0, 2),
            "windspeed_kmh":  round(hourly["windspeed_10m"][idx] or 0, 1),
            "weather_code":   int(hourly["weathercode"][idx] or 0),
            "visibility_m":   round((hourly["visibility"][idx] or 10000), 0)
        }
    except Exception as e:
        print(f"[WeatherService] Hour extraction error: {e}")
        return None


def get_weather_for_location(lat: float, lng: float,
                              target_date: date, hour: int) -> dict | None:
    
    today = date.today()
    days_ahead = (target_date - today).days

    if days_ahead < 0:
        return _fetch_historical(lat, lng, target_date, hour)
    elif days_ahead <= 15:
        return _fetch_forecast(lat, lng, target_date, hour)
    else:
        return None



def get_weather_for_route(locations: list, target_date: date, hour: int) -> dict:
   
    readings = []
    for loc in locations:
        lat = loc.get("lat") or loc.get("latitude")
        lng = loc.get("lng") or loc.get("lon") or loc.get("longitude")
        if lat is None or lng is None:
            continue
        w = get_weather_for_location(float(lat), float(lng), target_date, hour)
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
        "num_nodes_checked":    len(readings)
    }


def _default_weather() -> dict:
    """Fallback when API is unavailable."""
    return {
        "max_precipitation_mm": 0.0,
        "max_windspeed_kmh":    0.0,
        "min_visibility_m":     10000,
        "max_weather_code":     0,
        "bad_weather_nodes":    0,
        "avg_temperature_c":    15.0,
        "num_nodes_checked":    0
    }