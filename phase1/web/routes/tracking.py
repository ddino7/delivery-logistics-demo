from flask import Blueprint, request, jsonify, current_app

tracking_bp = Blueprint('tracking', __name__)

@tracking_bp.route('/<tracking_number>', methods=['GET'])
def track_shipment(tracking_number):
    """Track shipment - returns complete shipment data"""
    try:
        db_service = current_app.db_service
        collection = db_service.get_collection('shipments')
        
        shipment = collection.find_one({'tracking_number': tracking_number})
        
        if not shipment:
            return jsonify({
                'found': False,
                'message': 'Shipment not found'
            }), 404
        
        # Convert ObjectId
        shipment['_id'] = str(shipment['_id'])
        
        # Add found flag
        shipment['found'] = True
        
        # Return EVERYTHING
        return jsonify(shipment), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@tracking_bp.route('/search', methods=['GET'])
def search_shipments():
    """Search shipments"""
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
        
        return jsonify({'shipments': shipments, 'count': len(shipments)}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
