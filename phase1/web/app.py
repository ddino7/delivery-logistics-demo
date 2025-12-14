from flask import Flask, render_template, jsonify
from config import Config
from services.mongodb_service import MongoDBService
from routes.shipments import shipments_bp
from routes.tracking import tracking_bp
import os
import time

app = Flask(__name__)
app.config.from_object(Config)

# Initialize MongoDB service
db_service = MongoDBService(app.config['MONGO_URI'], app.config['MONGO_DB_NAME'])
app.db_service = db_service

# Initialize Neo4j service (Phase 2)
neo4j_service = None
if os.getenv('NEO4J_URI'):
    try:
        from services.neo4j_service import Neo4jService
        from routes.network import network_bp
        
        neo4j_service = Neo4jService(
            uri=os.getenv('NEO4J_URI'),
            user=os.getenv('NEO4J_USER', 'neo4j'),
            password=os.getenv('NEO4J_PASSWORD')
        )
        app.neo4j_service = neo4j_service
        
        # Register network blueprint
        app.register_blueprint(network_bp, url_prefix='/api/network')
        print("✓ Neo4j integration enabled (Phase 2)")
    except Exception as e:
        print(f"⚠ Neo4j integration unavailable: {e}")

# Register blueprints
app.register_blueprint(shipments_bp, url_prefix='/api/shipments')
app.register_blueprint(tracking_bp, url_prefix='/api/tracking')

@app.route('/')
def index():
    phase = 2 if neo4j_service else 1
    return render_template('index.html', server_id=app.config['SERVER_ID'], phase=phase)

@app.route('/health')
def health():
    try:
        db_service.get_collection('shipments').find_one()
        db_status = 'healthy'
    except Exception as e:
        db_status = f'unhealthy: {str(e)}'
    
    neo4j_status = 'not_configured'
    if neo4j_service:
        try:
            neo4j_service.get_network_statistics()
            neo4j_status = 'healthy'
        except:
            neo4j_status = 'unhealthy'
    
    return jsonify({
        'status': 'healthy' if db_status == 'healthy' else 'unhealthy',
        'server_id': app.config['SERVER_ID'],
        'mongodb': db_status,
        'neo4j': neo4j_status,
        'phase': 2 if neo4j_service else 1,
        'timestamp': time.time()
    })

@app.route('/create')
def create_page():
    return render_template('create_shipment.html', server_id=app.config['SERVER_ID'])

@app.route('/track')
def track_page():
    return render_template('tracking.html', server_id=app.config['SERVER_ID'])

@app.route('/shipments')
def shipments_page():
    """Page for viewing all shipments"""
    return render_template('shipments_list.html', server_id=app.config['SERVER_ID'])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=app.config['DEBUG'])
