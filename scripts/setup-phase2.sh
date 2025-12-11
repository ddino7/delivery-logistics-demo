#!/bin/bash

echo "=== Setting up Phase 2: Logistics Network with Neo4j ==="
echo ""


cd phase2


echo "1. Creating directory structure..."
mkdir -p neo4j/import neo4j/conf
mkdir -p web-extensions/models web-extensions/routes web-extensions/services web-extensions/templates


echo ""
echo "2. Stopping Phase 1 containers..."
cd ../phase1
docker-compose down


echo ""
echo "3. Starting Phase 2 services..."
cd ../phase2
docker-compose -f docker-compose.phase2.yml up -d mongo-primary mongo-secondary1 mongo-secondary2


echo ""
echo "4. Waiting for MongoDB to be ready..."
sleep 10


echo ""
echo "5. Initializing MongoDB replica set..."
docker exec phase2_mongo_primary mongosh --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
});
'

echo ""
echo "Waiting for replica set to stabilize..."
sleep 10


echo ""
echo "6. Starting Neo4j..."
docker-compose -f docker-compose.phase2.yml up -d neo4j

echo ""
echo "Waiting for Neo4j to be ready..."
sleep 15


echo ""
echo "7. Initializing Neo4j logistics network..."
docker exec -i phase2_neo4j cypher-shell -u neo4j -p deliverypass123 < neo4j/import/init-network.cypher


echo ""
echo "8. Starting web servers and load balancer..."
docker-compose -f docker-compose.phase2.yml up -d


echo ""
echo "9. Waiting for all services to be ready..."
sleep 10


echo ""
echo "10. Checking service status..."
docker-compose -f docker-compose.phase2.yml ps


echo ""
echo "11. Testing endpoints..."
echo ""
echo "MongoDB Status:"
docker exec phase2_mongo_primary mongosh --eval 'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr));'

echo ""
echo "Neo4j Status:"
docker exec phase2_neo4j cypher-shell -u neo4j -p deliverypass123 "MATCH (n) RETURN labels(n)[0] as Type, count(n) as Count"

echo ""
echo "Web Service Health:"
curl -s http://localhost/health | python3 -m json.tool

echo ""
echo "=== Phase 2 Setup Complete! ==="
echo ""
echo "Available endpoints:"
echo "  - Web UI: http://localhost"
echo "  - Neo4j Browser: http://localhost:7474"
echo "  - API Docs: http://localhost/api/network/statistics"
echo ""
echo "Test commands:"
echo "  curl http://localhost/api/network/locations"
echo "  curl 'http://localhost/api/network/routes?from=Zagreb&to=Split'"
echo ""