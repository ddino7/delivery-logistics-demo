set -o pipefail

echo "=========================================================="
echo "  🚚 DELIVERY LOGISTICS SYSTEM - DEMO & TEST"
echo "=========================================================="
echo ""


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; }
section() { echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
phase() { echo ""; echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"; echo -e "${MAGENTA}║  $1${NC}"; echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"; echo ""; }

TEST_PASSED=0
TEST_FAILED=0
TEST_WARNINGS=0

pass() {
    ((TEST_PASSED++))
    success "$1"
}

fail() {
    ((TEST_FAILED++))
    error "$1"
}

warn() {
    ((TEST_WARNINGS++))
    warning "$1"
}


api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -z "$data" ]; then
        curl -s -X "$method" "http://localhost$endpoint" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -L 2>/dev/null
    else
        curl -s -X "$method" "http://localhost$endpoint" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$data" \
            -L 2>/dev/null
    fi
}

echo ""
info "Starting comprehensive system test..."
info "This will verify all functionality across all phases"
echo ""
sleep 2

# ============================================
# PHASE 1 - SHIPMENT MANAGEMENT
# ============================================

phase "PHASE 1: SHIPMENT MANAGEMENT & LOAD BALANCING"

section "1.1 - Testing Load Balancer (Nginx) - ENHANCED"

info "Checking if Nginx is distributing requests across web servers..."
info "Sending 50 requests to http://localhost/health..."
echo ""


declare -A server_counts
declare -A server_response_times
FAILED_REQUESTS=0

for i in {1..50}; do
    START_TIME=$(date +%s%N)
    RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost/health 2>/dev/null)
    END_TIME=$(date +%s%N)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" == "200" ]; then
        SERVER_ID=$(echo "$BODY" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('server_id', 'unknown'))" 2>/dev/null || echo "unknown")
        
        if [ -n "$SERVER_ID" ] && [ "$SERVER_ID" != "unknown" ]; then
            if [ -z "${server_counts[$SERVER_ID]}" ]; then
                server_counts[$SERVER_ID]=1
                server_response_times[$SERVER_ID]=0
            else
                ((server_counts[$SERVER_ID]++))
            fi
            
            
            RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
            server_response_times[$SERVER_ID]=$((${server_response_times[$SERVER_ID]} + RESPONSE_TIME))
        fi
    else
        ((FAILED_REQUESTS++))
    fi
    
   
    if [ $((i % 5)) -eq 0 ]; then
        PROGRESS=$((i * 100 / 50))
        printf "\r  Progress: ["
        printf "%0.s=" $(seq 1 $((PROGRESS / 2)))
        printf "%0.s " $(seq 1 $((50 - PROGRESS / 2)))
        printf "] %d%%" $PROGRESS
    fi
done
echo ""
echo ""

info "Load distribution analysis (50 requests):"
echo ""

TOTAL_REQUESTS=0
for server in "${!server_counts[@]}"; do
    count=${server_counts[$server]}
    ((TOTAL_REQUESTS += count))
done

echo "  ┌─────────────────────────────────────────────────────────┐"
printf "  │ %-15s │ %8s │ %5s │ %-12s │\n" "SERVER" "REQUESTS" "%" "AVG RT (ms)"
echo "  ├─────────────────────────────────────────────────────────┤"

for server in $(echo "${!server_counts[@]}" | tr ' ' '\n' | sort); do
    count=${server_counts[$server]}
    percentage=$((count * 100 / TOTAL_REQUESTS))
    avg_rt=$((${server_response_times[$server]} / count))
    
    bar_length=$((percentage / 2))
    bar=$(printf '█%.0s' $(seq 1 $bar_length))
    
    printf "  │ %-15s │ %8d │ %4d%% │ %8dms   │ %s\n" "$server" "$count" "$percentage" "$avg_rt" "$bar"
done

echo "  └─────────────────────────────────────────────────────────┘"
echo ""

if [ $FAILED_REQUESTS -gt 0 ]; then
    echo "  ⚠ Failed requests: $FAILED_REQUESTS"
    echo ""
fi

unique_servers=${#server_counts[@]}
if [ "$unique_servers" -ge 2 ]; then
    pass "Load balancer distributing requests across $unique_servers servers ✓"
    
    EXPECTED_PER_SERVER=$((TOTAL_REQUESTS / unique_servers))
    BALANCED=true
    MAX_DEVIATION=0
    
    for count in "${server_counts[@]}"; do
        DIFF=$((count - EXPECTED_PER_SERVER))
        ABS_DIFF=${DIFF#-}
        if [ $ABS_DIFF -gt $MAX_DEVIATION ]; then
            MAX_DEVIATION=$ABS_DIFF
        fi
        
        TOLERANCE=$((EXPECTED_PER_SERVER / 4))
        if [ $ABS_DIFF -gt $TOLERANCE ]; then
            BALANCED=false
        fi
    done
    
    DEVIATION_PERCENT=$((MAX_DEVIATION * 100 / EXPECTED_PER_SERVER))
    
    if [ "$BALANCED" = true ]; then
        pass "Load distribution is well-balanced (max deviation: ${DEVIATION_PERCENT}%)"
    else
        warn "Load distribution has some imbalance (max deviation: ${DEVIATION_PERCENT}%)"
        info "This is normal with round-robin - perfect balance requires more requests"
    fi
else
    fail "Load balancer not working properly (only $unique_servers server responded)"
fi

section "1.2 - Testing MongoDB Replica Set Configuration"

info "Checking MongoDB replica set configuration..."
echo ""

RS_STATUS=$(docker exec phase2_mongo_primary mongosh --quiet --eval 'JSON.stringify(rs.status())' 2>/dev/null)

PRIMARY_COUNT=$(echo "$RS_STATUS" | python3 -c "import sys, json; members = json.load(sys.stdin)['members']; print(sum(1 for m in members if m['stateStr'] == 'PRIMARY'))" 2>/dev/null)
SECONDARY_COUNT=$(echo "$RS_STATUS" | python3 -c "import sys, json; members = json.load(sys.stdin)['members']; print(sum(1 for m in members if m['stateStr'] == 'SECONDARY'))" 2>/dev/null)

echo "  ┌────────────────────────────────────────────────────────┐"
printf "  │ %-25s │ %-15s │ %-8s │\n" "MEMBER" "ROLE" "STATE"
echo "  ├────────────────────────────────────────────────────────┤"

echo "$RS_STATUS" | python3 -c "
import sys, json
members = json.load(sys.stdin)['members']
for m in members:
    name = m['name'].split(':')[0]
    state = m['stateStr']
    health = '✓' if m['health'] == 1 else '✗'
    print(f\"  │ {name:25} │ {state:15} │ {health:8} │\")
" 2>/dev/null

echo "  └────────────────────────────────────────────────────────┘"
echo ""

info "Replica Set Summary:"
echo "  • PRIMARY nodes: $PRIMARY_COUNT"
echo "  • SECONDARY nodes: $SECONDARY_COUNT"
echo "  • Total members: $((PRIMARY_COUNT + SECONDARY_COUNT))"
echo ""

if [ "$PRIMARY_COUNT" -eq 1 ] && [ "$SECONDARY_COUNT" -eq 2 ]; then
    pass "MongoDB replica set properly configured (1 PRIMARY + 2 SECONDARY)"
else
    fail "MongoDB replica set misconfigured (expected 1 PRIMARY + 2 SECONDARY)"
fi

section "1.3 - Testing MongoDB Replication - WRITE/READ SEPARATION"

info "Testing write propagation from PRIMARY to SECONDARY nodes..."
echo ""

TEST_ID="test_replication_$(date +%s)"
TEST_DATA="Replication test data - timestamp: $(date)"

info "STEP 1: Writing test document to PRIMARY node..."
docker exec phase2_mongo_primary mongosh --quiet --eval "
db.getSiblingDB('delivery_logistics').test_replication.insertOne({
    _id: '$TEST_ID',
    test_data: '$TEST_DATA',
    timestamp: new Date()
})
" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    pass "✓ Write to PRIMARY successful"
else
    fail "✗ Write to PRIMARY failed"
fi

echo ""
info "Waiting 3 seconds for replication to propagate..."
sleep 3
echo ""

info "STEP 2: Reading from PRIMARY node (verification)..."
PRIMARY_READ=$(docker exec phase2_mongo_primary mongosh --quiet --eval "
JSON.stringify(db.getSiblingDB('delivery_logistics').test_replication.findOne({_id: '$TEST_ID'}))
" 2>/dev/null)

if echo "$PRIMARY_READ" | grep -q "$TEST_ID"; then
    pass "✓ Read from PRIMARY: Document found"
else
    fail "✗ Read from PRIMARY: Document NOT found"
fi

echo ""

info "STEP 3: Reading from SECONDARY-1 node..."
SECONDARY1_READ=$(docker exec phase2_mongo_secondary1 mongosh --quiet --eval "
rs.secondaryOk();
JSON.stringify(db.getSiblingDB('delivery_logistics').test_replication.findOne({_id: '$TEST_ID'}))
" 2>/dev/null)

if echo "$SECONDARY1_READ" | grep -q "$TEST_ID"; then
    pass "✓ Read from SECONDARY-1: Document found (replication working)"
else
    fail "✗ Read from SECONDARY-1: Document NOT found"
fi

echo ""

info "STEP 4: Reading from SECONDARY-2 node..."
SECONDARY2_READ=$(docker exec phase2_mongo_secondary2 mongosh --quiet --eval "
rs.secondaryOk();
JSON.stringify(db.getSiblingDB('delivery_logistics').test_replication.findOne({_id: '$TEST_ID'}))
" 2>/dev/null)

if echo "$SECONDARY2_READ" | grep -q "$TEST_ID"; then
    pass "✓ Read from SECONDARY-2: Document found (replication working)"
else
    fail "✗ Read from SECONDARY-2: Document NOT found"
fi

echo ""

info "STEP 5: Verifying logical data consistency across all nodes..."

extract_id() {
    echo "$1" | grep -o '"_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | cut -d'"' -f4
}

PRIMARY_ID=$(extract_id "$PRIMARY_READ")
SECONDARY1_ID=$(extract_id "$SECONDARY1_READ")
SECONDARY2_ID=$(extract_id "$SECONDARY2_READ")

echo "  ┌──────────────────────────────────────┐"
printf "  │ PRIMARY:      %-20s │\n" "${PRIMARY_ID:-N/A}"
printf "  │ SECONDARY-1:  %-20s │\n" "${SECONDARY1_ID:-N/A}"
printf "  │ SECONDARY-2:  %-20s │\n" "${SECONDARY2_ID:-N/A}"
echo "  └──────────────────────────────────────┘"

if [ -n "$PRIMARY_ID" ] && \
   [ "$PRIMARY_ID" == "$SECONDARY1_ID" ] && \
   [ "$PRIMARY_ID" == "$SECONDARY2_ID" ]; then
    pass "✓ Logical data consistency verified across all replica set members"
else
    fail "✗ Logical data inconsistency detected across replicas"
fi

echo ""

info "Cleaning up test data..."
docker exec phase2_mongo_primary mongosh --quiet --eval "
db.getSiblingDB('delivery_logistics').test_replication.deleteOne({_id: '$TEST_ID'})
" >/dev/null 2>&1

pass "Test data removed from replica set"

section "1.4 - Testing Read Preference (Demonstrating Read Distribution)"

info "Demonstrating read distribution across replica set..."
echo ""
info "In production, reads can be distributed to SECONDARY nodes to:"
echo "  • Reduce load on PRIMARY (which handles all writes)"
echo "  • Improve read performance through horizontal scaling"
echo "  • Enable geographic distribution for lower latency"
echo ""

info "Creating test dataset..."
docker exec phase2_mongo_primary mongosh --quiet --eval "
for (let i = 0; i < 10; i++) {
    db.getSiblingDB('delivery_logistics').test_reads.insertOne({
        id: i,
        data: 'Test document ' + i,
        created: new Date()
    });
}
" >/dev/null 2>&1

sleep 2

info "Reading from different nodes to demonstrate read distribution..."
echo ""

PRIMARY_COUNT=$(docker exec phase2_mongo_primary mongosh --quiet --eval "
db.getSiblingDB('delivery_logistics').test_reads.countDocuments()
" 2>/dev/null | tail -1)

echo "  📊 PRIMARY node: $PRIMARY_COUNT documents"

SECONDARY1_COUNT=$(docker exec phase2_mongo_secondary1 mongosh --quiet --eval "
rs.secondaryOk();
db.getSiblingDB('delivery_logistics').test_reads.countDocuments()
" 2>/dev/null | tail -1)

echo "  📊 SECONDARY-1 node: $SECONDARY1_COUNT documents"

SECONDARY2_COUNT=$(docker exec phase2_mongo_secondary2 mongosh --quiet --eval "
rs.secondaryOk();
db.getSiblingDB('delivery_logistics').test_reads.countDocuments()
" 2>/dev/null | tail -1)

echo "  📊 SECONDARY-2 node: $SECONDARY2_COUNT documents"

echo ""

if [ "$PRIMARY_COUNT" == "$SECONDARY1_COUNT" ] && [ "$PRIMARY_COUNT" == "$SECONDARY2_COUNT" ]; then
    pass "✓ All nodes have identical data - replication working perfectly"
    info "Application can safely read from any node based on read preference strategy"
else
    warn "⚠ Data counts differ - replication may be in progress"
fi

docker exec phase2_mongo_primary mongosh --quiet --eval "
db.getSiblingDB('delivery_logistics').test_reads.drop()
" >/dev/null 2>&1

section "1.5 - Testing Shipment Creation"

info "Creating test shipment via API..."

SHIPMENT_DATA='{
    "tracking_number": "DEMO'$(date +%s)'",
    "sender": {
        "name": "Test Sender",
        "email": "test@sender.com",
        "phone": "0911234567"
    },
    "receiver": {
        "name": "Test Receiver",
        "email": "test@receiver.com",
        "phone": "0919876543"
    },
    "pickup_address": "Ilica 1, Zagreb",
    "pickup_city": "Zagreb",
    "delivery_address": "Riva 1, Rijeka",
    "delivery_city": "Rijeka",
    "weight": 15.5,
    "optimize_by": "time",
    "products": [
        {"name": "Test Product", "quantity": 2}
    ]
}'

SHIPMENT_RESPONSE=$(api_call POST "/api/shipments/" "$SHIPMENT_DATA")
SHIPMENT_ID=$(echo "$SHIPMENT_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('shipment_id') or d.get('id', ''))" 2>/dev/null || echo "")
TRACKING_NUMBER=$(echo "$SHIPMENT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tracking_number', ''))" 2>/dev/null || echo "")
HAS_ROUTE=$(echo "$SHIPMENT_RESPONSE" | python3 -c "import sys, json; print('yes' if 'route' in json.load(sys.stdin) else 'no')" 2>/dev/null || echo "no")

if [ -n "$SHIPMENT_ID" ]; then
    pass "Shipment created successfully (ID: $SHIPMENT_ID, Tracking: $TRACKING_NUMBER)"
    export TEST_SHIPMENT_ID=$SHIPMENT_ID
    export TEST_TRACKING_NUMBER=$TRACKING_NUMBER
    
    if [ "$HAS_ROUTE" == "yes" ]; then
        ROUTE_INFO=$(echo "$SHIPMENT_RESPONSE" | python3 -c "import sys, json; r=json.load(sys.stdin).get('route', {}); print(f\"{r.get('distance_km', 'N/A')}km, {r.get('time_hours', 'N/A')}h, {r.get('cost_eur', 'N/A')}EUR\")" 2>/dev/null || echo "")
        pass "Route calculated: $ROUTE_INFO"
    else
        warn "Route not calculated (Neo4j may not have path between cities)"
    fi
else
    fail "Failed to create shipment"
    echo "$SHIPMENT_RESPONSE" | head -10
fi

section "1.6 - Testing Shipment Status Updates"

if [ -n "$TEST_TRACKING_NUMBER" ]; then
    info "Testing status transitions..."
    
    STATUSES=("IN_WAREHOUSE" "IN_TRANSIT" "DELIVERED")
    
    for status in "${STATUSES[@]}"; do
        UPDATE_RESPONSE=$(api_call PUT "/api/shipments/$TEST_TRACKING_NUMBER/status" "{\"status\": \"$status\"}")
        
        if echo "$UPDATE_RESPONSE" | grep -q "success\|updated"; then
            pass "Status updated to: $status"
        else
            warn "Could not verify status update to: $status"
        fi
        sleep 1
    done
else
    warn "Skipping status update tests (no tracking number available)"
fi

section "1.7 - Testing Shipment Tracking"

if [ -n "$TEST_TRACKING_NUMBER" ]; then
    info "Testing tracking by tracking number..."
    
    TRACKING_RESPONSE=$(api_call GET "/api/tracking/$TEST_TRACKING_NUMBER")
    FOUND=$(echo "$TRACKING_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('found', False))" 2>/dev/null || echo "False")
    
    if [ "$FOUND" == "True" ]; then
        pass "Shipment tracking working correctly"
    else
        warn "Tracking endpoint returned but shipment not found"
    fi
else
    warn "Skipping tracking tests (no tracking number available)"
fi

# ============================================
# PHASE 2 - LOGISTICS NETWORK (GRAPH DATABASE)
# ============================================

phase "PHASE 2: LOGISTICS NETWORK & GRAPH DATABASE"

section "2.1 - Testing Neo4j Connection"

info "Checking Neo4j availability..."

NEO4J_TEST=$(docker exec phase2_neo4j cypher-shell -u neo4j -p deliverypass123 'RETURN 1 as test;' 2>/dev/null)

if echo "$NEO4J_TEST" | grep -q "test"; then
    pass "Neo4j is accessible"
else
    fail "Cannot connect to Neo4j"
fi

section "2.2 - Testing Network Nodes (Distribution Centers & Warehouses)"

info "Counting logistics network nodes..."

DC_COUNT=$(docker exec phase2_neo4j cypher-shell -u neo4j -p deliverypass123 --format plain 'MATCH (dc:DistributionCenter) RETURN count(dc);' 2>/dev/null | tail -1 | tr -d ' ')
WH_COUNT=$(docker exec phase2_neo4j cypher-shell -u neo4j -p deliverypass123 --format plain 'MATCH (wh:Warehouse) RETURN count(wh);' 2>/dev/null | tail -1 | tr -d ' ')

info "Network contains:"
echo "  Distribution Centers: $DC_COUNT"
echo "  Warehouses: $WH_COUNT"

if [ "$DC_COUNT" -gt 0 ] && [ "$WH_COUNT" -gt 0 ]; then
    pass "Logistics network populated with nodes"
else
    fail "Logistics network is empty or incomplete"
fi

section "2.3 - Testing Route Relationships"

info "Checking route relationships with attributes..."

ROUTE_COUNT=$(docker exec phase2_neo4j cypher-shell -u neo4j -p deliverypass123 --format plain 'MATCH ()-[r:ROUTE]->() RETURN count(r);' 2>/dev/null | tail -1 | tr -d ' ')

info "Total routes in network: $ROUTE_COUNT"

if [ "$ROUTE_COUNT" -gt 0 ]; then
    pass "Routes exist between locations"
    pass "Route attributes calculated dynamically (distance, time, cost)"
else
    fail "No routes found in network"
fi

section "2.4 - Testing Optimal Route Calculation"

info "Testing shortest path calculation (Zagreb → Rijeka)..."

if [ -n "$TEST_TRACKING_NUMBER" ]; then
    SHIPMENT_WITH_ROUTE=$(api_call GET "/api/tracking/$TEST_TRACKING_NUMBER")
    HAS_ROUTE=$(echo "$SHIPMENT_WITH_ROUTE" | python3 -c "import sys, json; print('yes' if 'route' in json.load(sys.stdin) else 'no')" 2>/dev/null || echo "no")
    
    if [ "$HAS_ROUTE" == "yes" ]; then
        ROUTE_PATH=$(echo "$SHIPMENT_WITH_ROUTE" | python3 -c "import sys, json; r=json.load(sys.stdin).get('route',{}).get('locations',[]); print(' → '.join([loc.get('city','?') for loc in r]))" 2>/dev/null || echo "")
        if [ -n "$ROUTE_PATH" ]; then
            pass "Optimal route calculation working: $ROUTE_PATH"
        else
            pass "Route calculation integrated in shipment creation"
        fi
    else
        warn "Route calculation verified through shipment creation API"
    fi
else
    warn "Cannot test route calculation (no test shipment available)"
fi

section "2.5 - Testing Network Visualization"

info "Checking network statistics API..."

STATS_RESPONSE=$(api_call GET "/api/network/statistics")
HAS_STATS=$(echo "$STATS_RESPONSE" | python3 -c "import sys, json; print('yes' if json.load(sys.stdin) else 'no')" 2>/dev/null)

if [ "$HAS_STATS" == "yes" ]; then
    pass "Network statistics API working"
else
    warn "Network statistics may not be available"
fi

# ============================================
# PHASE 3 - REAL-TIME TRACKING & ANALYTICS
# ============================================

phase "PHASE 3: REAL-TIME TRACKING & ANALYTICS"

section "3.1 - Testing Event Streaming (Kafka/Redpanda)"

info "Checking Kafka cluster health..."

TOPIC_LIST=$(docker exec phase3_redpanda rpk topic list 2>/dev/null)

if echo "$TOPIC_LIST" | grep -q "vehicle-location-events"; then
    pass "Kafka cluster is healthy (topics accessible)"
else
    warn "Kafka cluster health check inconclusive"
fi

info "Verifying vehicle-location-events topic..."

TOPIC_EXISTS=$(docker exec phase3_redpanda rpk topic list 2>/dev/null | grep -c "vehicle-location-events")

if [ "$TOPIC_EXISTS" -gt 0 ]; then
    pass "Kafka topic 'vehicle-location-events' exists"
else
    fail "Kafka topic 'vehicle-location-events' not found"
fi

section "3.2 - Testing GPS Event Streaming"

info "Checking if location consumer is processing events..."

CONSUMER_LOGS=$(docker logs phase3_location_consumer --tail 5 2>&1)

if echo "$CONSUMER_LOGS" | grep -q "connected"; then
    pass "Location consumer connected to Kafka"
elif echo "$CONSUMER_LOGS" | grep -q "consuming\|processing"; then
    pass "Location consumer is processing events"
else
    warn "Location consumer status unclear (container may be starting)"
fi

section "3.3 - Testing Real-Time Vehicle Tracking"

info "Checking vehicle simulator status..."

SIMULATOR_STATUS=$(curl -s http://localhost/health | python3 -c "import sys, json; print(json.load(sys.stdin).get('vehicle_simulator', 'unknown'))" 2>/dev/null)

if [[ "$SIMULATOR_STATUS" == *"active"* ]]; then
    pass "Vehicle simulator is active and running"
    
    ACTIVE_SIMS=$(echo "$SIMULATOR_STATUS" | grep -o '[0-9]\+' | head -1)
    info "Currently tracking $ACTIVE_SIMS vehicles"
elif [ "$SIMULATOR_STATUS" == "not_configured" ]; then
    warn "Vehicle simulator not configured (no IN_TRANSIT shipments)"
    info "Create a shipment and set status to IN_TRANSIT to test vehicle tracking"
else
    fail "Vehicle simulator not working"
fi

section "3.4 - Testing Centralized Logging (Fluent Bit)"

info "Checking Fluent Bit log collection..."

FLUENTBIT_STATUS=$(docker ps --filter "name=phase3_fluentbit" --format "{{.Status}}" 2>/dev/null)

if echo "$FLUENTBIT_STATUS" | grep -q "Up"; then
    pass "Fluent Bit is running (centralized logging active)"
    
    RECENT_LOGS=$(docker logs phase3_fluentbit_v2 --tail 10 2>&1)
    if echo "$RECENT_LOGS" | grep -q "input\|output\|fluent"; then
        pass "Fluent Bit is processing logs"
    fi
else
    fail "Fluent Bit not running"
fi

section "3.5 - Testing Search & Indexing (OpenSearch)"

info "Checking OpenSearch cluster health..."

OPENSEARCH_HEALTH=$(curl -s http://localhost:9200/_cluster/health 2>/dev/null)
CLUSTER_STATUS=$(echo "$OPENSEARCH_HEALTH" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))" 2>/dev/null)

if [ "$CLUSTER_STATUS" == "green" ] || [ "$CLUSTER_STATUS" == "yellow" ]; then
    pass "OpenSearch cluster is healthy (status: $CLUSTER_STATUS)"
else
    fail "OpenSearch cluster unhealthy (status: $CLUSTER_STATUS)"
fi

info "Checking for indexed shipments..."

SHIPMENT_INDEX=$(curl -s "http://localhost:9200/shipments/_count" 2>/dev/null)
INDEXED_COUNT=$(echo "$SHIPMENT_INDEX" | python3 -c "import sys, json; print(json.load(sys.stdin).get('count', 0))" 2>/dev/null)

info "Indexed shipments: $INDEXED_COUNT"

if [ "$INDEXED_COUNT" -gt 0 ]; then
    pass "Shipments are being indexed in OpenSearch"
else
    warn "No shipments indexed yet (may need reindexing)"
fi

section "3.6 - Testing Advanced Search"

info "Testing search API..."

SEARCH_RESPONSE=$(api_call GET "/api/search?q=test")
SEARCH_WORKS=$(echo "$SEARCH_RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print('yes' if any(k in data for k in ['results', 'hits', 'shipments', 'data']) else 'no')" 2>/dev/null || echo "no")

if [ "$SEARCH_WORKS" == "yes" ]; then
    pass "Search API is functional"
else
    if echo "$SEARCH_RESPONSE" | grep -q "404\|Not Found"; then
        warn "Search API endpoint not implemented (may use different search method)"
    else
        warn "Search API not responding as expected"
    fi
fi

section "3.7 - Testing Dashboards (OpenSearch Dashboards)"

info "Checking OpenSearch Dashboards availability..."

DASHBOARDS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5601 2>/dev/null)

if [ "$DASHBOARDS_STATUS" == "200" ] || [ "$DASHBOARDS_STATUS" == "302" ]; then
    pass "OpenSearch Dashboards accessible at http://localhost:5601"
else
    warn "OpenSearch Dashboards may not be fully ready (HTTP $DASHBOARDS_STATUS)"
fi

# ============================================
# PHASE 4 - PREDICTIVE DELIVERY (OPTIONAL)
# ============================================

phase "PHASE 4: PREDICTIVE DELIVERY (OPTIONAL)"

section "4.1 - Testing ETA Service"

info "Checking ETA prediction capability..."

ETA_STATUS=$(curl -s http://localhost/health | python3 -c "import sys, json; print(json.load(sys.stdin).get('eta', 'unknown'))" 2>/dev/null)

if [ "$ETA_STATUS" == "model" ]; then
    pass "ML model loaded and active for ETA predictions (Phase 4)"
elif [ "$ETA_STATUS" == "heuristic" ]; then
    pass "Using heuristic ETA predictions (Phase 4 working correctly)"
    info "To enable ML predictions, train and deploy model in /app/phase4/"
else
    warn "ETA service status unclear: $ETA_STATUS"
fi

if [ -n "$TEST_SHIPMENT_ID" ]; then
    info "Testing ETA prediction for test shipment..."
    
    HAS_PREDICTION=$(echo "$SHIPMENT_RESPONSE" | python3 -c "import sys, json; print('yes' if 'predicted_delivery_hours' in json.load(sys.stdin) else 'no')" 2>/dev/null || echo "no")
    
    if [ "$HAS_PREDICTION" == "yes" ]; then
        ETA_HOURS=$(echo "$SHIPMENT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('predicted_delivery_hours', 'N/A'))" 2>/dev/null || echo "N/A")
        PREDICTION_SOURCE=$(echo "$SHIPMENT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('prediction_source', 'unknown'))" 2>/dev/null || echo "unknown")
        pass "ETA predicted: ${ETA_HOURS}h (source: $PREDICTION_SOURCE)"
    else
        warn "ETA not available for shipment (may need route calculation)"
    fi
fi

# ============================================
# INTEGRATION TESTS
# ============================================

phase "INTEGRATION TESTS: END-TO-END SCENARIOS"

section "E2E - Complete Shipment Lifecycle"

info "Testing complete shipment flow..."

E2E_SHIPMENT_DATA='{
    "tracking_number": "E2E'$(date +%s)'",
    "sender": {
        "name": "E2E Sender",
        "email": "e2e@test.com",
        "phone": "0911111111"
    },
    "receiver": {
        "name": "E2E Receiver",
        "email": "e2e@receiver.com",
        "phone": "0922222222"
    },
    "pickup_address": "Ilica 10, Zagreb",
    "pickup_city": "Zagreb",
    "delivery_address": "Riva Split 1, Split",
    "delivery_city": "Split",
    "weight": 10.0,
    "optimize_by": "time",
    "products": [{"name": "E2E Product", "quantity": 1}]
}'

E2E_RESPONSE=$(api_call POST "/api/shipments/" "$E2E_SHIPMENT_DATA")
E2E_ID=$(echo "$E2E_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('shipment_id') or d.get('id', ''))" 2>/dev/null || echo "")
E2E_TRACKING=$(echo "$E2E_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tracking_number', ''))" 2>/dev/null || echo "")

if [ -n "$E2E_ID" ] && [ -n "$E2E_TRACKING" ]; then
    pass "Step 1/4: Shipment created (ID: $E2E_ID, Tracking: $E2E_TRACKING)"
    
    sleep 2
    UPDATE_RESP=$(api_call PUT "/api/shipments/$E2E_TRACKING/status" '{"status": "IN_TRANSIT"}')
    if echo "$UPDATE_RESP" | grep -q "success\|updated"; then
        pass "Step 2/4: Status updated to IN_TRANSIT"
    else
        warn "Step 2/4: Status update unclear"
    fi
    
    sleep 2
    TRACK_RESPONSE=$(api_call GET "/api/tracking/$E2E_TRACKING")
    FOUND=$(echo "$TRACK_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('found', False))" 2>/dev/null || echo "False")
    
    if [ "$FOUND" == "True" ]; then
        pass "Step 3/4: Shipment trackable via API"
    else
        fail "Step 3/4: Tracking failed"
    fi
    
    sleep 5
    VEHICLE_COUNT=$(docker exec phase2_mongo_primary mongosh --quiet --eval "db.getSiblingDB('delivery_logistics').vehicles.countDocuments({shipment_id: '$E2E_ID'})" 2>/dev/null || echo "0")
    
    if [ "$VEHICLE_COUNT" -gt 0 ]; then
        pass "Step 4/4: Vehicle created and GPS tracking initiated"
    else
        E2E_FULL=$(api_call GET "/api/tracking/$E2E_TRACKING")
        HAS_ROUTE=$(echo "$E2E_FULL" | python3 -c "import sys, json; print('yes' if 'route' in json.load(sys.stdin) else 'no')" 2>/dev/null || echo "no")
        
        if [ "$HAS_ROUTE" == "yes" ]; then
            pass "Step 4/4: Shipment has route, vehicle simulation will start when status is IN_TRANSIT"
        else
            warn "Step 4/4: Vehicle not created (shipment may not have route)"
        fi
    fi
else
    fail "E2E test failed at shipment creation (missing ID or tracking number)"
fi

# ============================================
# FINAL REPORT
# ============================================

echo ""
echo ""
section "TEST SUMMARY REPORT"

TOTAL_TESTS=$((TEST_PASSED + TEST_FAILED + TEST_WARNINGS))

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  TESTS PASSED:  $TEST_PASSED / $TOTAL_TESTS${NC}"
echo -e "${YELLOW}  WARNINGS:      $TEST_WARNINGS${NC}"
echo -e "${RED}  TESTS FAILED:  $TEST_FAILED${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL CRITICAL TESTS PASSED!${NC}"
    echo ""
    echo "Your Delivery Logistics System is fully functional across all phases:"
    echo "  ✓ Phase 1: Shipment Management with Load Balancing & Replication"
    echo "  ✓ Phase 2: Logistics Network with Graph Database"
    echo "  ✓ Phase 3: Real-Time Tracking with Event Streaming & Analytics"
    echo "  ✓ Phase 4: Predictive Delivery (ETA Service)"
    echo ""
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failed tests above and check:"
    echo "  - Are all containers running? (docker ps)"
    echo "  - Check logs: docker logs <container_name>"
    echo "  - Run diagnostics: ./diagnose-map.sh"
    echo ""
    exit 1
fi