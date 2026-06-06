from flask import Blueprint, request, jsonify, current_app
from datetime import date as date_type
from services.weather_service import get_weather_for_route, check_holiday

weather_bp = Blueprint('weather', __name__)

CITY_COORDS = {
    "Zagreb":        {"lat": 45.8150, "lng": 15.9819},
    "Split":         {"lat": 43.5081, "lng": 16.4402},
    "Rijeka":        {"lat": 45.3271, "lng": 14.4419},
    "Osijek":        {"lat": 45.5550, "lng": 18.6955},
    "Karlovac":      {"lat": 45.4870, "lng": 15.5478},
    "Zadar":         {"lat": 44.1194, "lng": 15.2314},
    "Pula":          {"lat": 44.8666, "lng": 13.8496},
    "Dubrovnik":     {"lat": 42.6507, "lng": 18.0944},
    "Sibenik":       {"lat": 43.7350, "lng": 15.8952},
    "Varazdin":      {"lat": 46.3059, "lng": 16.3366},
    "Slavonski Brod":{"lat": 45.1600, "lng": 18.0158},
}


@weather_bp.route('/route', methods=['GET'])
def get_route_weather():
    """
    Returns aggregated weather for the route between origin and destination.
    Uses Neo4j route if available, otherwise interpolates between endpoint coordinates.
    """
    try:
        date_str = request.args.get('date')
        hour_str = request.args.get('hour', '9')
        origin   = request.args.get('origin')
        dest     = request.args.get('dest')

        if not all([date_str, origin, dest]):
            return jsonify({'error': 'date, origin and dest are required'}), 400

        target_date = date_type.fromisoformat(date_str)
        hour        = int(hour_str)

        locations = _get_route_locations(origin, dest)

        from services.weather_service import get_weather_for_route as gw
        weather = gw(locations, target_date, hour)

        from datetime import date as today_cls
        today = today_cls.today()
        days_ahead = (target_date - today).days
        if days_ahead < 0:
            source = "openmeteo_historical"
        elif days_ahead <= 15:
            source = "openmeteo_forecast"
        else:
            source = "openmeteo_seasonal_estimate"

        return jsonify({'weather': weather, 'source': source}), 200

    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@weather_bp.route('/holiday', methods=['GET'])
def get_holiday():
    """Check whether a given date is a Croatian public holiday."""
    try:
        date_str = request.args.get('date')
        if not date_str:
            return jsonify({'error': 'date is required'}), 400

        target_date = date_type.fromisoformat(date_str)
        is_holiday, holiday_name = check_holiday(target_date)

        return jsonify({'is_holiday': is_holiday, 'holiday_name': holiday_name}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500



def _get_route_locations(origin: str, dest: str) -> list:
    """
    Returns list of location dicts with lat/lng for weather aggregation.
    Tries Neo4j first for the actual intermediate nodes; falls back to
    just origin + destination coordinates.
    """
    # Try Neo4j
    try:
        neo4j = current_app.neo4j_service
        if neo4j:
            route = neo4j.find_shortest_path(origin, dest, optimize_by='time')
            if route and route.get('locations'):
                return route['locations']
    except Exception:
        pass

    # Fallback: just the two endpoints
    locations = []
    for city in [origin, dest]:
        coords = CITY_COORDS.get(city)
        if coords:
            locations.append({'city': city, 'lat': coords['lat'], 'lng': coords['lng']})
    return locations