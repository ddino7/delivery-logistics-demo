from datetime import datetime
import random
import string


class Shipment:
    """Model for shipment documents"""

    STATUSES = ['CREATED', 'IN_WAREHOUSE', 'IN_TRANSIT', 'DELIVERED']

    def __init__(self, sender, receiver, weight, products,
                 pickup_address, delivery_address):
        self.tracking_number  = self._generate_tracking_number()
        self.status           = 'CREATED'
        self.sender           = sender
        self.receiver         = receiver
        self.weight           = weight
        self.products         = products
        self.pickup_address   = pickup_address
        self.delivery_address = delivery_address
        self.created_at       = datetime.utcnow()
        self.updated_at       = datetime.utcnow()
        self.status_history   = [{
            'status':    'CREATED',
            'timestamp': self.created_at,
            'note':      'Shipment created'
        }]

        # ── Phase 4 fields (populated after creation) ──────────────────────────

        # Planned departure chosen by dispatcher
        self.planned_departure_at    = None   # datetime
        self.planned_departure_month = None   # int 1-12
        self.planned_departure_hour  = None   # int 0-23
        self.is_weekend              = None   # bool
        self.is_holiday              = None   # bool
        self.holiday_name            = None   # str or None

        # Real-world weather conditions at departure time
        # source: "openmeteo_forecast" | "openmeteo_historical" | "manual"
        self.weather_at_departure = {
            "source":               "unknown",
            "max_precipitation_mm": None,
            "max_windspeed_kmh":    None,
            "min_visibility_m":     None,
            "max_weather_code":     None,
            "bad_weather_nodes":    None,
            "avg_temperature_c":    None,
            "fetched_at":           None
        }

        # Traffic & road context
        self.traffic_load_factor  = None   # float — from HAC data
        self.night_driving_ratio  = None   # float 0.0–1.0
        self.is_dark_departure    = None   # bool

        # ML risk prediction (filled in by ml_service once model is trained)
        self.ml_prediction = {
            "risk_score":       None,   # float 0.0–1.0
            "prediction":       None,   # "DELAYED" | "ON_TIME"
            "risk_level":       None,   # "LOW" | "MEDIUM" | "HIGH"
            "confidence":       None,
            "top_risk_factors": [],
            "model_version":    None,
            "predicted_at":     None
        }

    # ── Class methods ──────────────────────────────────────────────────────────

    @staticmethod
    def _generate_tracking_number():
        prefix = 'DLV'
        random_part = ''.join(random.choices(string.digits, k=9))
        return f"{prefix}{random_part}"

    def to_dict(self):
        """Convert shipment to dictionary for MongoDB insertion."""
        d = {
            'tracking_number':  self.tracking_number,
            'status':           self.status,
            'sender':           self.sender,
            'receiver':         self.receiver,
            'weight':           self.weight,
            'products':         self.products,
            'pickup_address':   self.pickup_address,
            'delivery_address': self.delivery_address,
            'created_at':       self.created_at,
            'updated_at':       self.updated_at,
            'status_history':   self.status_history,

            # Phase 4 — departure context
            'planned_departure_at':    self.planned_departure_at,
            'planned_departure_month': self.planned_departure_month,
            'planned_departure_hour':  self.planned_departure_hour,
            'is_weekend':              self.is_weekend,
            'is_holiday':              self.is_holiday,
            'holiday_name':            self.holiday_name,

            # Phase 4 — weather
            'weather_at_departure':    self.weather_at_departure,

            # Phase 4 — traffic / night driving
            'traffic_load_factor':     self.traffic_load_factor,
            'night_driving_ratio':     self.night_driving_ratio,
            'is_dark_departure':       self.is_dark_departure,

            # Phase 4 — ML prediction
            'ml_prediction':           self.ml_prediction,
        }
        return d

    @staticmethod
    def from_dict(data):
        """Reconstruct a Shipment from a MongoDB document."""
        shipment = Shipment(
            sender=data.get('sender'),
            receiver=data.get('receiver'),
            weight=data.get('weight'),
            products=data.get('products', []),
            pickup_address=data.get('pickup_address'),
            delivery_address=data.get('delivery_address')
        )

        for field in ('tracking_number', 'status', 'created_at',
                      'updated_at', 'status_history'):
            if field in data:
                setattr(shipment, field, data[field])

        # Phase 4 fields
        for field in ('planned_departure_at', 'planned_departure_month',
                      'planned_departure_hour', 'is_weekend',
                      'is_holiday', 'holiday_name',
                      'weather_at_departure', 'traffic_load_factor',
                      'night_driving_ratio', 'is_dark_departure',
                      'ml_prediction'):
            if field in data:
                setattr(shipment, field, data[field])

        return shipment

    def set_departure_context(self, departure_dt: datetime,
                               is_holiday: bool, holiday_name: str | None):
        """Populate departure-related fields from a datetime object."""
        self.planned_departure_at    = departure_dt
        self.planned_departure_month = departure_dt.month
        self.planned_departure_hour  = departure_dt.hour
        self.is_weekend              = departure_dt.weekday() >= 5
        self.is_holiday              = is_holiday
        self.holiday_name            = holiday_name

    def set_weather(self, weather_dict: dict, source: str, fetched_at: datetime = None):
        """Populate weather fields from weather_service output."""
        self.weather_at_departure = {
            "source":               source,
            "max_precipitation_mm": weather_dict.get("max_precipitation_mm"),
            "max_windspeed_kmh":    weather_dict.get("max_windspeed_kmh"),
            "min_visibility_m":     weather_dict.get("min_visibility_m"),
            "max_weather_code":     weather_dict.get("max_weather_code"),
            "bad_weather_nodes":    weather_dict.get("bad_weather_nodes"),
            "avg_temperature_c":    weather_dict.get("avg_temperature_c"),
            "fetched_at":           fetched_at or datetime.utcnow()
        }

    def set_traffic_context(self, traffic_load_factor: float,
                             night_ratio: float, is_dark: bool):
        self.traffic_load_factor = traffic_load_factor
        self.night_driving_ratio = night_ratio
        self.is_dark_departure   = is_dark

    def update_status(self, new_status, note=''):
        """Update shipment status."""
        if new_status not in self.STATUSES:
            raise ValueError(f"Invalid status: {new_status}")
        self.status     = new_status
        self.updated_at = datetime.utcnow()
        self.status_history.append({
            'status':    new_status,
            'timestamp': self.updated_at,
            'note':      note or f'Status changed to {new_status}'
        })

    @staticmethod
    def validate_data(data):
        """Validate incoming request data."""
        required_fields = ['sender', 'receiver', 'weight',
                           'pickup_address', 'delivery_address']
        for field in required_fields:
            if field not in data:
                return False, f"Missing required field: {field}"

        if not isinstance(data['sender'], dict) or 'name' not in data['sender']:
            return False, "Invalid sender data"

        if not isinstance(data['receiver'], dict) or 'name' not in data['receiver']:
            return False, "Invalid receiver data"

        try:
            weight = float(data['weight'])
            if weight <= 0:
                return False, "Weight must be positive"
        except (ValueError, TypeError):
            return False, "Invalid weight value"

        return True, None