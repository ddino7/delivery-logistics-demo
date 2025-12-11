from flask import Blueprint, request, jsonify, current_app

network_bp = Blueprint('network', __name__)

@network_bp.route('/locations', methods=['GET'])
def get_locations():
    """Get all distribution centers and warehouses"""
    try:
        neo4j_service = current_app.neo4j_service
        locations = neo4j_service.get_all_locations()
        
        return jsonify({
            'locations': locations,
            'count': len(locations)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@network_bp.route('/locations/<location_id>', methods=['GET'])
def get_location(location_id):
    """Get specific location details"""
    try:
        neo4j_service = current_app.neo4j_service
        location = neo4j_service.get_location_by_id(location_id)
        
        if not location:
            return jsonify({'error': 'Location not found'}), 404
        
        
        routes = neo4j_service.get_routes_from_location(location_id)
        location['routes'] = routes
        
        return jsonify(location), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@network_bp.route('/locations/city/<city>', methods=['GET'])
def get_locations_by_city(city):
    """Get all locations in a specific city"""
    try:
        neo4j_service = current_app.neo4j_service
        locations = neo4j_service.get_location_by_city(city)
        
        return jsonify({
            'city': city,
            'locations': locations,
            'count': len(locations)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@network_bp.route('/routes', methods=['GET'])
def get_optimal_route():
    """Calculate optimal route between two cities"""
    try:
        from_city = request.args.get('from')
        to_city = request.args.get('to')
        optimize_by = request.args.get('optimize_by', 'distance')
        
        if not from_city or not to_city:
            return jsonify({'error': 'Both from and to city parameters are required'}), 400
        
        if optimize_by not in ['distance', 'time', 'cost']:
            return jsonify({'error': 'optimize_by must be one of: distance, time, cost'}), 400
        
        neo4j_service = current_app.neo4j_service
        path = neo4j_service.find_shortest_path(from_city, to_city, optimize_by)
        
        if not path:
            return jsonify({
                'error': 'No route found between cities',
                'from': from_city,
                'to': to_city
            }), 404
        
        return jsonify({
            'from': from_city,
            'to': to_city,
            'path': path
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@network_bp.route('/statistics', methods=['GET'])
def get_statistics():
    """Get network statistics"""
    try:
        neo4j_service = current_app.neo4j_service
        stats = neo4j_service.get_network_statistics()
        
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@network_bp.route('/initialize', methods=['POST'])
def initialize_network():
    """Initialize network from Cypher file (admin endpoint)"""
    try:
        neo4j_service = current_app.neo4j_service
        cypher_file = '/var/lib/neo4j/import/init-network.cypher'
        
        success = neo4j_service.initialize_network(cypher_file)
        
        if success:
            stats = neo4j_service.get_network_statistics()
            return jsonify({
                'message': 'Network initialized successfully',
                'statistics': stats
            }), 200
        else:
            return jsonify({'error': 'Failed to initialize network'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500