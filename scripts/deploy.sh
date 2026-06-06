#!/bin/bash

set -e

# ===================================================
#  🚀 Delivery Logistics - Deployment Script
# ===================================================

# Boje za output
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
#  🔧 Inicijalizacija i provjera preduvjeta
# ===================================================

header "Dobrodošao u Deployment Script za Delivery Logistics!"
echo "Ova skripta će pokrenuti sve potrebne servise."
echo "Molimo pratite upute i čekajte potvrde za svaki korak."
echo ""

# Provjera Docker i Docker Compose
header "Provjera preduvjeta"

if ! command -v docker &> /dev/null; then
    error "Docker nije instaliran! Molimo instalirajte Docker prije pokretanja skripte."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose nije instaliran! Molimo instalirajte Docker Compose prije pokretanja skripte."
    exit 1
fi

# Odaberi docker-compose ili docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

info "Korištena verzija: $($DOCKER_COMPOSE version | head -n1)"

# Idi u root direktorij projekta
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || { error "Ne mogu pronaći root direktorij projekta!"; exit 1; }

info "Radni direktorij: $PROJECT_ROOT"

# ===================================================
#  🧹 Opcionalni potpuni cleanup
# ===================================================

header "Opcionalni cleanup prije deploya"

echo "Želite li izvršiti potpuni cleanup prije deploya?"
echo "Ovo će obrisati sve kontejnere, mreže i volume-e (svi podaci će biti izgubljeni!)."
echo -n "Preporučeno ako imate problema sa mrežama ili želite fresh start. (Y/n): "
read -r do_cleanup

if [[ ! "$do_cleanup" =~ ^[Nn]$ ]]; then
    warning "Počinjem s potpunim cleanupom..."

    info "Zaustavljam sve postojeće servise..."
    cd phase1 2>/dev/null && $DOCKER_COMPOSE down -v 2>/dev/null || true
    cd "$PROJECT_ROOT"
    cd phase2 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase2.yml down -v 2>/dev/null || true
    cd "$PROJECT_ROOT"
    $DOCKER_COMPOSE -f docker-compose.phase3.yml down -v 2>/dev/null || true
    cd "$PROJECT_ROOT"
    cd phase4 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase4.yml down -v 2>/dev/null || true
    cd "$PROJECT_ROOT"

    info "Brišem sve kontejnere..."
    docker rm -f $(docker ps -a -q --filter "name=phase1_" --filter "name=phase2_" \
                                   --filter "name=phase3_" --filter "name=phase4_") 2>/dev/null || true

    info "Brišem mreže..."
    docker network rm phase2_delivery-network 2>/dev/null || true
    docker network rm phase1_delivery-network 2>/dev/null || true
    docker network rm phase3_delivery-network 2>/dev/null || true

    warning "Brišem volume-e (PAŽNJA: Gubi se svi podaci!)..."
    docker volume rm $(docker volume ls -q --filter "name=phase1_" --filter "name=phase2_" \
                                           --filter "name=phase3_") 2>/dev/null || true

    success "Potpuni cleanup je uspješno završen!"
    sleep 2
fi

# ===================================================
#  🛑 Zaustavljanje postojećih servisa
# ===================================================

header "Zaustavljanje postojećih servisa"

info "Zaustavljam sve postojeće kontejnere..."
cd phase1 2>/dev/null && $DOCKER_COMPOSE down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase2 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase2.yml down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase3 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase3.yml down -v 2>/dev/null || true
cd "$PROJECT_ROOT"
cd phase4 2>/dev/null && $DOCKER_COMPOSE -f docker-compose.phase4.yml down 2>/dev/null || true
cd "$PROJECT_ROOT"

docker rm -f phase1_nginx phase1_web1 phase1_web2 phase1_web3 \
             phase1_mongo_primary phase1_mongo_secondary1 phase1_mongo_secondary2 \
             phase1_mongo_init phase2_nginx phase2_web1 phase2_web2 phase2_web3 \
             phase2_mongo_primary phase2_mongo_secondary1 phase2_mongo_secondary2 \
             phase2_neo4j phase3_* phase4_ml_service 2>/dev/null || true

success "Svi postojeći kontejneri su zaustavljeni."

# ===================================================
#  🐘 Pokretanje MongoDB servisa
# ===================================================

header "Pokretanje MongoDB servisa"

info "Pokrećem MongoDB primarni i sekundarni čvorove..."
cd "$PROJECT_ROOT/phase2"
$DOCKER_COMPOSE -f docker-compose.phase2.yml up -d mongo-primary mongo-secondary1 mongo-secondary2

info "Čekam 15 sekundi da se MongoDB servisi stabiliziraju..."
sleep 15

# ===================================================
#  🔄 Inicijalizacija MongoDB replica set
# ===================================================

header "Inicijalizacija MongoDB replica set"

info "Inicijaliziram MongoDB replica set..."
docker exec phase2_mongo_primary mongosh --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
});
' || { warning "Došlo je do greške prilikom inicijalizacije replica seta. Nastavljam..."; }

sleep 10

info "Provjeravam status MongoDB replica seta..."
docker exec phase2_mongo_primary mongosh --eval 'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr));' || true

success "MongoDB replica set je uspješno inicijaliziran!"

# ===================================================
#  🔗 Pokretanje Neo4j servisa
# ===================================================

header "Pokretanje Neo4j servisa"

info "Pokrećem Neo4j..."
cd "$PROJECT_ROOT/phase2"
$DOCKER_COMPOSE -f docker-compose.phase2.yml up -d neo4j

info "Čekam 20 sekundi da se Neo4j pokrene..."
sleep 20

info "Inicijaliziram Neo4j mrežu..."
sudo chown -R $USER:$USER "$PROJECT_ROOT/phase2/neo4j/" 2>/dev/null || true
docker exec -i phase2_neo4j cypher-shell -u neo4j -p deliverypass123 < "$PROJECT_ROOT/phase2/neo4j/import/init-network.cypher"

success "Neo4j mreža je uspješno inicijalizirana!"

# ===================================================
#  🚀 Pokretanje Phase 3 servisa (Kafka, GPS, ELK)
# ===================================================

header "Pokretanje Phase 3 servisa"

info "Pokrećem Kafka, GPS i ELK stack..."
cd "$PROJECT_ROOT"
$DOCKER_COMPOSE -f docker-compose.phase3.yml up -d --build

info "Čekam 15 sekundi da se Kafka pokrene..."
sleep 15

success "Phase 3 servisi su uspješno pokrenuti!"

# ===================================================
#  🌐 Pokretanje web servisa faze 2
# ===================================================

header "Pokretanje web servisa faze 2"

info "Pokrećem web servise i nginx..."
cd "$PROJECT_ROOT/phase2"
$DOCKER_COMPOSE -f docker-compose.phase2.yml up -d --build

success "Phase 2 servisi su uspješno pokrenuti!"

# ===================================================
#  🤖 Pokretanje Phase 4 ML servisa
# ===================================================

header "Pokretanje Phase 4 ML servisa"

if [ -f "$PROJECT_ROOT/phase4/docker-compose.phase4.yml" ] && \
   [ -f "$PROJECT_ROOT/phase4/models/best_model.pkl" ]; then
    info "Pokrećem ML Risk Prediction servis..."
    cd "$PROJECT_ROOT/phase4"
    $DOCKER_COMPOSE -f docker-compose.phase4.yml up -d --build
    success "Phase 4 ML servis je uspješno pokrenut!"
else
    warning "Phase 4 ML servis nije dostupan."
    warning "Razlog: model nije treniran ili docker-compose.phase4.yml nedostaje."
    warning "Pokrenite ručno: cd phase4 && python3 train.py && docker compose -f docker-compose.phase4.yml up -d --build"
fi

cd "$PROJECT_ROOT"

# ===================================================
#  📊 Status servisa
# ===================================================

header "Pregled statusa servisa"

echo -e "${BOLD}Faza 2:${NC}"
cd "$PROJECT_ROOT/phase2"
$DOCKER_COMPOSE -f docker-compose.phase2.yml ps

echo -e "\n${BOLD}Faza 3:${NC}"
cd "$PROJECT_ROOT"
$DOCKER_COMPOSE -f docker-compose.phase3.yml ps

echo -e "\n${BOLD}Faza 4:${NC}"
cd "$PROJECT_ROOT/phase4"
$DOCKER_COMPOSE -f docker-compose.phase4.yml ps 2>/dev/null || echo "  (ML servis nije pokrenut)"

cd "$PROJECT_ROOT"

# ===================================================
#  🎉 Deployment uspješno završen!
# ===================================================

header "🎉 DEPLOYMENT ZAVRŠEN!"

echo -e "${GREEN}✅ Svi servisi su uspješno pokrenuti!${NC}"
echo ""
echo -e "${BOLD}Pristupite servisima:${NC}"
echo "  🌍 Web aplikacija:       http://localhost"
echo "  🔍 Neo4j Browser:        http://localhost:7474"
echo "  🗃️  MongoDB:             localhost:27017"
echo "  📊 Kibana:               http://localhost:5601"
echo "  🔎 Elasticsearch:        http://localhost:9200"
echo "  🤖 ML Risk Service:      http://localhost:5050/health"
echo ""
echo -e "${BOLD}Korisne komande:${NC}"
echo "  📜 Logovi (Faza 2):      $DOCKER_COMPOSE -f phase2/docker-compose.phase2.yml logs -f"
echo "  📜 Logovi (Faza 3):      $DOCKER_COMPOSE -f docker-compose.phase3.yml logs -f"
echo "  📜 Logovi (Faza 4):      $DOCKER_COMPOSE -f phase4/docker-compose.phase4.yml logs -f"
echo "  ⏹️  Zaustavljanje (Faza 2): $DOCKER_COMPOSE -f phase2/docker-compose.phase2.yml down"
echo "  ⏹️  Zaustavljanje (Faza 3): $DOCKER_COMPOSE -f docker-compose.phase3.yml down"
echo "  ⏹️  Zaustavljanje (Faza 4): $DOCKER_COMPOSE -f phase4/docker-compose.phase4.yml down"
echo ""
header "🧪 Quick Test"
echo ""
echo "  1. Otvorite:            http://localhost/create"
echo "  2. Kreirajte pošiljku (npr. Zagreb → Split, datum 15. kolovoza)"
echo "  3. Provjerite ML risk score — trebao bi biti HIGH zbog Velike Gospe"
echo "  4. Postavite status u IN_TRANSIT"
echo "  5. Otvorite:            http://localhost/map"
echo "  6. Pratite vozilo u realnom vremenu! 🚚"
echo ""
echo -e "${YELLOW}Za dodatnu pomoć ili rješavanje problema, provjerite logove ili dokumentaciju.${NC}"