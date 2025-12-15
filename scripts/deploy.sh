#!/bin/bash

set -e

echo "=================================================="
echo "  Delivery Logistics - Deployment Script"
echo "=================================================="

# Provjera Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker nije instaliran!"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose nije instaliran!"
    exit 1
fi

# Idi u root direktorij projekta
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Zaustavi postojeće kontejnere
echo ""
echo "[1/8] Zaustavljam postojeće kontejnere..."
cd phase1 2>/dev/null && docker-compose down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase2 2>/dev/null && docker-compose -f docker-compose.phase2.yml down -v 2>/dev/null || true
cd "$PROJECT_ROOT"

docker rm -f phase1_nginx phase1_web1 phase1_web2 phase1_web3 \
             phase1_mongo_primary phase1_mongo_secondary1 phase1_mongo_secondary2 \
             phase1_mongo_init phase2_nginx phase2_web1 phase2_web2 phase2_web3 \
             phase2_mongo_primary phase2_mongo_secondary1 phase2_mongo_secondary2 \
             phase2_neo4j 2>/dev/null || true

# Pokreni MongoDB servise
echo ""
echo "[2/8] Pokrećem MongoDB servise..."
cd "$PROJECT_ROOT/phase2"
docker-compose -f docker-compose.phase2.yml up -d mongo-primary mongo-secondary1 mongo-secondary2

# Čekaj MongoDB
echo ""
echo "[3/8] Čekam MongoDB (15 sekundi)..."
sleep 15

# Inicijaliziraj MongoDB replica set
echo ""
echo "[4/8] Inicijaliziram MongoDB replica set..."
docker exec phase2_mongo_primary mongosh --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
});
' || true

sleep 10

# Provjeri MongoDB status
echo ""
echo "[5/8] Provjeravam MongoDB status..."
docker exec phase2_mongo_primary mongosh --eval 'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr));' || true

# Pokreni Neo4j
echo ""
echo "[6/8] Pokrećem Neo4j..."
docker-compose -f docker-compose.phase2.yml up -d neo4j

echo "Čekam Neo4j (20 sekundi)..."
sleep 20

# Inicijaliziraj Neo4j mrežu
echo ""
echo "[7/8] Inicijaliziram Neo4j mrežu..."
# Postavi permisije na neo4j direktorij
sudo chown -R $USER:$USER neo4j/ 2>/dev/null || true

docker exec -i phase2_neo4j cypher-shell -u neo4j -p deliverypass123 < neo4j/import/init-network.cypher

# Pokreni sve servise
echo ""
echo "[8/8] Pokrećem web servise i nginx..."
docker-compose -f docker-compose.phase2.yml up -d --build

# Provjeri status
echo ""
echo "=================================================="
echo "  Status servisa:"
echo "=================================================="
docker-compose -f docker-compose.phase2.yml ps

echo ""
echo "=================================================="
echo "  Deployment završen!"
echo "=================================================="
echo ""
echo "Pristup:"
echo "  - Web aplikacija: http://localhost"
echo "  - Neo4j Browser:  http://localhost:7474"
echo "  - MongoDB:        localhost:27017"
echo ""
echo "Provjera logova: docker-compose -f docker-compose.phase2.yml logs -f"
echo "Zaustavljanje:   docker-compose -f docker-compose.phase2.yml down"
echo ""