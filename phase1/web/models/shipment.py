from datetime import datetime
import random
import string

class Shipment:
    """Model for shipment documents"""
    
    STATUSES = ['CREATED', 'IN_WAREHOUSE', 'IN_TRANSIT', 'DELIVERED']
    
    def __init__(self, sender, receiver, weight, products, pickup_address, delivery_address):
        self.tracking_number = self._generate_tracking_number()
        self.status = 'CREATED'
        self.sender = sender
        self.receiver = receiver
        self.weight = weight
        self.products = products
        self.pickup_address = pickup_address
        self.delivery_address = delivery_address
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.status_history = [{
            'status': 'CREATED',
            'timestamp': self.created_at,
            'note': 'Shipment created'
        }]
    
    @staticmethod
    def _generate_tracking_number():
        """Generate unique tracking number"""
        prefix = 'DLV'
        random_part = ''.join(random.choices(string.digits, k=9))
        return f"{prefix}{random_part}"
    
    def to_dict(self):
        """Convert shipment to dictionary"""
        return {
            'tracking_number': self.tracking_number,
            'status': self.status,
            'sender': self.sender,
            'receiver': self.receiver,
            'weight': self.weight,
            'products': self.products,
            'pickup_address': self.pickup_address,
            'delivery_address': self.delivery_address,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
            'status_history': self.status_history
        }
    
    @staticmethod
    def from_dict(data):
        """Create shipment from dictionary"""
        shipment = Shipment(
            sender=data.get('sender'),
            receiver=data.get('receiver'),
            weight=data.get('weight'),
            products=data.get('products', []),
            pickup_address=data.get('pickup_address'),
            delivery_address=data.get('delivery_address')
        )
        
        # Override auto-generated fields if they exist in data
        if 'tracking_number' in data:
            shipment.tracking_number = data['tracking_number']
        if 'status' in data:
            shipment.status = data['status']
        if 'created_at' in data:
            shipment.created_at = data['created_at']
        if 'updated_at' in data:
            shipment.updated_at = data['updated_at']
        if 'status_history' in data:
            shipment.status_history = data['status_history']
        
        return shipment
    
    def update_status(self, new_status, note=''):
        """Update shipment status"""
        if new_status not in self.STATUSES:
            raise ValueError(f"Invalid status: {new_status}")
        
        self.status = new_status
        self.updated_at = datetime.utcnow()
        self.status_history.append({
            'status': new_status,
            'timestamp': self.updated_at,
            'note': note or f'Status changed to {new_status}'
        })
    
    @staticmethod
    def validate_data(data):
        """Validate shipment data"""
        required_fields = ['sender', 'receiver', 'weight', 'pickup_address', 'delivery_address']
        
        for field in required_fields:
            if field not in data:
                return False, f"Missing required field: {field}"
        
        # Validate sender
        if not isinstance(data['sender'], dict) or 'name' not in data['sender']:
            return False, "Invalid sender data"
        
        # Validate receiver
        if not isinstance(data['receiver'], dict) or 'name' not in data['receiver']:
            return False, "Invalid receiver data"
        
        # Validate weight
        try:
            weight = float(data['weight'])
            if weight <= 0:
                return False, "Weight must be positive"
        except (ValueError, TypeError):
            return False, "Invalid weight value"
        
        return True, None