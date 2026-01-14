"""
Vehicle Simulator Service
Simulates vehicle movement along calculated routes for shipments in transit.
"""
import threading
import time
import json
import math
from typing import Dict, Optional, Tuple
from datetime import datetime


class VehicleSimulator:
    """
    Manages simulated vehicle movements for shipments.
    Each shipment in IN_TRANSIT gets a simulated vehicle that travels along its route.
    """
    
    def __init__(self, kafka_producer, mongo_service, time_scale=100):
        """
        Args:
            kafka_producer: Kafka producer instance for sending location events
            mongo_service: MongoDB service for reading shipment data
            time_scale: Speed-up factor (100 = 100x faster, 1 = real-time)
        """
        self.kafka_producer = kafka_producer
        self.mongo_service = mongo_service
        self.time_scale = time_scale
        
        # Active simulations: tracking_number -> simulation_thread
        self.active_simulations: Dict[str, threading.Thread] = {}
        self.stop_flags: Dict[str, threading.Event] = {}
        
        # Lock for thread-safe operations
        self.lock = threading.Lock()
    
    def start_simulation(self, tracking_number: str, driver_id: str = None):
        """
        Start simulating vehicle movement for a shipment.
        
        Args:
            tracking_number: Shipment tracking number
            driver_id: Optional driver ID (defaults to tracking number)
        """
        with self.lock:
            # Check if already running
            if tracking_number in self.active_simulations:
                print(f"[Simulator] Already simulating {tracking_number}")
                return False
            
            # Get shipment data from MongoDB
            collection = self.mongo_service.get_collection('shipments')
            shipment = collection.find_one({'tracking_number': tracking_number})
            
            if not shipment:
                print(f"[Simulator] Shipment {tracking_number} not found")
                return False
            
            route = shipment.get('route')
            if not route or not route.get('locations'):
                print(f"[Simulator] No route for shipment {tracking_number}")
                return False
            
            # Generate vehicle_id
            vehicle_id = f"VEH-{tracking_number}"
            if not driver_id:
                driver_id = f"DRV-{tracking_number[-6:]}"
            
            # Create stop flag
            stop_flag = threading.Event()
            self.stop_flags[tracking_number] = stop_flag
            
            # Start simulation thread
            thread = threading.Thread(
                target=self._simulate_route,
                args=(tracking_number, vehicle_id, driver_id, route, stop_flag),
                daemon=True
            )
            thread.start()
            
            self.active_simulations[tracking_number] = thread
            print(f"✓ [Simulator] Started simulation for {tracking_number} (vehicle: {vehicle_id})")
            return True
    
    def stop_simulation(self, tracking_number: str):
        """
        Stop simulating vehicle movement for a shipment.
        Removes vehicle from tracking system immediately.
    
        Args:
            tracking_number: Shipment tracking number
        """
        vehicle_id = f"VEH-{tracking_number}"
    

        try:
            col = self.mongo_service.get_collection('vehicle_latest_locations')
            result = col.delete_one({'vehicle_id': vehicle_id})
            print(f"✓ [Simulator] Removed vehicle {vehicle_id} from DB (deleted {result.deleted_count} docs)")
        except Exception as e:
            print(f"[Simulator] Error removing vehicle from DB: {e}")
    
        with self.lock:
            if tracking_number not in self.active_simulations:
                print(f"[Simulator] No active simulation for {tracking_number} (already stopped or never started)")
                return True  # Still return True since vehicle was removed from DB
        
        
            self.stop_flags[tracking_number].set()
        
        
            del self.active_simulations[tracking_number]
            del self.stop_flags[tracking_number]
        
            print(f"✓ [Simulator] Stopped simulation thread for {tracking_number}")
            return True
    
    def _simulate_route(self, tracking_number: str, vehicle_id: str, 
                       driver_id: str, route: dict, stop_flag: threading.Event):
        """
        Simulate vehicle movement along route (runs in separate thread).
        
        Args:
            tracking_number: Shipment tracking number
            vehicle_id: Vehicle identifier
            driver_id: Driver identifier
            route: Route dictionary with locations and routes
            stop_flag: Event to signal when to stop
        """
        try:
            locations = route['locations']
            routes = route.get('routes', [])
            
            print(f"[Simulator] {vehicle_id} starting route with {len(locations)} locations")
            
            # Iterate through route segments
            for i in range(len(locations) - 1):
                if stop_flag.is_set():
                    print(f"[Simulator] {vehicle_id} stopped by flag")
                    return
                
                start_loc = locations[i]
                end_loc = locations[i + 1]
                
                # Get segment details if available
                segment = routes[i] if i < len(routes) else {}
                distance_km = segment.get('distance', 50)  # default 50km
                time_hours = segment.get('time', 1.0)  # default 1 hour
                
                # Simulate movement along segment
                self._simulate_segment(
                    vehicle_id, driver_id, tracking_number,
                    start_loc, end_loc, 
                    distance_km, time_hours,
                    stop_flag,
                    self.time_scale
                )
                
                if stop_flag.is_set():
                    return
            
            print(f"✓ [Simulator] {vehicle_id} completed route for {tracking_number}")
            
        except Exception as e:
            print(f"[Simulator] Error in simulation for {tracking_number}: {e}")
            import traceback
            traceback.print_exc()
    
    def _simulate_segment(self, vehicle_id: str, driver_id: str, 
                         tracking_number: str, start_loc: dict, end_loc: dict,
                         distance_km: float, time_hours: float, stop_flag: threading.Event,
                         time_scale: int = 100):
        """
        Simulate movement between two locations with realistic GPS updates.
        
        Args:
            vehicle_id: Vehicle identifier
            driver_id: Driver identifier
            tracking_number: Shipment tracking number
            start_loc: Starting location dict with lat/lng
            end_loc: Ending location dict with lat/lng
            distance_km: Distance of segment in km
            time_hours: Expected travel time in hours
            stop_flag: Event to signal when to stop
            time_scale: Speed-up factor (100 = 100x faster)
        """
        # Extract coordinates
        start_lat = start_loc.get('lat', start_loc.get('latitude', 45.0))
        start_lng = start_loc.get('lng', start_loc.get('longitude', 14.0))
        end_lat = end_loc.get('lat', end_loc.get('latitude', 45.5))
        end_lng = end_loc.get('lng', end_loc.get('longitude', 15.0))
        
        # Calculate real duration and accelerated duration
        real_duration_seconds = time_hours * 3600  # Real-world time
        simulated_duration_seconds = real_duration_seconds / time_scale  # Accelerated time
        
        # GPS update interval (keep at 3 seconds for smooth animation)
        update_interval = 3.0
        
        # Calculate number of steps based on simulated duration
        num_steps = int(simulated_duration_seconds / update_interval)
        num_steps = max(5, min(num_steps, 200))  # between 5 and 200 steps
        
        # Recalculate actual interval to match simulated duration
        actual_interval = simulated_duration_seconds / num_steps
        
        print(f"[Simulator] {vehicle_id}: {start_loc['city']} → {end_loc['city']}")
        print(f"            {distance_km:.1f}km, {time_hours:.2f}h real-time → {simulated_duration_seconds:.1f}s simulated ({time_scale}x faster)")
        print(f"            {num_steps} steps, {actual_interval:.2f}s interval")
        
        for step in range(num_steps + 1):
            if stop_flag.is_set():
                return
            
            # Linear interpolation
            progress = step / num_steps
            current_lat = start_lat + (end_lat - start_lat) * progress
            current_lng = start_lng + (end_lng - start_lng) * progress
            
            # Add small random variation for realism
            import random
            current_lat += random.uniform(-0.001, 0.001)
            current_lng += random.uniform(-0.001, 0.001)
            
            # Send GPS event to Kafka
            event = {
                'vehicle_id': vehicle_id,
                'driver_id': driver_id,
                'tracking_number': tracking_number,
                'lat': round(current_lat, 6),
                'lng': round(current_lng, 6),
                'ts': datetime.utcnow().isoformat(),
                'segment': f"{start_loc['city']}-{end_loc['city']}",
                'progress': round(progress * 100, 1),
                'real_time_hours': time_hours,
                'time_scale': time_scale
            }
            
            try:
                self.kafka_producer.send(
                    'vehicle-location-events',
                    key=vehicle_id.encode('utf-8'),
                    value=json.dumps(event).encode('utf-8')
                )
                self.kafka_producer.flush()
            except Exception as e:
                print(f"[Simulator] Kafka send error: {e}")
            
            # Wait before next update
            time.sleep(actual_interval)
    
    def get_active_simulations(self) -> list:
        """Get list of currently active simulations"""
        with self.lock:
            return list(self.active_simulations.keys())
    
    def stop_all(self):
        """Stop all active simulations"""
        with self.lock:
            tracking_numbers = list(self.active_simulations.keys())
        
        for tn in tracking_numbers:
            self.stop_simulation(tn)
        
        print(f"[Simulator] Stopped all {len(tracking_numbers)} simulations")