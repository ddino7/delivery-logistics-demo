from flask import Flask, render_template, jsonify
from config import Config
from services.mongodb_service import MongoDBService
from routes.shipments import shipments_bp
from routes.tracking import tracking_bp
import time

app = Flask(__name__)
app.config.from_object(Config)


db_service = MongoDBService(app.config['MONGO_URI'], app.config['MONGO_DB_NAME'])


app.db_service = db_service


app.register_blueprint(shipments_bp, url_prefix='/api/shipments')
app.register_blueprint(tracking_bp, url_prefix='/api/tracking')

@app.route('/')
def index():
    """Main page"""
    return render_template('index.html', server_id=app.config['SERVER_ID'])

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        
        db_service.get_collection('shipments').find_one()
        db_status = 'healthy'
    except Exception as e:
        db_status = f'unhealthy: {str(e)}'
    
    return jsonify({
        'status': 'healthy' if db_status == 'healthy' else 'unhealthy',
        'server_id': app.config['SERVER_ID'],
        'database': db_status,
        'timestamp': time.time()
    })

@app.route('/create')
def create_page():
    """Page for creating shipments"""
    return render_template('create_shipment.html', server_id=app.config['SERVER_ID'])

@app.route('/track')
def track_page():
    """Page for tracking shipments"""
    return render_template('tracking.html', server_id=app.config['SERVER_ID'])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=app.config['DEBUG'])