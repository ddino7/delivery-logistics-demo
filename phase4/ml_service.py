import json
import math
import os
import pickle
import sys
from datetime import date, datetime, timedelta, timezone

import numpy as np
from flask import Flask, jsonify, request


BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR  = os.path.join(BASE_DIR, "models")

MODEL_PATH    = os.path.join(MODELS_DIR, "best_model.pkl")
SCALER_PATH   = os.path.join(MODELS_DIR, "scaler.pkl")
FEATURES_PATH = os.path.join(MODELS_DIR, "feature_names.json")


def load_artifacts():
    with open(MODEL_PATH,    "rb") as f: model    = pickle.load(f)
    with open(SCALER_PATH,   "rb") as f: scaler   = pickle.load(f)
    with open(FEATURES_PATH, "r")  as f: features = json.load(f)
    print(f"✓ [ML Service] Model loaded: {type(model).__name__}")
    print(f"  Features: {len(features)}")
    return model, scaler, features

try:
    MODEL, SCALER, FEATURE_NAMES = load_artifacts()
    MODEL_READY = True
except Exception as e:
    print(f"⚠ [ML Service] Could not load model: {e}")
    MODEL, SCALER, FEATURE_NAMES = None, None, []
    MODEL_READY = False


sys.path.insert(0, BASE_DIR)
try:
    from hac_traffic import get_traffic_load
    from holidays   import load_holidays, check_holiday
    HAC_READY = True
except ImportError as e:
    print(f"⚠ [ML Service] HAC/Holiday modules unavailable: {e}")
    HAC_READY = False

_HOLIDAY_CACHE = {}
if HAC_READY:
    try:
        current_year = datetime.now().year
        cache_dir    = os.path.join(BASE_DIR, "data", "holiday_cache")
        _HOLIDAY_CACHE = load_holidays(cache_dir, [current_year, current_year + 1])
        print(f"✓ [ML Service] Holidays loaded: {len(_HOLIDAY_CACHE)} entries")
    except Exception as e:
        print(f"⚠ [ML Service] Holiday load error: {e}")


def _fetch_weather_for_route(locations: list, target_date: date, hour: int) -> dict:
    """Fetch real weather from Open-Meteo for route nodes."""
    try:
        from weather_cache import WeatherCache, get_route_weather
        cache_dir = os.path.join(BASE_DIR, "data", "weather_cache")
        cache     = WeatherCache(cache_dir)
        return get_route_weather(locations, target_date, hour, cache)
    except Exception as e:
        print(f"  [ML Service] Weather fetch error: {e}")
        return _default_weather()


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


_SUNSET_BY_MONTH  = {1:16.5, 2:17.3, 3:18.2, 4:19.0, 5:19.8,
                      6:20.3, 7:20.1, 8:19.4, 9:18.3, 10:17.2,
                      11:16.4, 12:16.1}
_SUNRISE_BY_MONTH = {1:7.3,  2:6.8,  3:6.0,  4:6.0,  5:5.3,
                      6:5.0,  7:5.1,  8:5.6,  9:6.2,  10:6.8,
                      11:6.5, 12:7.2}


def _night_ratio(hour: float, duration: float, month: int) -> tuple:
    sunrise = _SUNRISE_BY_MONTH[month]
    sunset  = _SUNSET_BY_MONTH[month]
    night   = 0.0
    steps   = max(int(duration * 60), 1)
    for i in range(steps):
        h = (hour + i / 60) % 24
        if h < sunrise or h > sunset:
            night += 1 / 60
    ratio   = round(min(night / duration, 1.0), 3) if duration > 0 else 0.0
    is_dark = (hour % 24) > sunset or (hour % 24) < sunrise
    return ratio, is_dark


ROAD_TYPES = ["coastal", "highway", "mixed", "regional"]
HOLIDAY_NAMES = [
    "Bogojavljenje, Sveta tri kralja", "Božić",
    "Dan antifašističke borbe", "Dan državnosti",
    "Dan pobjede i domovinske zahvalnosti i Dan hrvatskih branitelja",
    "Dan sjećanja na žrtve Domovinskog rata", "Dan svih svetih",
    "Međunarodni praznik rada", "Nova Godina",
    "Prvi dan po Božiću, Sveti Stjepan, Štefanje, Stipanje",
    "Tijelovo", "Uskrs i uskrsni ponedjeljak", "Velika Gospa", "none"
]


def build_feature_vector(shipment: dict, weather: dict,
                          departure_dt: datetime,
                          traffic_load: float,
                          is_holiday: bool, holiday_name: str) -> np.ndarray:
    """
    Build feature vector in exact order matching FEATURE_NAMES.
    Returns numpy array ready for model.predict_proba().
    """
    month  = departure_dt.month
    hour   = departure_dt.hour
    night_ratio, is_dark = _night_ratio(
        float(hour),
        float(shipment.get("expected_hours", 2.0)),
        month
    )

    base = {
        "distance_km":          float(shipment.get("distance_km", 0)),
        "expected_hours":       float(shipment.get("expected_hours", 0)),
        "num_stops":            int(shipment.get("num_stops", 2)),
        "cost_per_km":          float(shipment.get("cost_per_km", 1.3)),
        "weight_kg":            float(shipment.get("weight_kg", 50)),
        "num_items":            int(shipment.get("num_items", 1)),
        "max_precipitation_mm": float(weather.get("max_precipitation_mm", 0)),
        "max_windspeed_kmh":    float(weather.get("max_windspeed_kmh", 0)),
        "min_visibility_m":     float(weather.get("min_visibility_m", 10000)),
        "max_weather_code":     int(weather.get("max_weather_code", 0)),
        "bad_weather_nodes":    int(weather.get("bad_weather_nodes", 0)),
        "avg_temperature_c":    float(weather.get("avg_temperature_c", 15)),
        "is_holiday":           int(is_holiday),
        "traffic_load_factor":  float(traffic_load),
        "night_driving_ratio":  float(night_ratio),
        "is_dark_departure":    int(is_dark),
        "month":                month,
        "hour_of_day":          hour,
        "is_weekend":           int(departure_dt.weekday() >= 5),
    }

    road_type = shipment.get("road_type", "highway")
    for rt in ROAD_TYPES:
        base[f"road_type_{rt}"] = int(road_type == rt)

    hname = holiday_name if holiday_name else "none"
    for hn in HOLIDAY_NAMES:
        base[f"holiday_name_{hn}"] = int(hname == hn)

    vector = np.array([base.get(f, 0) for f in FEATURE_NAMES],
                      dtype=np.float64)
    return vector


def explain_risk(shipment: dict, weather: dict, traffic_load: float,
                 is_holiday: bool, holiday_name: str,
                 departure_dt: datetime) -> list:
    """Return top risk factors as human-readable strings."""
    factors = []
    month = departure_dt.month

    if weather.get("max_precipitation_mm", 0) > 5:
        factors.append(f"Visoka količina oborina ({weather['max_precipitation_mm']}mm)")
    if weather.get("max_windspeed_kmh", 0) > 50:
        factors.append(f"Jak vjetar ({weather['max_windspeed_kmh']} km/h)")
    if weather.get("max_weather_code", 0) >= 61:
        factors.append("Loši vremenski uvjeti na ruti")
    if weather.get("bad_weather_nodes", 0) > 0:
        factors.append(f"Loše vrijeme na {weather['bad_weather_nodes']} čvor(a) rute")

    if traffic_load > 1.8:
        factors.append(f"Ekstremno prometno opterećenje (×{traffic_load:.2f})")
    elif traffic_load > 1.3:
        factors.append(f"Povećano prometno opterećenje (×{traffic_load:.2f})")

    if is_holiday and holiday_name:
        factors.append(f"Državni praznik: {holiday_name}")

    night_ratio, _ = _night_ratio(
        float(departure_dt.hour),
        float(shipment.get("expected_hours", 2.0)),
        month
    )
    if night_ratio > 0.5:
        factors.append(f"Pretežno noćna vožnja ({int(night_ratio*100)}%)")
    elif night_ratio > 0.2:
        factors.append(f"Djelomično noćna vožnja ({int(night_ratio*100)}%)")

    road_type = shipment.get("road_type", "highway")
    if road_type == "coastal" and month in [6, 7, 8, 9]:
        factors.append("Obalna ruta u turističkoj sezoni")

    if float(shipment.get("weight_kg", 0)) > 500:
        factors.append(f"Teška pošiljka ({shipment['weight_kg']} kg)")

    if float(shipment.get("distance_km", 0)) > 400:
        factors.append(f"Duga ruta ({shipment['distance_km']} km)")

    return factors[:5] if factors else ["Nema značajnih faktora rizika"]


app = Flask(__name__)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status":      "healthy" if MODEL_READY else "degraded",
        "model_ready": MODEL_READY,
        "model_type":  type(MODEL).__name__ if MODEL_READY else None,
        "n_features":  len(FEATURE_NAMES),
    }), 200 if MODEL_READY else 503


@app.route("/predict", methods=["POST"])
def predict():
    """
    Predict delay risk for a single shipment.

    Expected JSON:
    {
        "shipment": {
            "distance_km": 380,
            "expected_hours": 4.0,
            "num_stops": 3,
            "road_type": "highway",
            "cost_per_km": 1.5,
            "weight_kg": 450,
            "num_items": 5
        },
        "route_locations": ["Zagreb", "Split"],   // city names
        "planned_departure": "2026-08-15T14:00",  // ISO datetime
        "origin": "Zagreb",
        "destination": "Split",
        "manual_weather": null                    // optional override
    }
    """
    if not MODEL_READY:
        return jsonify({"error": "Model not loaded"}), 503

    try:
        data     = request.get_json()
        shipment = data.get("shipment", {})

        dep_str = data.get("planned_departure", datetime.now(timezone.utc).isoformat())
        for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M", "%Y-%m-%d %H:%M"):
            try:
                dep_dt = datetime.strptime(dep_str[:16], fmt[:len(dep_str[:16])])
                break
            except ValueError:
                continue
        else:
            dep_dt = datetime.now()

        dep_date = dep_dt.date()

        is_holiday, holiday_name = check_holiday(_HOLIDAY_CACHE, dep_date) \
            if HAC_READY else (False, None)

        origin      = data.get("origin", "")
        destination = data.get("destination", "")
        traffic_load = get_traffic_load(origin, destination, dep_date, holiday_name) \
            if HAC_READY else 1.0

        manual = data.get("manual_weather")
        if manual:
            weather = {
                "max_precipitation_mm": float(manual.get("precipitation_mm", 0)),
                "max_windspeed_kmh":    float(manual.get("windspeed_kmh", 0)),
                "min_visibility_m":     float(manual.get("visibility_m", 10000)),
                "max_weather_code":     int(manual.get("weather_code", 0)),
                "bad_weather_nodes":    int(manual.get("bad_weather_nodes", 0)),
                "avg_temperature_c":    float(manual.get("temperature_c", 15)),
            }
        else:
            locations = data.get("route_locations", [origin, destination])
            weather   = _fetch_weather_for_route(locations, dep_date, dep_dt.hour)

        fv      = build_feature_vector(shipment, weather, dep_dt,
                                        traffic_load, is_holiday, holiday_name)
        fv_sc   = SCALER.transform(fv.reshape(1, -1))
        proba   = MODEL.predict_proba(fv_sc)[0][1]  # P(DELAYED)
        pred    = int(proba >= 0.5)

        if proba >= 0.70:
            risk_level = "HIGH"
        elif proba >= 0.45:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"

        factors = explain_risk(shipment, weather, traffic_load,
                                is_holiday, holiday_name, dep_dt)

        return jsonify({
            "risk_score":       round(float(proba), 4),
            "risk_pct":         round(float(proba) * 100, 1),
            "prediction":       "DELAYED" if pred else "ON_TIME",
            "risk_level":       risk_level,
            "top_risk_factors": factors,
            "context": {
                "is_holiday":          is_holiday,
                "holiday_name":        holiday_name,
                "traffic_load_factor": round(traffic_load, 3),
                "weather_source":      "manual" if manual else "openmeteo",
                "weather_summary": {
                    "precipitation_mm": weather.get("max_precipitation_mm"),
                    "windspeed_kmh":    weather.get("max_windspeed_kmh"),
                    "weather_code":     weather.get("max_weather_code"),
                },
            },
        }), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/analyze-route", methods=["POST"])
def analyze_route():
    """
    Compare multiple departure time slots for the same route.
    Returns ranked options with risk scores.

    Expected JSON: same as /predict but without planned_departure
    (we generate multiple slots automatically)
    """
    if not MODEL_READY:
        return jsonify({"error": "Model not loaded"}), 503

    try:
        data        = request.get_json()
        base_dep    = data.get("planned_departure",
                               datetime.now(timezone.utc).isoformat())

        for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M"):
            try:
                base_dt = datetime.strptime(base_dep[:16], fmt[:16])
                break
            except ValueError:
                continue
        else:
            base_dt = datetime.now()

        slots = [
            base_dt,
            base_dt.replace(hour=6),                      
            base_dt.replace(hour=9),                      
            (base_dt + timedelta(days=1)).replace(hour=6), 
            (base_dt + timedelta(days=1)).replace(hour=9), 
        ]
        seen = set()
        unique_slots = []
        for s in slots:
            key = s.strftime("%Y-%m-%dT%H:%M")
            if key not in seen:
                seen.add(key)
                unique_slots.append(s)

        options = []
        for slot in unique_slots:
            slot_data = dict(data)
            slot_data["planned_departure"] = slot.strftime("%Y-%m-%dT%H:%M")

            with app.test_request_context(
                "/predict", method="POST",
                json=slot_data,
                content_type="application/json"
            ):
                resp = predict()
                if hasattr(resp, "get_json"):
                    result = resp.get_json()
                else:
                    result = resp[0].get_json()

            options.append({
                "departure":    slot.strftime("%Y-%m-%dT%H:%M"),
                "departure_label": _slot_label(slot, base_dt),
                "risk_score":   result.get("risk_score", 0.5),
                "risk_pct":     result.get("risk_pct", 50),
                "risk_level":   result.get("risk_level", "MEDIUM"),
                "prediction":   result.get("prediction", "UNKNOWN"),
                "top_factors":  result.get("top_risk_factors", []),
            })

        options.sort(key=lambda x: x["risk_score"])
        options[0]["recommended"] = True

        return jsonify({
            "options":       options,
            "best_departure": options[0]["departure"],
            "recommendation": (
                f"Preporučujemo polazak {options[0]['departure_label']} "
                f"— rizik kašnjenja {options[0]['risk_pct']}%"
            ),
        }), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


def _slot_label(slot: datetime, base: datetime) -> str:
    diff = (slot.date() - base.date()).days
    time_str = slot.strftime("%H:%M")
    if diff == 0:
        return f"danas u {time_str}"
    elif diff == 1:
        return f"sutra u {time_str}"
    else:
        return slot.strftime("%d.%m. u %H:%M")


if __name__ == "__main__":
    port = int(os.getenv("ML_SERVICE_PORT", 5050))
    print(f"[ML Service] Starting on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)