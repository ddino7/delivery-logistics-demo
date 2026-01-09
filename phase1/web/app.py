from flask import Flask, render_template, jsonify
from config import Config
from services.mongodb_service import MongoDBService
from services.eta_service import EtaService
from routes.shipments import shipments_bp
from routes.tracking import tracking_bp
# `routes.location` depends on kafka; guard import so CLI tools (reindex) can run without kafka installed
try:
    from routes.location import location_bp
except Exception as _:
    location_bp = None
import os
import time

app = Flask(__name__)
app.config.from_object(Config)

# Initialize MongoDB service
db_service = MongoDBService(app.config['MONGO_URI'], app.config['MONGO_DB_NAME'])
app.db_service = db_service

# Initialize ETA predictor (Phase 4 - optional)
eta_model_path = os.getenv("ETA_MODEL_PATH", "/app/phase4/model.joblib")
eta_stats_path = os.getenv("ETA_STATS_PATH", "/app/phase4/model.json")
try:
    app.eta_service = EtaService(model_path=eta_model_path, stats_path=eta_stats_path)
    if app.eta_service.has_model:
        print("✓ ETA model loaded (Phase 4)")
    else:
        print("ℹ Using heuristic ETA (Phase 4)")
except Exception as e:
    print(f"⚠ ETA service unavailable: {e}")

# Initialize OpenSearch (Phase 3)
opensearch_url = os.getenv("OPENSEARCH_URL", "http://phase3_opensearch:9200")
try:
    from services.opensearch_service import OpenSearchService
    _os_service = OpenSearchService(opensearch_url)
    # Always attach the service if URL is provided; initial health may be delayed
    app.opensearch = _os_service
    if _os_service.is_available():
        print("✓ OpenSearch integration enabled (Phase 3)")
    else:
        print(f"⚠ OpenSearch at {opensearch_url} appears unavailable right now; will retry on demand")
except Exception as e:
    print(f"⚠ OpenSearch integration unavailable: {e}")

# Dashboards URL (can be overridden with env var DASHBOARDS_URL)
dashboards_url = os.getenv('DASHBOARDS_URL', 'http://localhost:5601/app/home#/')

@app.context_processor
def inject_dashboards_url():
    return dict(dashboards_url=dashboards_url)

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
if location_bp:
    app.register_blueprint(location_bp, url_prefix='/api/location')
# register search blueprint (Phase 3)
try:
    from routes.search import search_bp

    app.register_blueprint(search_bp, url_prefix="/api/search")
except Exception as e:
    print(f"⚠ Search blueprint not registered: {e}")

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
    
    opensearch_status = 'not_configured'
    try:
        if hasattr(app, 'opensearch'):
            opensearch_status = 'healthy' if app.opensearch.is_available() else 'unhealthy'
    except Exception:
        opensearch_status = 'unhealthy'

    eta_status = 'not_configured'
    try:
        if hasattr(app, 'eta_service'):
            eta_status = 'model' if app.eta_service.has_model else 'heuristic'
    except Exception:
        eta_status = 'unhealthy'
    
    return jsonify({
        'status': 'healthy' if db_status == 'healthy' else 'unhealthy',
        'server_id': app.config['SERVER_ID'],
        'mongodb': db_status,
        'neo4j': neo4j_status,
        'opensearch': opensearch_status,
        'eta': eta_status,
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

@app.route('/map')
def map_page():
    return render_template('map.html', server_id=app.config['SERVER_ID'])

@app.route('/network')
def network_page():
    if not neo4j_service:
        return "Neo4j not configured. Phase 2 required.", 503
    return render_template('network.html', server_id=app.config['SERVER_ID'])


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=app.config['DEBUG'])
