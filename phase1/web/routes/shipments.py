from flask import Blueprint, request, jsonify, current_app
from models.shipment import Shipment
from datetime import datetime

shipments_bp = Blueprint('shipments', __name__)

@shipments_bp.route('/', methods=['POST'])
def create_shipment():
    """Create a new shipment"""
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
        
        
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        result = collection.insert_one(shipment.to_dict())
        
        return jsonify({
            'message': 'Shipment created successfully',
            'tracking_number': shipment.tracking_number,
            'id': str(result.inserted_id)
        }), 201
        
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
        
        
        collection.update_one(
            {'tracking_number': tracking_number},
            {'$set': {
                'status': shipment.status,
                'updated_at': shipment.updated_at,
                'status_history': shipment.status_history
            }}
        )
        
        return jsonify({
            'message': 'Status updated successfully',
            'tracking_number': tracking_number,
            'new_status': new_status
        }), 200
        
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

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