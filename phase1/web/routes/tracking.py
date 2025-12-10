from flask import Blueprint, request, jsonify, current_app

tracking_bp = Blueprint('tracking', __name__)

@tracking_bp.route('/<tracking_number>', methods=['GET'])
def track_shipment(tracking_number):
    """Track shipment by tracking number"""
    try:
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        
        shipment = collection.find_one({'tracking_number': tracking_number})
        
        if not shipment:
            return jsonify({
                'found': False,
                'message': 'Shipment not found'
            }), 404
        
        
        shipment['_id'] = str(shipment['_id'])
        
        
        tracking_info = {
            'found': True,
            'tracking_number': shipment['tracking_number'],
            'status': shipment['status'],
            'sender': shipment['sender'],
            'receiver': shipment['receiver'],
            'weight': shipment['weight'],
            'pickup_address': shipment['pickup_address'],
            'delivery_address': shipment['delivery_address'],
            'created_at': shipment['created_at'],
            'updated_at': shipment['updated_at'],
            'status_history': shipment['status_history']
        }
        
        return jsonify(tracking_info), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tracking_bp.route('/search', methods=['GET'])
def search_shipments():
    """Search shipments by receiver name or other criteria"""
    try:
        receiver_name = request.args.get('receiver_name')
        status = request.args.get('status')
        
        if not receiver_name and not status:
            return jsonify({'error': 'At least one search parameter is required'}), 400
        
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        
        
        query = {}
        if receiver_name:
            query['receiver.name'] = {'$regex': receiver_name, '$options': 'i'}
        if status:
            query['status'] = status
        
        
        shipments = list(collection.find(query).sort('created_at', -1).limit(50))
        
        
        for shipment in shipments:
            shipment['_id'] = str(shipment['_id'])
        
        return jsonify({
            'shipments': shipments,
            'count': len(shipments)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500