from neo4j import GraphDatabase
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)

class Neo4jService:
    def __init__(self, uri: str, user: str, password: str):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))
        logger.info(f"Neo4j service initialized: {uri}")
    
    def close(self):
        self.driver.close()
    
    def get_network_statistics(self) -> Dict:
        """Get network statistics"""
        with self.driver.session() as session:
            result = session.run("""
                MATCH (dc:DistributionCenter)
                WITH count(dc) as dcCount
                MATCH (wh:Warehouse)
                WITH dcCount, count(wh) as whCount
                MATCH ()-[r:ROUTE]->()
                RETURN dcCount as distribution_centers,
                       whCount as warehouses,
                       count(r) as routes
            """)
            record = result.single()
            if record:
                return {
                    'distribution_centers': record['distribution_centers'],
                    'warehouses': record['warehouses'],
                    'routes': record['routes'],
                    'total_locations': record['distribution_centers'] + record['warehouses']
                }
            return {'distribution_centers': 0, 'warehouses': 0, 'routes': 0, 'total_locations': 0}
    
    def get_all_locations(self) -> List[Dict]:
        """Get all distribution centers and warehouses"""
        with self.driver.session() as session:
            result = session.run("""
                MATCH (n)
                WHERE n:DistributionCenter OR n:Warehouse
                RETURN n.id as id,
                       n.name as name,
                       n.city as city,
                       n.address as address,
                       labels(n)[0] as type,
                       n.capacity as capacity,
                       n.lat as lat,
                       n.lon as lon
                ORDER BY n.city
            """)
            return [dict(record) for record in result]
    
    def get_network_graph(self) -> Dict:
        """Get complete network graph for visualization"""
        with self.driver.session() as session:
            # Get nodes
            nodes_result = session.run("""
                MATCH (n)
                WHERE n:DistributionCenter OR n:Warehouse
                RETURN n.id as id,
                       n.name as name,
                       n.city as city,
                       labels(n)[0] as type,
                       n.lat as lat,
                       n.lon as lon
            """)
            nodes = [dict(record) for record in nodes_result]
            
            # Get edges
            edges_result = session.run("""
                MATCH (a)-[r:ROUTE]->(b)
                WHERE r.active = true
                RETURN a.id as source,
                       b.id as target,
                       r.distance_km as distance,
                       r.avg_time_hours as time,
                       r.cost_per_km as cost_per_km,
                       r.road_type as road_type
            """)
            edges = [dict(record) for record in edges_result]
            
            return {'nodes': nodes, 'edges': edges}
    
    def find_city_location(self, city: str) -> Optional[str]:
        """Find location ID by city name"""
        with self.driver.session() as session:
            result = session.run("""
                MATCH (n)
                WHERE (n:DistributionCenter OR n:Warehouse)
                  AND toLower(n.city) = toLower($city)
                RETURN n.id as id
                LIMIT 1
            """, city=city)
            record = result.single()
            return record['id'] if record else None
    
    def calculate_optimal_route(self, origin_city: str, destination_city: str, 
                               optimization: str = 'distance') -> Dict:
        """
        Calculate optimal route between two cities
        
        Args:
            origin_city: Starting city
            destination_city: Destination city
            optimization: 'distance', 'time', or 'cost'
        
        Returns:
            Dict with route details including path, total distance, time, and cost
        """
        # Map optimization to relationship property
        weight_property = {
            'distance': 'distance_km',
            'time': 'avg_time_hours',
            'cost': 'cost_per_km'
        }.get(optimization, 'distance_km')
        
        with self.driver.session() as session:
            result = session.run(f"""
                MATCH (start), (end)
                WHERE (start:DistributionCenter OR start:Warehouse)
                  AND (end:DistributionCenter OR end:Warehouse)
                  AND toLower(start.city) = toLower($origin)
                  AND toLower(end.city) = toLower($destination)
                
                CALL {{
                    WITH start, end
                    MATCH path = shortestPath((start)-[:ROUTE*]-(end))
                    WHERE all(r IN relationships(path) WHERE r.active = true)
                    RETURN path,
                           reduce(dist = 0, r IN relationships(path) | dist + r.distance_km) as total_distance,
                           reduce(time = 0, r IN relationships(path) | time + r.avg_time_hours) as total_time,
                           reduce(cost = 0, r IN relationships(path) | cost + r.distance_km * r.cost_per_km) as total_cost
                    ORDER BY CASE
                        WHEN '{optimization}' = 'distance' THEN total_distance
                        WHEN '{optimization}' = 'time' THEN total_time
                        WHEN '{optimization}' = 'cost' THEN total_cost
                        ELSE total_distance
                    END
                    LIMIT 1
                }}
                
                WITH path, total_distance, total_time, total_cost,
                     [node IN nodes(path) | {{
                         id: node.id,
                         name: node.name,
                         city: node.city,
                         type: labels(node)[0]
                     }}] as locations,
                     [rel IN relationships(path) | {{
                         distance_km: rel.distance_km,
                         time_hours: rel.avg_time_hours,
                         cost: rel.distance_km * rel.cost_per_km,
                         road_type: rel.road_type
                     }}] as segments
                
                RETURN locations,
                       segments,
                       total_distance,
                       total_time,
                       total_cost,
                       size(locations) - 1 as stops
            """, origin=origin_city, destination=destination_city, optimization=optimization)
            
            record = result.single()
            if not record:
                return {
                    'found': False,
                    'error': f'No route found between {origin_city} and {destination_city}'
                }
            
            return {
                'found': True,
                'origin': origin_city,
                'destination': destination_city,
                'optimization': optimization,
                'route': {
                    'locations': record['locations'],
                    'segments': record['segments'],
                    'total_distance_km': round(record['total_distance'], 2),
                    'total_time_hours': round(record['total_time'], 2),
                    'total_cost': round(record['total_cost'], 2),
                    'stops': record['stops']
                }
            }
    
    def calculate_route_for_shipment(self, shipment: Dict, optimization: str = 'distance') -> Dict:
        """
        Calculate optimal route for a shipment based on sender and receiver cities
        
        Args:
            shipment: Shipment dict from MongoDB with sender/receiver info
            optimization: 'distance', 'time', or 'cost'
        """
        sender_city = shipment.get('sender', {}).get('city', '')
        receiver_city = shipment.get('receiver', {}).get('city', '')
        
        if not sender_city or not receiver_city:
            return {
                'found': False,
                'error': 'Missing sender or receiver city in shipment'
            }
        
        route_result = self.calculate_optimal_route(sender_city, receiver_city, optimization)
        
        if route_result['found']:
            route_result['shipment_tracking_number'] = shipment.get('tracking_number')
            route_result['weight_kg'] = shipment.get('weight', 0)
            
        return route_result
    
    def get_routes_from_location(self, location_id: str) -> List[Dict]:
        """Get all routes from a specific location"""
        with self.driver.session() as session:
            result = session.run("""
                MATCH (start {id: $location_id})-[r:ROUTE]->(end)
                WHERE r.active = true
                RETURN end.id as destination_id,
                       end.name as destination_name,
                       end.city as destination_city,
                       labels(end)[0] as destination_type,
                       r.distance_km as distance,
                       r.avg_time_hours as time,
                       r.cost_per_km as cost_per_km,
                       r.road_type as road_type
                ORDER BY r.distance_km
            """, location_id=location_id)
            return [dict(record) for record in result]
    
    def get_all_cities(self) -> List[str]:
        """Get list of all available cities"""
        with self.driver.session() as session:
            result = session.run("""
                MATCH (n)
                WHERE n:DistributionCenter OR n:Warehouse
                RETURN DISTINCT n.city as city
                ORDER BY n.city
            """)
            return [record['city'] for record in result]