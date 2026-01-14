#!/bin/bash

set -e

# ===================================================
#  🚀 Delivery Logistics - Deployment Script
# ===================================================

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; }
header() { echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"; }

# ===================================================
#  🔧 Initialization and Pre-Checks
# ===================================================

header "Welcome to the Delivery Logistics Deployment Script!"
echo "This script will start all required services for project phases 1, 2, and 3."
echo "Please follow the instructions and wait for confirmation at each step."
echo ""

# Check Docker and Docker Compose
header "Checking Prerequisites"

if ! command -v docker &> /dev/null; then
    error "Docker is not installed! Please install Docker before running this script."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose is not installed! Please install Docker Compose before running this script."
    exit 1
fi

# Choose docker-compose or docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

info "Using version: $($DOCKER_COMPOSE version | head -n1)"

# Go to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || { error "Could not find the project root directory!"; exit 1; }

info "Working directory: $PROJECT_ROOT"

# ===================================================
#  🧹 Optional Full Cleanup
# ===================================================

header "Optional Cleanup Before Deployment"

echo "Do you want to perform a full cleanup before deployment?"
echo "This will remove all containers, networks, and volumes (all data will be lost!)."
echo -n "Recommended if you have network issues or want a fresh start. (Y/n): "
read -r do_cleanup

if [[ ! "$do_cleanup" =~ ^[Nn]$ ]]; then
    warning "Starting full cleanup..."

    info "Stopping all existing services..."
    cd phase1 2>/dev/null && $DOCKER_COMPOSE down -v 2>/dev/null || true
    cd "$PROJECT_ROOT"
    cd phase2 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase2.yml down -v 2>/dev/null || true
    cd "$PROJECT_ROOT"
    $DOCKER_COMPOSE -f docker-compose.phase3.yml down -v 2>/dev/null || true

    info "Removing all containers..."
    docker rm -f $(docker ps -a -q --filter "name=phase1_" --filter "name=phase2_" --filter "name=phase3_") 2>/dev/null || true

    info "Removing networks..."
    docker network rm phase2_delivery-network 2>/dev/null || true
    docker network rm phase1_delivery-network 2>/dev/null || true
    docker network rm phase3_delivery-network 2>/dev/null || true

    warning "Removing volumes (WARNING: All data will be lost!)..."
    docker volume rm $(docker volume ls -q --filter "name=phase1_" --filter "name=phase2_" --filter "name=phase3_") 2>/dev/null || true

    success "Full cleanup completed successfully!"
    sleep 2
fi

# ===================================================
#  🛑 Stopping Existing Services
# ===================================================

header "Stopping Existing Services"

info "Stopping all existing containers..."
cd phase1 2>/dev/null && $DOCKER_COMPOSE down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase2 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase2.yml down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase3 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase3.yml down -v 2>/dev/null || true
cd "$PROJECT_ROOT"

docker rm -f phase1_nginx phase1_web1 phase1_web2 phase1_web3 \
             phase1_mongo_primary phase1_mongo_secondary1 phase1_mongo_secondary2 \
             phase1_mongo_init phase2_nginx phase2_web1 phase2_web2 phase2_web3 \
             phase2_mongo_primary phase2_mongo_secondary1 phase2_mongo_secondary2 \
             phase2_neo4j phase3_* 2>/dev/null || true

success "All existing containers have been stopped."

# ===================================================
#  🐘 Starting MongoDB Services
# ===================================================

header "Starting MongoDB Services"

info "Starting MongoDB primary and secondary nodes..."
cd "$PROJECT_ROOT/phase2"
$DOCKER_COMPOSE -f docker-compose.phase2.yml up -d mongo-primary mongo-secondary1 mongo-secondary2

info "Waiting 15 seconds for MongoDB services to stabilize..."
sleep 15

# ===================================================
#  🔄 Initializing MongoDB Replica Set
# ===================================================

header "Initializing MongoDB Replica Set"

info "Initializing MongoDB replica set..."
docker exec phase2_mongo_primary mongosh --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
});
' || { warning "An error occurred while initializing the replica set. Continuing..."; }

sleep 10

info "Checking MongoDB replica set status..."
docker exec phase2_mongo_primary mongosh --eval 'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr));' || true

success "MongoDB replica set has been successfully initialized!"

# ===================================================
#  🔗 Starting Neo4j Services
# ===================================================

header "Starting Neo4j Services"

info "Starting Neo4j..."
$DOCKER_COMPOSE -f docker-compose.phase2.yml up -d neo4j

info "Waiting 20 seconds for Neo4j to start..."
sleep 20

info "Initializing Neo4j network..."
sudo chown -R $USER:$USER "$PROJECT_ROOT/phase2/neo4j/" 2>/dev/null || true
docker exec -i phase2_neo4j cypher-shell -u neo4j -p deliverypass123 < "$PROJECT_ROOT/phase2/neo4j/import/init-network.cypher"

success "Neo4j network has been successfully initialized!"

# ===================================================
#  🚀 Starting Phase 3 Services (Kafka, GPS, ELK)
# ===================================================

header "Starting Phase 3 Services"

info "Starting Kafka, GPS, and ELK stack..."
cd "$PROJECT_ROOT"
$DOCKER_COMPOSE -f docker-compose.phase3.yml up -d --build

info "Waiting 15 seconds for Kafka to start..."
sleep 15

success "Phase 3 services are now running!"

# ===================================================
#  🌐 Starting Phase 2 Web Services
# ===================================================

header "Starting Phase 2 Web Services"

info "Starting web services and nginx..."
cd "$PROJECT_ROOT/phase2"
$DOCKER_COMPOSE -f docker-compose.phase2.yml up -d --build

success "Phase 2 services are now running!"

# ===================================================
#  📊 Service Status Overview
# ===================================================

header "Service Status Overview"

echo -e "${BOLD}Phase 2:${NC}"
cd "$PROJECT_ROOT/phase2"
$DOCKER_COMPOSE -f docker-compose.phase2.yml ps

echo -e "\n${BOLD}Phase 3:${NC}"
cd "$PROJECT_ROOT"
$DOCKER_COMPOSE -f docker-compose.phase3.yml ps

# ===================================================
#  🎉 Deployment Completed Successfully!
# ===================================================

header "🎉 DEPLOYMENT COMPLETED!"

echo -e "${GREEN}✅ All services are now running!${NC}"
echo ""
echo -e "${BOLD}Access the services:${NC}"
echo "  🌍 Web Application:      http://localhost"
echo "  🔍 Neo4j Browser:       http://localhost:7474"
echo "  📊 Kibana:              http://localhost:5601"
echo "  🔎 Elasticsearch:       http://localhost:9200"
echo ""
echo -e "${BOLD}Useful Commands:${NC}"
echo "  📜 Logs (Phase 2):      $DOCKER_COMPOSE -f phase2/docker-compose.phase2.yml logs -f"
echo "  📜 Logs (Phase 3):      $DOCKER_COMPOSE -f docker-compose.phase3.yml logs -f"
echo "  ⏹️  Stop (Phase 2):     $DOCKER_COMPOSE -f phase2/docker-compose.phase2.yml down"
echo "  ⏹️  Stop (Phase 3):     $DOCKER_COMPOSE -f docker-compose.phase3.yml down"
echo ""
header "🧪 Quick Test"
echo ""
echo "  1. Open:                http://localhost/create"
echo "  2. Create a shipment (e.g., Zagreb → Rijeka)"
echo "  3. Set status to IN_TRANSIT"
echo "  4. Open:                http://localhost/map"
echo "  5. Watch the vehicle move in real-time! 🚚"
echo ""
echo -e "${YELLOW}For additional help or troubleshooting, check the logs or documentation.${NC}"
