"""
Simulator API Routes
Endpoints for managing vehicle simulations
"""
from flask import Blueprint, jsonify, current_app

simulator_bp = Blueprint('simulator', __name__)

@simulator_bp.route('/active', methods=['GET'])
def get_active_simulations():
    """Get list of currently active vehicle simulations"""
    try:
        if not hasattr(current_app, 'vehicle_simulator') or not current_app.vehicle_simulator:
            return jsonify({
                'error': 'Vehicle simulator not available',
                'active_simulations': []
            }), 503
        
        active = current_app.vehicle_simulator.get_active_simulations()
        
        return jsonify({
            'count': len(active),
            'active_simulations': active
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@simulator_bp.route('/start/<tracking_number>', methods=['POST'])
def start_simulation(tracking_number):
    """Manually start vehicle simulation for a shipment"""
    try:
        if not hasattr(current_app, 'vehicle_simulator') or not current_app.vehicle_simulator:
            return jsonify({'error': 'Vehicle simulator not available'}), 503
        
        success = current_app.vehicle_simulator.start_simulation(tracking_number)
        
        if success:
            return jsonify({
                'message': f'Simulation started for {tracking_number}',
                'tracking_number': tracking_number
            }), 200
        else:
            return jsonify({
                'error': f'Could not start simulation for {tracking_number}',
                'tracking_number': tracking_number
            }), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@simulator_bp.route('/stop/<tracking_number>', methods=['POST'])
def stop_simulation(tracking_number):
    """Manually stop vehicle simulation for a shipment"""
    try:
        if not hasattr(current_app, 'vehicle_simulator') or not current_app.vehicle_simulator:
            return jsonify({'error': 'Vehicle simulator not available'}), 503
        
        success = current_app.vehicle_simulator.stop_simulation(tracking_number)
        
        if success:
            return jsonify({
                'message': f'Simulation stopped for {tracking_number}',
                'tracking_number': tracking_number
            }), 200
        else:
            return jsonify({
                'error': f'No active simulation for {tracking_number}',
                'tracking_number': tracking_number
            }), 404
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@simulator_bp.route('/stop-all', methods=['POST'])
def stop_all_simulations():
    """Stop all active vehicle simulations"""
    try:
        if not hasattr(current_app, 'vehicle_simulator') or not current_app.vehicle_simulator:
            return jsonify({'error': 'Vehicle simulator not available'}), 503
        
        current_app.vehicle_simulator.stop_all()
        
        return jsonify({
            'message': 'All simulations stopped'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500