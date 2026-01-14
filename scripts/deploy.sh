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
echo "[1/9] Zaustavljam postojeće kontejnere..."
cd phase1 2>/dev/null && docker-compose down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase2 2>/dev/null && docker-compose -f docker-compose.phase2.yml down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase3 2>/dev/null && docker-compose -f docker-compose.phase3.yml down -v 2>/dev/null || true
cd "$PROJECT_ROOT"

docker rm -f phase1_nginx phase1_web1 phase1_web2 phase1_web3 \
             phase1_mongo_primary phase1_mongo_secondary1 phase1_mongo_secondary2 \
             phase1_mongo_init phase2_nginx phase2_web1 phase2_web2 phase2_web3 \
             phase2_mongo_primary phase2_mongo_secondary1 phase2_mongo_secondary2 \
             phase2_neo4j phase3_* 2>/dev/null || true

# Pokreni MongoDB servise
echo ""
echo "[2/9] Pokrećem MongoDB servise..."
cd "$PROJECT_ROOT/phase2"
docker-compose -f docker-compose.phase2.yml up -d mongo-primary mongo-secondary1 mongo-secondary2

# Čekaj MongoDB
echo ""
echo "[3/9] Čekam MongoDB (15 sekundi)..."
sleep 15

# Inicijaliziraj MongoDB replica set
echo ""
echo "[4/9] Inicijaliziram MongoDB replica set..."
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
echo "[5/9] Provjeravam MongoDB status..."
docker exec phase2_mongo_primary mongosh --eval 'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr));' || true

# Pokreni Neo4j
echo ""
echo "[6/9] Pokrećem Neo4j..."
cd "$PROJECT_ROOT/phase2"
docker-compose -f docker-compose.phase2.yml up -d neo4j

echo "Čekam Neo4j (20 sekundi)..."
sleep 20

# Inicijaliziraj Neo4j mrežu
echo ""
echo "[7/9] Inicijaliziram Neo4j mrežu..."
# Postavi permisije na neo4j direktorij
sudo chown -R $USER:$USER "$PROJECT_ROOT/phase2/neo4j/" 2>/dev/null || true

docker exec -i phase2_neo4j cypher-shell -u neo4j -p deliverypass123 < "$PROJECT_ROOT/phase2/neo4j/import/init-network.cypher"

# Pokreni web servise faze 2
echo ""
echo "[8/9] Pokrećem web servise faze 2 i nginx..."
docker-compose -f docker-compose.phase2.yml up -d --build

# Pokreni fazu 3
echo ""
echo "[9/9] Pokrećem servise faze 3 (GPS, Kafka, ELK stack)..."
cd "$PROJECT_ROOT"
docker compose -f docker-compose.phase3.yml up -d --build

# Provjeri status
echo ""
echo "=================================================="
echo "  Status servisa - Faza 2:"
echo "=================================================="
cd "$PROJECT_ROOT/phase2"
docker-compose -f docker-compose.phase2.yml ps

echo ""
echo "=================================================="
echo "  Status servisa - Faza 3:"
echo "=================================================="
cd "$PROJECT_ROOT"
docker compose -f docker-compose.phase3.yml ps

echo ""
echo "=================================================="
echo "  Deployment završen!"
echo "=================================================="
echo ""
echo "Pristup:"
echo "  - Web aplikacija: http://localhost"
echo "  - Neo4j Browser:  http://localhost:7474"
echo "  - MongoDB:        localhost:27017"
echo "  - Kibana:         http://localhost:5601"
echo "  - Elasticsearch:  http://localhost:9200"
echo ""
echo "Provjera logova:"
echo "  Faza 2: docker-compose -f phase2/docker-compose.phase2.yml logs -f"
echo "  Faza 3: docker compose -f docker-compose.phase3.yml logs -f"
echo ""
echo "Zaustavljanje:"
echo "  Faza 2: docker-compose -f phase2/docker-compose.phase2.yml down"
echo "  Faza 3: docker compose -f docker-compose.phase3.yml down"
echo ""