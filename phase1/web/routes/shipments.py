from flask import Blueprint, request, jsonify, current_app
from models.shipment import Shipment
from datetime import datetime

shipments_bp = Blueprint('shipments', __name__)

@shipments_bp.route('/', methods=['POST'])
def create_shipment():
    """Create a new shipment with automatic route calculation"""
    try:
        data = request.get_json()
        
        # Validate data
        is_valid, error = Shipment.validate_data(data)
        if not is_valid:
            return jsonify({'error': error}), 400
        
        # Create shipment
        shipment = Shipment(
            sender=data['sender'],
            receiver=data['receiver'],
            weight=float(data['weight']),
            products=data.get('products', []),
            pickup_address=data['pickup_address'],
            delivery_address=data['delivery_address']
        )
        
        # PHASE 2 INTEGRATION: Calculate optimal route
        route_info = None
        if hasattr(current_app, 'neo4j_service') and current_app.neo4j_service:
            try:
                # Get cities
                pickup_city = data.get('pickup_city', '').strip()
                delivery_city = data.get('delivery_city', '').strip()
                optimize_by = data.get('optimize_by', 'time')
                
                print(f"📍 Calculating route: {pickup_city} → {delivery_city} (optimize by: {optimize_by})")
                
                if pickup_city and delivery_city:
                    route_info = current_app.neo4j_service.find_shortest_path(
                        pickup_city, delivery_city, optimize_by
                    )
                    
                    if route_info:
                        print(f"✓ Route found: {route_info['total_distance_km']} km, {route_info['total_time_hours']} h, {route_info['total_cost_eur']} EUR")
                    else:
                        print(f"⚠️ No route found between {pickup_city} and {delivery_city}")
                else:
                    print(f"⚠️ Missing city information")
                    
            except Exception as e:
                print(f"❌ Route calculation error: {e}")
                import traceback
                traceback.print_exc()
        else:
            print("⚠️ Neo4j service not available")
        
        # Save shipment with route info
        shipment_dict = shipment.to_dict()
        if route_info:
            shipment_dict['route'] = route_info
            shipment_dict['estimated_delivery_hours'] = route_info['total_time_hours']
            shipment_dict['estimated_cost_eur'] = route_info['total_cost_eur']
            shipment_dict['optimize_by'] = data.get('optimize_by', 'time')

        # PHASE 4 OPTIONAL: Predict delivery time (model or heuristic)
        if route_info and hasattr(current_app, "eta_service"):
            try:
                eta_hours, eta_source = current_app.eta_service.predict(shipment_dict, route_info)
                shipment_dict["predicted_delivery_hours"] = eta_hours
                shipment_dict["prediction_source"] = eta_source
                route_info["predicted_delivery_hours"] = eta_hours
                print(f"ℹ ETA ({eta_source}): {eta_hours:.2f} hours")
            except Exception as e:
                print(f"⚠ ETA prediction error: {e}")
        
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        result = collection.insert_one(shipment_dict)

        # Index in OpenSearch (if configured) - use shipment dict without Mongo _id
        try:
            if hasattr(current_app, "opensearch"):
                saved_doc = dict(shipment_dict)
                saved_doc.pop("_id", None)
                # include string id for completeness (OpenSearchService will prefer tracking_number)
                saved_doc["id"] = str(result.inserted_id)
                try:
                    current_app.opensearch.index_shipment(saved_doc)
                except Exception as e:
                    print("OpenSearch index error:", e)
        except Exception:
            pass
        
        response = {
            'message': 'Shipment created successfully',
            'tracking_number': shipment.tracking_number,
            'id': str(result.inserted_id)
        }
        
        if "predicted_delivery_hours" in shipment_dict:
            response["predicted_delivery_hours"] = shipment_dict["predicted_delivery_hours"]
            response["prediction_source"] = shipment_dict.get("prediction_source", "heuristic")

        # Include route in response
        if route_info:
            response['route'] = {
                'path': [loc['city'] for loc in route_info['locations']],
                'distance_km': route_info['total_distance_km'],
                'time_hours': route_info['total_time_hours'],
                'cost_eur': route_info['total_cost_eur'],
                'optimized_by': data.get('optimize_by', 'time')
            }
        
        return jsonify(response), 201
        
    except Exception as e:
        import traceback
        traceback.print_exc()
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
    """Update shipment status"""
    try:
        data = request.get_json()
        new_status = data.get('status')
        note = data.get('note', '')
        
        if not new_status:
            return jsonify({'error': 'Status is required'}), 400
        
        if new_status not in Shipment.STATUSES:
            return jsonify({'error': f'Invalid status. Must be one of: {Shipment.STATUSES}'}), 400
        
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        
        shipment_data = collection.find_one({'tracking_number': tracking_number})
        if not shipment_data:
            return jsonify({'error': 'Shipment not found'}), 404
        
        shipment = Shipment.from_dict(shipment_data)
        shipment.update_status(new_status, note)

        # If delivered, set delivered_at and compute delivery time
        extra_fields = {}
        if new_status == 'DELIVERED':
            delivered_at = datetime.utcnow()
            extra_fields['delivered_at'] = delivered_at
            try:
                created_at = shipment.created_at
                if isinstance(created_at, datetime):
                    delivery_sec = int((delivered_at - created_at).total_seconds())
                    extra_fields['delivery_time_seconds'] = delivery_sec
            except Exception:
                pass

        update_payload = {
            'status': shipment.status,
            'updated_at': shipment.updated_at,
            'status_history': shipment.status_history,
        }
        update_payload.update(extra_fields)

        collection.update_one(
            {'tracking_number': tracking_number},
            {'$set': update_payload}
        )

        # Re-index updated shipment in OpenSearch (if configured)
        try:
            if hasattr(current_app, "opensearch"):
                updated_doc = collection.find_one({'tracking_number': tracking_number}, {'_id': 0})
                if updated_doc:
                    try:
                        current_app.opensearch.index_shipment(updated_doc)
                    except Exception as e:
                        print("OpenSearch index error on status update:", e)
        except Exception:
            pass
        
        return jsonify({
            'message': 'Status updated successfully',
            'tracking_number': tracking_number,
            'new_status': new_status
        }), 200
        
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route("/search", methods=["GET"])
def search_shipments():
    """
    Advanced search by tracking number, status and recipient fields.
    Query params:
      - q (free text across multiple fields)
      - tracking
      - status
      - recipient
    """
    try:
        col = current_app.db_service.get_collection("shipments")

        q = (request.args.get("q") or "").strip()
        tracking = (request.args.get("tracking") or "").strip()
        status = (request.args.get("status") or "").strip()
        recipient = (request.args.get("recipient") or "").strip()

        query = {}

        # spec. filteri
        if tracking:
            query["tracking_number"] = {"$regex": tracking, "$options": "i"}

        if status:
            query["status"] = {"$regex": f"^{status}$", "$options": "i"}

        if recipient:
            query["receiver.name"] = {"$regex": recipient, "$options": "i"}

        # free-text q across important fields
        if q:
            query["$or"] = [
                {"tracking_number": {"$regex": q, "$options": "i"}},
                {"status": {"$regex": q, "$options": "i"}},
                {"receiver.name": {"$regex": q, "$options": "i"}},
                {"delivery_address": {"$regex": q, "$options": "i"}},
                {"sender.name": {"$regex": q, "$options": "i"}},
                {"pickup_address": {"$regex": q, "$options": "i"}},
            ]

        docs = list(col.find(query, {"_id": 0}).limit(200))
        return jsonify({"ok": True, "count": len(docs), "data": docs}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@shipments_bp.route("/reindex", methods=["POST"])
def reindex_shipments():
    # Reindexing via HTTP endpoint is unsafe for production and has been disabled.
    # Use the CLI script at `scripts/reindex_shipments.py` instead.
    return jsonify({"ok": False, "error": "Reindex endpoint disabled. Use scripts/reindex_shipments.py."}), 404

@shipments_bp.route('/', methods=['GET'])
def list_shipments():
    """List all shipments with optional filtering"""
    try:
        status = request.args.get('status')
        limit = int(request.args.get('limit', 50))
        skip = int(request.args.get('skip', 0))
        
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        
        query = {}
        if status:
            query['status'] = status
        
        shipments = list(collection.find(query).sort('created_at', -1).limit(limit).skip(skip))
        
        for shipment in shipments:
            shipment['_id'] = str(shipment['_id'])
        
        return jsonify({
            'shipments': shipments,
            'count': len(shipments)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@shipments_bp.route('/<tracking_number>', methods=['PUT'])
def update_shipment(tracking_number):
    """Update shipment details"""
    try:
        data = request.get_json()
        
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        
        # Check if exists
        shipment = collection.find_one({'tracking_number': tracking_number})
        if not shipment:
            return jsonify({'error': 'Shipment not found'}), 404
        
        # Update fields
        update_data = {
            'sender': data.get('sender', shipment['sender']),
            'receiver': data.get('receiver', shipment['receiver']),
            'weight': data.get('weight', shipment['weight']),
            'pickup_address': data.get('pickup_address', shipment['pickup_address']),
            'delivery_address': data.get('delivery_address', shipment['delivery_address']),
            'updated_at': datetime.utcnow()
        }
        
        collection.update_one(
            {'tracking_number': tracking_number},
            {'$set': update_data}
        )

        # Re-fetch - doc - re-index u OpenSearch-u
        try:
            if hasattr(current_app, "opensearch"):
                updated_doc = collection.find_one({'tracking_number': tracking_number}, {'_id': 0})
                if updated_doc:
                    # da budemo isg da postoji id
                    if 'id' not in updated_doc:
                        pass
                    try:
                        current_app.opensearch.index_shipment(updated_doc)
                    except Exception as e:
                        print("OpenSearch index error:", e)
        except Exception:
            pass

        return jsonify({
            'message': 'Shipment updated successfully',
            'tracking_number': tracking_number
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@shipments_bp.route('/<tracking_number>', methods=['DELETE'])
def delete_shipment(tracking_number):
    """Delete a shipment"""
    try:
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        
        result = collection.delete_one({'tracking_number': tracking_number})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'Shipment not found'}), 404
        
        return jsonify({
            'message': 'Shipment deleted successfully',
            'tracking_number': tracking_number
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
