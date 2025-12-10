import os

class Config:
    """Application configuration"""
    
    # Flask
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    DEBUG = os.environ.get('FLASK_ENV') == 'development'
    
    # MongoDB
    MONGO_URI = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/?replicaSet=rs0')
    MONGO_DB_NAME = 'delivery_system'
    
    # Server identification
    SERVER_ID = os.environ.get('SERVER_ID', 'unknown')
    
    # Application settings
    TRACKING_NUMBER_PREFIX = 'DLV'
    TRACKING_NUMBER_LENGTH = 12