import os
import requests

ML_SERVICE_URL = os.getenv("ML_SERVICE_URL", "http://phase4_ml_service:5050")
TIMEOUT = 5


def get_risk_prediction(shipment_doc: dict) -> dict | None:
    """
    Calls ml_service /predict and returns the prediction dict.
    Returns None on any failure so shipment creation always succeeds.
    """
    try:
        route   = shipment_doc.get("route", {})
        weather = shipment_doc.get("weather_at_departure", {})

        payload = {
            "origin":      _extract_city(route, 0),
            "destination": _extract_city(route, -1),
            "planned_departure": _format_dt(
                shipment_doc.get("planned_departure_at")
            ),
            "route_locations": [
                loc.get("city", "") for loc in route.get("locations", [])
            ],
            "shipment": {
                "distance_km":    route.get("total_distance_km", 0),
                "expected_hours": route.get("total_time_hours", 0),
                "num_stops":      route.get("num_stops", 2),
                "road_type":      route.get("road_type_dominant", "highway"),
                "cost_per_km":    _avg_cost(route),
                "weight_kg":      float(shipment_doc.get("weight", 50)),
                "num_items":      _count_items(shipment_doc),
            },
            "manual_weather": {
                "precipitation_mm":  weather.get("max_precipitation_mm", 0),
                "windspeed_kmh":     weather.get("max_windspeed_kmh", 0),
                "visibility_m":      weather.get("min_visibility_m", 10000),
                "weather_code":      weather.get("max_weather_code", 0),
                "bad_weather_nodes": weather.get("bad_weather_nodes", 0),
                "temperature_c":     weather.get("avg_temperature_c", 15),
            } if weather.get("source") else None,
        }

        resp = requests.post(
            f"{ML_SERVICE_URL}/predict",
            json=payload,
            timeout=TIMEOUT
        )
        resp.raise_for_status()
        return resp.json()

    except Exception as e:
        print(f"[ML Client] Prediction failed (non-critical): {e}")
        return None


def get_route_analysis(shipment_doc: dict) -> dict | None:
    
    try:
        route   = shipment_doc.get("route", {})
        weather = shipment_doc.get("weather_at_departure", {})

        payload = {
            "origin":      _extract_city(route, 0),
            "destination": _extract_city(route, -1),
            "planned_departure": _format_dt(
                shipment_doc.get("planned_departure_at")
            ),
            "route_locations": [
                loc.get("city", "") for loc in route.get("locations", [])
            ],
            "shipment": {
                "distance_km":    route.get("total_distance_km", 0),
                "expected_hours": route.get("total_time_hours", 0),
                "num_stops":      route.get("num_stops", 2),
                "road_type":      route.get("road_type_dominant", "highway"),
                "cost_per_km":    _avg_cost(route),
                "weight_kg":      float(shipment_doc.get("weight", 50)),
                "num_items":      _count_items(shipment_doc),
            },
            "manual_weather": {
                "precipitation_mm":  weather.get("max_precipitation_mm", 0),
                "windspeed_kmh":     weather.get("max_windspeed_kmh", 0),
                "visibility_m":      weather.get("min_visibility_m", 10000),
                "weather_code":      weather.get("max_weather_code", 0),
                "bad_weather_nodes": weather.get("bad_weather_nodes", 0),
                "temperature_c":     weather.get("avg_temperature_c", 15),
            } if weather.get("source") else None,
        }

        resp = requests.post(
            f"{ML_SERVICE_URL}/analyze-route",
            json=payload,
            timeout=10
        )
        resp.raise_for_status()
        return resp.json()

    except Exception as e:
        print(f"[ML Client] Route analysis failed (non-critical): {e}")
        return None



def _extract_city(route: dict, index: int) -> str:
    locs = route.get("locations", [])
    if not locs:
        return ""
    try:
        return locs[index].get("city", "")
    except IndexError:
        return ""


def _format_dt(dt) -> str:
    if dt is None:
        from datetime import datetime
        return datetime.now().strftime("%Y-%m-%dT%H:%M")
    if hasattr(dt, "strftime"):
        return dt.strftime("%Y-%m-%dT%H:%M")
    return str(dt)[:16]


def _avg_cost(route: dict) -> float:
    routes = route.get("routes", [])
    if not routes:
        return 1.3
    costs = [r.get("cost_per_km", 1.3) for r in routes if r.get("cost_per_km")]
    return round(sum(costs) / len(costs), 3) if costs else 1.3


def _count_items(shipment_doc: dict) -> int:
    products = shipment_doc.get("products", [])
    return sum(p.get("quantity", 1) for p in products) if products else 1