from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
import time

class MongoDBService:
    """Service for MongoDB operations with replica set support"""
    
    def __init__(self, mongo_uri, db_name, max_retries=5, retry_delay=2):
        self.mongo_uri = mongo_uri
        self.db_name = db_name
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self.client = None
        self.db = None
        self._connect()
    
    def _connect(self):
        """Connect to MongoDB with retry logic"""
        for attempt in range(self.max_retries):
            try:
                print(f"Attempting to connect to MongoDB (attempt {attempt + 1}/{self.max_retries})...")
                self.client = MongoClient(
                    self.mongo_uri,
                    serverSelectionTimeoutMS=5000,
                    connectTimeoutMS=5000,
                    retryWrites=True,
                    w='majority'  # Write concern for replica set
                )
                # Test connection
                self.client.admin.command('ping')
                self.db = self.client[self.db_name]
                print(f"✓ Successfully connected to MongoDB: {self.db_name}")
                self._create_indexes()
                return
            except (ConnectionFailure, OperationFailure) as e:
                print(f"✗ Connection attempt {attempt + 1} failed: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay)
                else:
                    raise Exception(f"Failed to connect to MongoDB after {self.max_retries} attempts")
    
    def _create_indexes(self):
        """Create necessary indexes"""
        try:
            # Shipments collection indexes
            shipments = self.db['shipments']
            shipments.create_index('tracking_number', unique=True)
            shipments.create_index('status')
            shipments.create_index('created_at')
            shipments.create_index('receiver.name')
            
            # Suppliers collection indexes
            suppliers = self.db['suppliers']
            suppliers.create_index('name')
            
            print("✓ Database indexes created")
        except Exception as e:
            print(f"Warning: Could not create indexes: {e}")
    
    def get_collection(self, collection_name):
        """Get a collection from the database"""
        if self.db is None:
            self._connect()
        return self.db[collection_name]
    
    def close(self):
        """Close the MongoDB connection"""
        if self.client:
            self.client.close()
            print("✓ MongoDB connection closed")