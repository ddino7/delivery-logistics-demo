from neo4j import GraphDatabase
import time

class Neo4jService:
    """Service for Neo4j graph database operations"""
    
    def __init__(self, uri, user, password, max_retries=5, retry_delay=2):
        self.uri = uri
        self.user = user
        self.password = password
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self.driver = None
        self._connect()
    
    def _connect(self):
        """Connect to Neo4j with retry logic"""
        for attempt in range(self.max_retries):
            try:
                print(f"Attempting to connect to Neo4j (attempt {attempt + 1}/{self.max_retries})...")
                self.driver = GraphDatabase.driver(self.uri, auth=(self.user, self.password))
                with self.driver.session() as session:
                    session.run("RETURN 1")
                print(f"✓ Successfully connected to Neo4j")
                return
            except Exception as e:
                print(f"✗ Connection attempt {attempt + 1} failed: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay)
                else:
                    print("⚠ Warning: Could not connect to Neo4j. Graph features will be unavailable.")
                    self.driver = None
    
    def close(self):
        if self.driver:
            self.driver.close()
    
    def get_all_locations(self):
        if not self.driver:
            return []
        query = """
        MATCH (n)
        WHERE n:DistributionCenter OR n:Warehouse
        RETURN n.id as id, n.name as name, n.city as city, 
               n.type as type, n.capacity as capacity,
               n.lat as lat, n.lon as lon,
               labels(n)[0] as node_type
        ORDER BY n.city
        """
        with self.driver.session() as session:
            result = session.run(query)
            return [dict(record) for record in result]
    
    def get_location_by_id(self, location_id):
        if not self.driver:
            return None
        query = """
        MATCH (n)
        WHERE (n:DistributionCenter OR n:Warehouse) AND n.id = $id
        RETURN n.id as id, n.name as name, n.city as city,
               n.address as address, n.type as type, 
               n.capacity as capacity, n.lat as lat, n.lon as lon,
               labels(n)[0] as node_type
        """
        with self.driver.session() as session:
            result = session.run(query, id=location_id)
            record = result.single()
            return dict(record) if record else None
    
    def get_location_by_city(self, city):
        if not self.driver:
            return []
        query = """
        MATCH (n)
        WHERE (n:DistributionCenter OR n:Warehouse) AND n.city = $city
        RETURN n.id as id, n.name as name, n.city as city,
               n.type as type, n.capacity as capacity,
               labels(n)[0] as node_type
        """
        with self.driver.session() as session:
            result = session.run(query, city=city)
            return [dict(record) for record in result]
    
    def get_routes_from_location(self, location_id):
        if not self.driver:
            return []
        query = """
        MATCH (start)-[r:ROUTE]->(end)
        WHERE start.id = $location_id
        RETURN start.id as from_id, start.name as from_name, start.city as from_city,
               end.id as to_id, end.name as to_name, end.city as to_city,
               r.distance_km as distance, r.avg_time_hours as time,
               r.cost_per_km as cost_per_km, r.road_type as road_type
        """
        with self.driver.session() as session:
            result = session.run(query, location_id=location_id)
            return [dict(record) for record in result]
    
    def find_shortest_path(self, from_city, to_city, optimize_by='distance'):
        if not self.driver:
            return None
        query = """
        MATCH (start), (end)
        WHERE (start:DistributionCenter OR start:Warehouse) AND start.city = $from_city
          AND (end:DistributionCenter OR end:Warehouse) AND end.city = $to_city
        MATCH path = shortestPath((start)-[:ROUTE*]-(end))
        WITH path, 
             reduce(dist = 0, r in relationships(path) | dist + r.distance_km) as total_distance,
             reduce(time = 0, r in relationships(path) | time + r.avg_time_hours) as total_time,
             reduce(cost = 0, r in relationships(path) | cost + r.distance_km * r.cost_per_km) as total_cost
        RETURN 
            [n in nodes(path) | {id: n.id, name: n.name, city: n.city, type: labels(n)[0]}] as locations,
            [r in relationships(path) | {distance: r.distance_km, time: r.avg_time_hours, road_type: r.road_type}] as routes,
            total_distance,
            total_time,
            total_cost
        ORDER BY 
            CASE $optimize_by
                WHEN 'distance' THEN total_distance
                WHEN 'time' THEN total_time
                WHEN 'cost' THEN total_cost
                ELSE total_distance
            END
        LIMIT 1
        """
        with self.driver.session() as session:
            result = session.run(query, from_city=from_city, to_city=to_city, optimize_by=optimize_by)
            record = result.single()
            if not record:
                return None
            return {
                'locations': record['locations'],
                'routes': record['routes'],
                'total_distance_km': round(record['total_distance'], 2),
                'total_time_hours': round(record['total_time'], 2),
                'total_cost_eur': round(record['total_cost'], 2),
                'optimize_by': optimize_by
            }
    
    def get_network_statistics(self):
        if not self.driver:
            return {}
        query = """
        MATCH (dc:DistributionCenter)
        WITH count(dc) as dcCount
        MATCH (wh:Warehouse)
        WITH dcCount, count(wh) as whCount
        MATCH ()-[r:ROUTE]->()
        WITH dcCount, whCount, count(r) as routeCount,
             sum(r.distance_km) as totalDistance,
             avg(r.distance_km) as avgDistance
        RETURN dcCount as distribution_centers,
               whCount as warehouses,
               routeCount as total_routes,
               round(totalDistance, 2) as total_network_distance_km,
               round(avgDistance, 2) as avg_route_distance_km
        """
        with self.driver.session() as session:
            result = session.run(query)
            record = result.single()
            return dict(record) if record else {}