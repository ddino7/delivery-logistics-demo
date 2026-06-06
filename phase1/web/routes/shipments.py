from flask import Blueprint, request, jsonify, current_app
from models.shipment import Shipment
from datetime import datetime, date as date_type

shipments_bp = Blueprint('shipments', __name__)


def _enrich_shipment(shipment_dict: dict, data: dict, route_info: dict | None) -> dict:
    """
    Add all Phase 4 fields to the shipment dict before MongoDB insertion.
    Safe — any failure is caught and logged; original dict is returned unchanged.
    """
    try:
        from services.weather_service import (
            get_weather_for_route, check_holiday,
            get_sun_times, compute_night_driving,
        )
        from services.hac_traffic_service import get_traffic_load_factor

        departure_str = data.get('planned_departure')
        departure_dt  = None
        if departure_str:
            for fmt in ("%Y-%m-%dT%H:%M", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M"):
                try:
                    departure_dt = datetime.strptime(departure_str, fmt)
                    break
                except ValueError:
                    continue
        if departure_dt is None:
            departure_dt = datetime.utcnow()

        departure_date = departure_dt.date()
        departure_hour = departure_dt.hour

        shipment_dict['planned_departure_at']    = departure_dt
        shipment_dict['planned_departure_month'] = departure_dt.month
        shipment_dict['planned_departure_hour']  = departure_dt.hour
        shipment_dict['is_weekend']              = departure_dt.weekday() >= 5

        is_holiday, holiday_name = check_holiday(departure_date)
        shipment_dict['is_holiday']   = is_holiday
        shipment_dict['holiday_name'] = holiday_name

        manual_weather = data.get('manual_weather')

        if manual_weather:
            weather_dict = {
                'max_precipitation_mm': float(manual_weather.get('precipitation_mm', 0)),
                'max_windspeed_kmh':    float(manual_weather.get('windspeed_kmh', 0)),
                'min_visibility_m':     float(manual_weather.get('visibility_m', 10000)),
                'max_weather_code':     int(manual_weather.get('weather_code', 0)),
                'bad_weather_nodes':    int(manual_weather.get('bad_weather_nodes', 0)),
                'avg_temperature_c':    float(manual_weather.get('temperature_c', 15)),
                'num_nodes_checked':    0,
            }
            source = 'manual'
        else:
            locations = route_info['locations'] if route_info else []
            weather_dict = get_weather_for_route(locations, departure_date, departure_hour)
            today = date_type.today()
            days  = (departure_date - today).days
            if days < 0:
                source = 'openmeteo_historical'
            elif days <= 15:
                source = 'openmeteo_forecast'
            else:
                source = 'openmeteo_seasonal_estimate'

        shipment_dict['weather_at_departure'] = {
            'source':               source,
            'max_precipitation_mm': weather_dict.get('max_precipitation_mm'),
            'max_windspeed_kmh':    weather_dict.get('max_windspeed_kmh'),
            'min_visibility_m':     weather_dict.get('min_visibility_m'),
            'max_weather_code':     weather_dict.get('max_weather_code'),
            'bad_weather_nodes':    weather_dict.get('bad_weather_nodes'),
            'avg_temperature_c':    weather_dict.get('avg_temperature_c'),
            'fetched_at':           datetime.utcnow(),
        }

        pickup_city   = data.get('pickup_city', '')
        delivery_city = data.get('delivery_city', '')
        traffic_load  = 1.0
        if pickup_city and delivery_city:
            traffic_load = get_traffic_load_factor(
                pickup_city, delivery_city, departure_date, holiday_name
            )
        shipment_dict['traffic_load_factor'] = traffic_load

        night_ratio = 0.0
        is_dark     = False
        if route_info and route_info.get('locations'):
            origin_loc = route_info['locations'][0]
            lat = origin_loc.get('lat') or origin_loc.get('latitude')
            lng = origin_loc.get('lng') or origin_loc.get('lon')
            if lat and lng:
                sun = get_sun_times(float(lat), float(lng), departure_date)
                expected_h = route_info.get('total_time_hours', 1.0)
                night_info = compute_night_driving(
                    float(departure_hour), float(expected_h),
                    sun['sunrise_hour'], sun['sunset_hour']
                )
                night_ratio = night_info['night_driving_ratio']
                is_dark     = night_info['is_dark_departure']

        shipment_dict['night_driving_ratio'] = night_ratio
        shipment_dict['is_dark_departure']   = is_dark

        shipment_dict['ml_prediction'] = {
            'risk_score':       None,
            'prediction':       None,
            'risk_level':       None,
            'confidence':       None,
            'top_risk_factors': [],
            'model_version':    None,
            'predicted_at':     None,
        }

        if route_info:
            route_info['road_type_dominant'] = _dominant_road_type(route_info)
            route_info['num_stops']          = len(route_info.get('locations', []))

        print(f"✓ [Phase4] Shipment enriched — holiday={is_holiday}, "
              f"traffic={traffic_load:.2f}, night={night_ratio:.2f}, source={source}")

    except Exception as e:
        print(f"⚠️ [Phase4] Enrichment failed (shipment still created): {e}")
        import traceback; traceback.print_exc()

    return shipment_dict


def _dominant_road_type(route_info: dict) -> str:
    routes = route_info.get('routes', [])
    if not routes:
        return 'highway'
    counts = {}
    for r in routes:
        rt = r.get('road_type', 'highway')
        counts[rt] = counts.get(rt, 0) + 1
    return max(counts, key=counts.get)



@shipments_bp.route('/', methods=['POST'])
def create_shipment():
    """Create a new shipment with automatic route calculation"""
    try:
        data = request.get_json()

        is_valid, error = Shipment.validate_data(data)
        if not is_valid:
            return jsonify({'error': error}), 400

        shipment = Shipment(
            sender=data['sender'],
            receiver=data['receiver'],
            weight=float(data['weight']),
            products=data.get('products', []),
            pickup_address=data['pickup_address'],
            delivery_address=data['delivery_address']
        )

        route_info = None
        if hasattr(current_app, 'neo4j_service') and current_app.neo4j_service:
            try:
                pickup_city   = data.get('pickup_city', '').strip()
                delivery_city = data.get('delivery_city', '').strip()
                optimize_by   = data.get('optimize_by', 'time')

                print(f"📍 Calculating route: {pickup_city} → {delivery_city} (optimize by: {optimize_by})")

                if pickup_city and delivery_city:
                    route_info = current_app.neo4j_service.find_shortest_path(
                        pickup_city, delivery_city, optimize_by
                    )
                    if route_info:
                        print(f"✓ Route found: {route_info['total_distance_km']} km, "
                              f"{route_info['total_time_hours']} h, {route_info['total_cost_eur']} EUR")
                    else:
                        print(f"⚠️ No route found between {pickup_city} and {delivery_city}")
            except Exception as e:
                print(f"❌ Route calculation error: {e}")
                import traceback; traceback.print_exc()
        else:
            print("⚠️ Neo4j service not available")

        shipment_dict = shipment.to_dict()

        if route_info:
            shipment_dict['route']                    = route_info
            shipment_dict['estimated_delivery_hours'] = route_info['total_time_hours']
            shipment_dict['estimated_cost_eur']       = route_info['total_cost_eur']
            shipment_dict['optimize_by']              = data.get('optimize_by', 'time')

        shipment_dict = _enrich_shipment(shipment_dict, data, route_info)

        try:
            from ml_client import get_risk_prediction
            ml_result = get_risk_prediction(shipment_dict)
            if ml_result:
                shipment_dict['ml_prediction'] = {
                    'risk_score':       ml_result.get('risk_score'),
                    'prediction':       ml_result.get('prediction'),
                    'risk_level':       ml_result.get('risk_level'),
                    'confidence':       ml_result.get('risk_score'),
                    'top_risk_factors': ml_result.get('top_risk_factors', []),
                    'model_version':    '1.0',
                    'predicted_at':     datetime.utcnow(),
                }
                print(f"✓ [ML] Risk: {ml_result.get('risk_level')} "
                      f"({ml_result.get('risk_pct')}%)")
        except Exception as e:
            print(f"⚠️ [ML] Prediction skipped: {e}")

        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        result     = collection.insert_one(shipment_dict)

        try:
            if hasattr(current_app, 'opensearch'):
                saved_doc = dict(shipment_dict)
                saved_doc.pop('_id', None)
                saved_doc['id'] = str(result.inserted_id)
                try:
                    current_app.opensearch.index_shipment(saved_doc)
                except Exception as e:
                    print('OpenSearch index error:', e)
        except Exception:
            pass

        response = {
            'message':         'Shipment created successfully',
            'tracking_number': shipment.tracking_number,
            'id':              str(result.inserted_id),
        }

        if route_info:
            response['route'] = {
                'path':         [loc['city'] for loc in route_info['locations']],
                'distance_km':  route_info['total_distance_km'],
                'time_hours':   route_info['total_time_hours'],
                'cost_eur':     route_info['total_cost_eur'],
                'optimized_by': data.get('optimize_by', 'time'),
            }

        response['departure_context'] = {
            'planned_departure':   shipment_dict.get('planned_departure_at',
                                                      datetime.utcnow()).isoformat()
                                   if isinstance(shipment_dict.get('planned_departure_at'), datetime)
                                   else str(shipment_dict.get('planned_departure_at', '')),
            'is_holiday':          shipment_dict.get('is_holiday', False),
            'holiday_name':        shipment_dict.get('holiday_name'),
            'is_weekend':          shipment_dict.get('is_weekend', False),
            'traffic_load_factor': shipment_dict.get('traffic_load_factor', 1.0),
            'night_driving_ratio': shipment_dict.get('night_driving_ratio', 0.0),
            'is_dark_departure':   shipment_dict.get('is_dark_departure', False),
            'weather':             {
                k: v for k, v in shipment_dict.get('weather_at_departure', {}).items()
                if k != 'fetched_at'
            },
            'weather_source':      shipment_dict.get('weather_at_departure', {}).get('source', 'unknown'),
        }

        ml_pred = shipment_dict.get('ml_prediction', {})
        if ml_pred.get('risk_score') is not None:
            response['ml_prediction'] = {
                'risk_score':       ml_pred.get('risk_score'),
                'risk_pct':         round(ml_pred.get('risk_score', 0) * 100, 1),
                'prediction':       ml_pred.get('prediction'),
                'risk_level':       ml_pred.get('risk_level'),
                'top_risk_factors': ml_pred.get('top_risk_factors', []),
            }

        return jsonify(response), 201

    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({'error': str(e)}), 500



@shipments_bp.route('/ml-predict', methods=['POST'])
def ml_predict_proxy():
    """Proxy endpoint — frontend calls this, backend calls ML service."""
    try:
        import requests as req
        import os

        data   = request.get_json()
        ml_url = os.getenv('ML_SERVICE_URL', 'http://phase4_ml_service:5050')

        resp = req.post(f"{ml_url}/predict", json=data, timeout=10)
        return jsonify(resp.json()), resp.status_code

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route('/<tracking_number>', methods=['GET'])
def get_shipment(tracking_number):
    """Get shipment by tracking number"""
    try:
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')

        shipment = collection.find_one({'tracking_number': tracking_number})
        if not shipment:
            return jsonify({'error': 'Shipment not found'}), 404

        shipment['_id'] = str(shipment['_id'])
        return jsonify(shipment), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route('/<tracking_number>/status', methods=['PUT'])
def update_status(tracking_number):
    """Update shipment status with automatic vehicle simulation control"""
    try:
        data       = request.get_json()
        new_status = data.get('status')
        note       = data.get('note', '')

        if not new_status:
            return jsonify({'error': 'Status is required'}), 400
        if new_status not in Shipment.STATUSES:
            return jsonify({'error': f'Invalid status. Must be one of: {Shipment.STATUSES}'}), 400

        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')

        shipment_data = collection.find_one({'tracking_number': tracking_number})
        if not shipment_data:
            return jsonify({'error': 'Shipment not found'}), 404

        old_status = shipment_data.get('status')

        shipment = Shipment.from_dict(shipment_data)
        shipment.update_status(new_status, note)

        extra_fields = {}
        if new_status == 'DELIVERED':
            delivered_at = datetime.utcnow()
            extra_fields['delivered_at'] = delivered_at
            try:
                created_at = shipment.created_at
                if isinstance(created_at, datetime):
                    extra_fields['delivery_time_seconds'] = int(
                        (delivered_at - created_at).total_seconds()
                    )
            except Exception:
                pass

        update_payload = {
            'status':         shipment.status,
            'updated_at':     shipment.updated_at,
            'status_history': shipment.status_history,
        }
        update_payload.update(extra_fields)

        collection.update_one(
            {'tracking_number': tracking_number},
            {'$set': update_payload}
        )

        if hasattr(current_app, 'vehicle_simulator') and current_app.vehicle_simulator:
            try:
                if new_status == 'IN_TRANSIT' and old_status != 'IN_TRANSIT':
                    if shipment_data.get('route'):
                        driver_id = data.get('driver_id')
                        success = current_app.vehicle_simulator.start_simulation(
                            tracking_number, driver_id
                        )
                        if success:
                            print(f"🚚 Started vehicle simulation for {tracking_number}")
                        else:
                            print(f"⚠️ Could not start simulation for {tracking_number}")
                    else:
                        print(f"⚠️ Cannot simulate {tracking_number} - no route available")

                elif new_status == 'DELIVERED':
                    success = current_app.vehicle_simulator.stop_simulation(tracking_number)
                    if success:
                        print(f"✅ Stopped vehicle simulation for {tracking_number} (DELIVERED)")

            except Exception as e:
                print(f"⚠️ Vehicle simulation error for {tracking_number}: {e}")
                import traceback; traceback.print_exc()

        try:
            if hasattr(current_app, 'opensearch'):
                updated_doc = collection.find_one(
                    {'tracking_number': tracking_number}, {'_id': 0}
                )
                if updated_doc:
                    try:
                        current_app.opensearch.index_shipment(updated_doc)
                    except Exception as e:
                        print('OpenSearch index error on status update:', e)
        except Exception:
            pass

        return jsonify({
            'message':         'Status updated successfully',
            'tracking_number': tracking_number,
            'new_status':      new_status,
            'simulation':      ('started'   if new_status == 'IN_TRANSIT'
                                else 'stopped' if new_status == 'DELIVERED'
                                else 'unchanged'),
        }), 200

    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route('/search', methods=['GET'])
def search_shipments():
    try:
        col = current_app.db_service.get_collection('shipments')

        q         = (request.args.get('q')         or '').strip()
        tracking  = (request.args.get('tracking')  or '').strip()
        status    = (request.args.get('status')    or '').strip()
        recipient = (request.args.get('recipient') or '').strip()

        query = {}
        if tracking:
            query['tracking_number'] = {'$regex': tracking, '$options': 'i'}
        if status:
            query['status'] = {'$regex': f'^{status}$', '$options': 'i'}
        if recipient:
            query['receiver.name'] = {'$regex': recipient, '$options': 'i'}
        if q:
            query['$or'] = [
                {'tracking_number':   {'$regex': q, '$options': 'i'}},
                {'status':            {'$regex': q, '$options': 'i'}},
                {'receiver.name':     {'$regex': q, '$options': 'i'}},
                {'delivery_address':  {'$regex': q, '$options': 'i'}},
                {'sender.name':       {'$regex': q, '$options': 'i'}},
                {'pickup_address':    {'$regex': q, '$options': 'i'}},
            ]

        docs = list(col.find(query, {'_id': 0}).limit(200))
        return jsonify({'ok': True, 'count': len(docs), 'data': docs}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route('/reindex', methods=['POST'])
def reindex_shipments():
    return jsonify({'ok': False,
                    'error': 'Reindex endpoint disabled. Use scripts/reindex_shipments.py.'}), 404


@shipments_bp.route('/', methods=['GET'])
def list_shipments():
    try:
        status = request.args.get('status')
        limit  = int(request.args.get('limit', 50))
        skip   = int(request.args.get('skip', 0))

        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')

        query = {}
        if status:
            query['status'] = status

        shipments = list(
            collection.find(query).sort('created_at', -1).limit(limit).skip(skip)
        )
        for s in shipments:
            s['_id'] = str(s['_id'])

        return jsonify({'shipments': shipments, 'count': len(shipments)}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route('/<tracking_number>', methods=['PUT'])
def update_shipment(tracking_number):
    try:
        data = request.get_json()

        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')

        shipment = collection.find_one({'tracking_number': tracking_number})
        if not shipment:
            return jsonify({'error': 'Shipment not found'}), 404

        update_data = {
            'sender':           data.get('sender',           shipment['sender']),
            'receiver':         data.get('receiver',         shipment['receiver']),
            'weight':           data.get('weight',           shipment['weight']),
            'pickup_address':   data.get('pickup_address',   shipment['pickup_address']),
            'delivery_address': data.get('delivery_address', shipment['delivery_address']),
            'updated_at':       datetime.utcnow(),
        }

        planned_departure = data.get('planned_departure')
        if planned_departure:
            try:
                from services.weather_service import check_holiday, get_weather_for_route, get_sun_times, compute_night_driving
                from services.hac_traffic_service import get_traffic_load_factor
                from datetime import date as date_type

                dep_dt = None
                for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M"):
                    try:
                        dep_dt = datetime.strptime(planned_departure[:16], fmt[:16])
                        break
                    except ValueError:
                        continue
                if dep_dt is None:
                    dep_dt = datetime.utcnow()

                dep_date = dep_dt.date()
                is_holiday, holiday_name = check_holiday(dep_date)

                update_data['planned_departure_at']    = dep_dt
                update_data['planned_departure_month'] = dep_dt.month
                update_data['planned_departure_hour']  = dep_dt.hour
                update_data['is_weekend']              = dep_dt.weekday() >= 5
                update_data['is_holiday']              = is_holiday
                update_data['holiday_name']            = holiday_name

                manual_weather = data.get('manual_weather')
                if manual_weather:
                    weather_dict = {
                        'max_precipitation_mm': float(manual_weather.get('precipitation_mm', 0)),
                        'max_windspeed_kmh':    float(manual_weather.get('windspeed_kmh', 0)),
                        'min_visibility_m':     float(manual_weather.get('visibility_m', 10000)),
                        'max_weather_code':     int(manual_weather.get('weather_code', 0)),
                        'bad_weather_nodes':    int(manual_weather.get('bad_weather_nodes', 0)),
                        'avg_temperature_c':    float(manual_weather.get('temperature_c', 15)),
                    }
                    source = 'manual'
                else:
                    route_info = shipment.get('route', {})
                    locations  = route_info.get('locations', [])
                    weather_dict = get_weather_for_route(locations, dep_date, dep_dt.hour)
                    today = date_type.today()
                    days  = (dep_date - today).days
                    source = 'openmeteo_historical' if days < 0 else 'openmeteo_forecast'

                update_data['weather_at_departure'] = {
                    'source':               source,
                    'max_precipitation_mm': weather_dict.get('max_precipitation_mm'),
                    'max_windspeed_kmh':    weather_dict.get('max_windspeed_kmh'),
                    'min_visibility_m':     weather_dict.get('min_visibility_m'),
                    'max_weather_code':     weather_dict.get('max_weather_code'),
                    'bad_weather_nodes':    weather_dict.get('bad_weather_nodes'),
                    'avg_temperature_c':    weather_dict.get('avg_temperature_c'),
                    'fetched_at':           datetime.utcnow(),
                }

                route_info    = shipment.get('route', {})
                locations     = route_info.get('locations', [])
                origin        = locations[0].get('city', '')  if locations else ''
                destination   = locations[-1].get('city', '') if locations else ''
                traffic_load  = get_traffic_load_factor(origin, destination, dep_date, holiday_name)
                update_data['traffic_load_factor'] = traffic_load

                if locations:
                    origin_loc = locations[0]
                    lat = origin_loc.get('lat') or origin_loc.get('latitude')
                    lng = origin_loc.get('lng') or origin_loc.get('lon')
                    if lat and lng:
                        sun = get_sun_times(float(lat), float(lng), dep_date)
                        expected_h = route_info.get('total_time_hours', 1.0)
                        night_info = compute_night_driving(
                            float(dep_dt.hour), float(expected_h),
                            sun['sunrise_hour'], sun['sunset_hour']
                        )
                        update_data['night_driving_ratio'] = night_info['night_driving_ratio']
                        update_data['is_dark_departure']   = night_info['is_dark_departure']

                try:
                    updated_doc = {**shipment, **update_data}
                    from ml_client import get_risk_prediction
                    ml_result = get_risk_prediction(updated_doc)
                    if ml_result:
                        update_data['ml_prediction'] = {
                            'risk_score':       ml_result.get('risk_score'),
                            'prediction':       ml_result.get('prediction'),
                            'risk_level':       ml_result.get('risk_level'),
                            'confidence':       ml_result.get('risk_score'),
                            'top_risk_factors': ml_result.get('top_risk_factors', []),
                            'model_version':    '1.0',
                            'predicted_at':     datetime.utcnow(),
                        }
                        print(f"✓ [ML] Re-predicted: {ml_result.get('risk_level')} "
                              f"({ml_result.get('risk_pct')}%)")
                except Exception as e:
                    print(f"⚠️ [ML] Re-prediction skipped: {e}")

            except Exception as e:
                print(f"⚠️ [Phase4] Departure update failed: {e}")
                import traceback; traceback.print_exc()

        collection.update_one(
            {'tracking_number': tracking_number},
            {'$set': update_data}
        )

        try:
            if hasattr(current_app, 'opensearch'):
                updated_doc = collection.find_one(
                    {'tracking_number': tracking_number}, {'_id': 0}
                )
                if updated_doc:
                    try:
                        current_app.opensearch.index_shipment(updated_doc)
                    except Exception as e:
                        print('OpenSearch index error:', e)
        except Exception:
            pass

        return jsonify({
            'message':         'Shipment updated successfully',
            'tracking_number': tracking_number,
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route('/<tracking_number>', methods=['DELETE'])
def delete_shipment(tracking_number):
    try:
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')

        if hasattr(current_app, 'vehicle_simulator') and current_app.vehicle_simulator:
            try:
                current_app.vehicle_simulator.stop_simulation(tracking_number)
            except Exception:
                pass

        result = collection.delete_one({'tracking_number': tracking_number})

        if result.deleted_count == 0:
            return jsonify({'error': 'Shipment not found'}), 404

        return jsonify({
            'message':         'Shipment deleted successfully',
            'tracking_number': tracking_number,
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500