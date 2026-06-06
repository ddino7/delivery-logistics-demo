import argparse
import json
import math
import os
import random
import sys
from datetime import date, datetime, timedelta, timezone

sys.path.insert(0, os.path.dirname(__file__))

from hac_traffic  import get_traffic_load
from holidays     import load_holidays, check_holiday
from noise_models import total_hidden_delay
from weather_cache import WeatherCache, get_route_weather, LOCATIONS


CACHE_DIR  = os.path.join(os.path.dirname(__file__), "data", "weather_cache")
DATA_DIR   = os.path.join(os.path.dirname(__file__), "data")
OUTPUT_FILE = os.path.join(DATA_DIR, "training_data.jsonl")

START_DATE = date(2024, 1, 1)
END_DATE   = date(2025, 12, 31)
YEARS      = [2024, 2025]

DISPATCH_HOURS = list(range(5, 21))

CITIES = list(LOCATIONS.keys())

ROAD_VULNERABILITY = {
    "coastal":  1.40,
    "regional": 1.20,
    "mixed":    1.10,
    "highway":  0.90,
}

DELAY_THRESHOLD = 0.20


_SUNSET_BY_MONTH = {
    1: 16.5, 2: 17.3, 3: 18.2, 4: 19.0, 5: 19.8,
    6: 20.3, 7: 20.1, 8: 19.4, 9: 18.3, 10: 17.2,
    11: 16.4, 12: 16.1
}
_SUNRISE_BY_MONTH = {
    1: 7.3, 2: 6.8, 3: 6.0, 4: 6.0, 5: 5.3,
    6: 5.0, 7: 5.1, 8: 5.6, 9: 6.2, 10: 6.8,
    11: 6.5, 12: 7.2
}


def _night_ratio(departure_hour: float, duration_hours: float, month: int) -> tuple[float, bool]:
    sunrise = _SUNRISE_BY_MONTH[month]
    sunset  = _SUNSET_BY_MONTH[month]
    night   = 0.0
    steps   = max(int(duration_hours * 60), 1)
    for i in range(steps):
        h = (departure_hour + i / 60) % 24
        if h < sunrise or h > sunset:
            night += 1 / 60
    ratio   = round(min(night / duration_hours, 1.0), 3) if duration_hours > 0 else 0.0
    is_dark = (departure_hour % 24) > sunset or (departure_hour % 24) < sunrise
    return ratio, is_dark



_ROUTE_TABLE = {
    # (origin, destination): (distance_km, time_hours, cost_per_km, road_type)
    frozenset(["Zagreb",    "Split"]):          (380, 4.0, 1.5, "highway"),
    frozenset(["Zagreb",    "Rijeka"]):         (165, 2.0, 1.5, "highway"),
    frozenset(["Zagreb",    "Osijek"]):         (280, 3.5, 1.5, "highway"),
    frozenset(["Zagreb",    "Zadar"]):          (285, 3.8, 1.6, "regional"),
    frozenset(["Zagreb",    "Pula"]):           (260, 3.3, 1.4, "highway"),
    frozenset(["Zagreb",    "Dubrovnik"]):      (580, 7.0, 1.6, "mixed"),
    frozenset(["Zagreb",    "Karlovac"]):       ( 55, 0.75,1.2, "regional"),
    frozenset(["Zagreb",    "Varazdin"]):       ( 80, 1.0, 1.2, "highway"),
    frozenset(["Zagreb",    "Slavonski Brod"]): (200, 2.5, 1.3, "highway"),
    frozenset(["Zagreb",    "Sibenik"]):        (320, 3.8, 1.7, "highway"),
    frozenset(["Split",     "Rijeka"]):         (420, 5.0, 1.5, "highway"),
    frozenset(["Split",     "Osijek"]):         (460, 5.5, 1.6, "regional"),
    frozenset(["Split",     "Zadar"]):          (155, 2.0, 1.2, "highway"),
    frozenset(["Split",     "Pula"]):           (280, 3.8, 1.3, "coastal"),
    frozenset(["Split",     "Dubrovnik"]):      (230, 3.0, 1.4, "coastal"),
    frozenset(["Split",     "Karlovac"]):       (320, 4.2, 1.4, "regional"),
    frozenset(["Split",     "Varazdin"]):       (410, 5.0, 1.5, "highway"),
    frozenset(["Split",     "Slavonski Brod"]): (380, 4.5, 1.4, "mixed"),
    frozenset(["Split",     "Sibenik"]):        ( 85, 1.25,1.2, "coastal"),
    frozenset(["Rijeka",    "Osijek"]):         (350, 4.3, 1.4, "regional"),
    frozenset(["Rijeka",    "Zadar"]):          (190, 2.5, 1.3, "coastal"),
    frozenset(["Rijeka",    "Pula"]):           (105, 1.5, 1.3, "coastal"),
    frozenset(["Rijeka",    "Dubrovnik"]):      (490, 5.8, 1.7, "highway"),
    frozenset(["Rijeka",    "Karlovac"]):       (120, 1.6, 1.2, "highway"),
    frozenset(["Rijeka",    "Varazdin"]):       (180, 2.2, 1.3, "regional"),
    frozenset(["Rijeka",    "Slavonski Brod"]): (360, 4.5, 1.4, "mixed"),
    frozenset(["Rijeka",    "Sibenik"]):        (275, 3.5, 1.5, "coastal"),
    frozenset(["Osijek",    "Zadar"]):          (430, 5.2, 1.4, "regional"),
    frozenset(["Osijek",    "Pula"]):           (510, 6.0, 1.5, "mixed"),
    frozenset(["Osijek",    "Dubrovnik"]):      (590, 7.2, 1.7, "mixed"),
    frozenset(["Osijek",    "Karlovac"]):       (300, 3.5, 1.5, "highway"),
    frozenset(["Osijek",    "Varazdin"]):       (210, 2.7, 1.3, "highway"),
    frozenset(["Osijek",    "Slavonski Brod"]): ( 62, 0.8, 1.2, "regional"),
    frozenset(["Osijek",    "Sibenik"]):        (440, 5.3, 1.5, "mixed"),
    frozenset(["Zadar",     "Pula"]):           (165, 2.3, 1.3, "coastal"),
    frozenset(["Zadar",     "Dubrovnik"]):      (290, 3.6, 1.4, "coastal"),
    frozenset(["Zadar",     "Karlovac"]):       (210, 3.0, 1.5, "regional"),
    frozenset(["Zadar",     "Varazdin"]):       (350, 4.3, 1.5, "mixed"),
    frozenset(["Zadar",     "Slavonski Brod"]): (370, 4.6, 1.4, "mixed"),
    frozenset(["Zadar",     "Sibenik"]):        ( 70, 1.0, 1.3, "coastal"),
    frozenset(["Pula",      "Dubrovnik"]):      (515, 6.5, 1.5, "highway"),
    frozenset(["Pula",      "Karlovac"]):       (180, 2.5, 1.3, "regional"),
    frozenset(["Pula",      "Varazdin"]):       (295, 3.7, 1.3, "regional"),
    frozenset(["Pula",      "Slavonski Brod"]): (465, 5.7, 1.4, "mixed"),
    frozenset(["Pula",      "Sibenik"]):        (295, 3.8, 1.4, "coastal"),
    frozenset(["Dubrovnik", "Karlovac"]):       (515, 6.3, 1.6, "highway"),
    frozenset(["Dubrovnik", "Varazdin"]):       (615, 7.5, 1.7, "highway"),
    frozenset(["Dubrovnik", "Slavonski Brod"]): (560, 6.9, 1.5, "mixed"),
    frozenset(["Dubrovnik", "Sibenik"]):        (185, 2.8, 1.4, "coastal"),
    frozenset(["Karlovac",  "Varazdin"]):       ( 90, 1.2, 1.3, "regional"),
    frozenset(["Karlovac",  "Slavonski Brod"]): (230, 3.0, 1.3, "regional"),
    frozenset(["Karlovac",  "Sibenik"]):        (255, 3.3, 1.4, "regional"),
    frozenset(["Varazdin",  "Slavonski Brod"]): (235, 3.0, 1.4, "regional"),
    frozenset(["Varazdin",  "Sibenik"]):        (385, 4.7, 1.5, "mixed"),
    frozenset(["Slavonski Brod", "Sibenik"]):   (340, 4.2, 1.4, "regional"),
}

def _num_stops(distance_km: float) -> int:
    if distance_km < 100:   return 2
    if distance_km < 250:   return 2
    if distance_km < 400:   return 3
    return 4


def _get_route(origin: str, destination: str) -> dict | None:
    key = frozenset([origin, destination])
    if key not in _ROUTE_TABLE:
        return None
    dist, time_h, cost_km, road_type = _ROUTE_TABLE[key]
    return {
        "total_distance_km":   dist,
        "total_time_hours":    time_h,
        "cost_per_km":         cost_km,
        "road_type_dominant":  road_type,
        "num_stops":           _num_stops(dist),
        "total_cost_eur":      round(dist * cost_km, 2),
    }



def compute_label(route: dict, weight_kg: float, weather: dict,
                  traffic_load: float, night_ratio: float,
                  month: int, hour: int) -> tuple[int, float]:
    """
    Returns (label, actual_hours).
    label = 1 (DELAYED) if actual > expected * (1 + DELAY_THRESHOLD).
    """
    expected   = route["total_time_hours"]
    road_type  = route["road_type_dominant"]
    vuln       = ROAD_VULNERABILITY.get(road_type, 1.0)

    w_delay = (
        weather["max_precipitation_mm"] * 0.25
        + max(0, weather["max_windspeed_kmh"] - 40) * 0.015
        + max(0, 5000 - weather["min_visibility_m"]) * 0.0003
        + weather["bad_weather_nodes"] * 0.20
    ) * vuln

    t_delay = (traffic_load - 1.0) * expected * 0.25

    n_delay = night_ratio * expected * 0.15

    wt_delay = (math.log1p(weight_kg) / math.log1p(5000)) * 0.15

    hidden = total_hidden_delay(expected, road_type, month, hour)

    actual = expected + w_delay + t_delay + n_delay + wt_delay + hidden
    actual = max(actual, expected * 0.70)   # physical minimum

    label = 1 if actual > expected * (1 + DELAY_THRESHOLD) else 0
    return label, round(actual, 4)



def build_record(origin: str, destination: str,
                 departure_dt: datetime,
                 weight_kg: float, num_items: int,
                 weather: dict, holidays: dict,
                 cache: WeatherCache) -> dict | None:

    route = _get_route(origin, destination)
    if not route:
        return None

    d    = departure_dt.date()
    hour = departure_dt.hour
    month = d.month

    is_holiday, holiday_name = check_holiday(holidays, d)
    traffic_load = get_traffic_load(origin, destination, d, holiday_name)
    night_ratio, is_dark = _night_ratio(float(hour), route["total_time_hours"], month)

    label, actual_hours = compute_label(
        route, weight_kg, weather, traffic_load, night_ratio, month, hour
    )

    return {
        "origin":              origin,
        "destination":         destination,
        "distance_km":         route["total_distance_km"],
        "expected_hours":      route["total_time_hours"],
        "num_stops":           route["num_stops"],
        "road_type":           route["road_type_dominant"],
        "cost_per_km":         route["cost_per_km"],

        "weight_kg":           round(weight_kg, 2),
        "num_items":           num_items,

        "max_precipitation_mm": weather["max_precipitation_mm"],
        "max_windspeed_kmh":    weather["max_windspeed_kmh"],
        "min_visibility_m":     weather["min_visibility_m"],
        "max_weather_code":     weather["max_weather_code"],
        "bad_weather_nodes":    weather["bad_weather_nodes"],
        "avg_temperature_c":    weather["avg_temperature_c"],

        "is_holiday":          int(is_holiday),
        "holiday_name":        holiday_name or "none",

        "traffic_load_factor": traffic_load,

        "night_driving_ratio": night_ratio,
        "is_dark_departure":   int(is_dark),

        "month":               month,
        "hour_of_day":         hour,
        "is_weekend":          int(d.weekday() >= 5),

        "label":               label,
        "actual_hours":        actual_hours,   # kept for debugging / analysis

        "departure_date":      d.isoformat(),
        "generated_at":        datetime.now(timezone.utc).isoformat(),
    }



def _stratified_dates(n: int, start: date, end: date) -> list[date]:
    
    total_days = (end - start).days + 1
    per_month  = n // 12
    extra      = n % 12

    result = []
    for m in range(1, 13):
        count = per_month + (1 if m <= extra else 0)
        candidates = []
        d = start
        while d <= end:
            if d.month == m:
                candidates.append(d)
            d += timedelta(days=1)
        if not candidates:
            continue
        sampled = random.choices(candidates, k=count)
        result.extend(sampled)

    random.shuffle(result)
    return result



def generate(n_records: int, skip_prefill: bool = False,
             use_mongo: bool = True, mongo_uri: str = None,
             mongo_db: str = None) -> int:

    os.makedirs(DATA_DIR, exist_ok=True)
    cache    = WeatherCache(CACHE_DIR)
    holidays = load_holidays(os.path.join(DATA_DIR, "holiday_cache"), YEARS)

    if not skip_prefill:
        cache.prefill(START_DATE, END_DATE)

    collection = None
    if use_mongo:
        try:
            from pymongo import MongoClient
            uri     = mongo_uri or os.getenv("MONGO_URI", "mongodb://localhost:27017/")
            db_name = mongo_db  or os.getenv("MONGO_DB_NAME", "delivery_logistics")
            client  = MongoClient(uri, serverSelectionTimeoutMS=5000)
            collection = client[db_name]["training_data"]
            deleted = collection.delete_many({}).deleted_count
            if deleted:
                print(f"[Generator] Cleared {deleted} existing training records.")
            print(f"[Generator] MongoDB connected — {db_name}.training_data")
        except Exception as e:
            print(f"[Generator] MongoDB unavailable ({e}) — JSON only.")
            collection = None

    out_path = OUTPUT_FILE
    written  = 0
    skipped  = 0

    dates = _stratified_dates(n_records, START_DATE, END_DATE)

    city_pairs = [
        (o, d) for o in CITIES for d in CITIES if o != d
    ]

    print(f"\n[Generator] Generating {n_records} records…")
    print(f"  Date range: {START_DATE} → {END_DATE}")
    print(f"  City pairs: {len(city_pairs)}")
    print(f"  Output: {out_path}\n")

    mongo_batch = []
    BATCH_SIZE  = 200

    with open(out_path, "w", encoding="utf-8") as f:
        for i, dep_date in enumerate(dates):
            origin, destination = random.choice(city_pairs)

            hour = random.choice(DISPATCH_HOURS)

            departure_dt = datetime(
                dep_date.year, dep_date.month, dep_date.day, hour
            )

            weight_kg = round(min(random.lognormvariate(4.5, 1.2), 2000), 1)
            weight_kg = max(weight_kg, 0.5)

            num_items = random.randint(1, 50)

            route_cities = [origin, destination]
            r = _get_route(origin, destination)
            if r and r["num_stops"] > 2:
                intermediates = [c for c in CITIES
                                 if c not in (origin, destination)]
                if intermediates:
                    route_cities.insert(1, random.choice(intermediates))

            weather = get_route_weather(route_cities, dep_date, hour, cache)

            record = build_record(
                origin, destination, departure_dt,
                weight_kg, num_items,
                weather, holidays, cache
            )

            if record is None:
                skipped += 1
                continue

            f.write(json.dumps(record, ensure_ascii=False) + "\n")
            written += 1

            if collection is not None:
                mongo_batch.append(record)
                if len(mongo_batch) >= BATCH_SIZE:
                    collection.insert_many(mongo_batch)
                    mongo_batch.clear()

            if written % 100 == 0 or written == n_records:
                pct = written / n_records * 100
                print(f"  {written}/{n_records} ({pct:.0f}%)  skipped={skipped}")

    if collection and mongo_batch:
        collection.insert_many(mongo_batch)

    print(f"\n✓ Done. Written={written}, Skipped={skipped}")
    print(f"  File: {out_path}  ({os.path.getsize(out_path)//1024} KB)")

    _report_distribution(out_path)

    return written


def _report_distribution(jsonl_path: str):
    from collections import Counter
    months = Counter()
    labels = Counter()
    with open(jsonl_path) as f:
        for line in f:
            r = json.loads(line)
            months[r["month"]] += 1
            labels[r["label"]] += 1

    total = sum(labels.values())
    print("\n── Label distribution ───────────────────────────")
    print(f"  ON_TIME : {labels[0]:5d} ({labels[0]/total*100:.1f}%)")
    print(f"  DELAYED : {labels[1]:5d} ({labels[1]/total*100:.1f}%)")
    print("\n── Monthly distribution ─────────────────────────")
    for m in range(1, 13):
        bar = "█" * (months[m] * 30 // max(months.values()))
        print(f"  {m:2d}: {months[m]:4d}  {bar}")



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Phase 4 Data Generator")
    parser.add_argument("--records",      type=int,  default=500,
                        help="Number of records to generate (default: 500)")
    parser.add_argument("--skip-prefill", action="store_true",
                        help="Skip weather cache pre-fill (use cached data only)")
    parser.add_argument("--no-mongo",     action="store_true",
                        help="Skip MongoDB insertion (JSON file only)")
    parser.add_argument("--mongo-uri",    type=str,  default=None,
                        help="MongoDB URI (overrides MONGO_URI env var)")
    parser.add_argument("--mongo-db",     type=str,  default=None,
                        help="MongoDB database name (overrides MONGO_DB_NAME env var)")
    args = parser.parse_args()

    generate(
        n_records    = args.records,
        skip_prefill = args.skip_prefill,
        use_mongo    = not args.no_mongo,
        mongo_uri    = args.mongo_uri,
        mongo_db     = args.mongo_db,
    )