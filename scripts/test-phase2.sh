#!/bin/bash

echo "=== Testing Phase 2: Logistics Network ==="
echo ""

echo "1. Health Check:"
curl -s http://localhost/health | python3 -m json.tool
echo ""

echo "2. Network Statistics:"
curl -s http://localhost/api/network/statistics | python3 -m json.tool
echo ""

echo "3. Total Locations:"
LOCATIONS=$(curl -s http://localhost/api/network/locations | python3 -c "import sys, json; print(json.load(sys.stdin)['count'])")
echo "Total locations: $LOCATIONS"
echo ""

echo "4. Optimal Routes:"
echo "   Zagreb → Split (distance):"
curl -s "http://localhost/api/network/routes?from=Zagreb&to=Split&optimize_by=distance" | python3 -c "import sys, json; d = json.load(sys.stdin)['path']; print(f\"   Distance: {d['total_distance_km']} km, Time: {d['total_time_hours']} h, Cost: {d['total_cost_eur']} EUR\")"

echo "   Rijeka → Dubrovnik (time):"
curl -s "http://localhost/api/network/routes?from=Rijeka&to=Dubrovnik&optimize_by=time" | python3 -c "import sys, json; d = json.load(sys.stdin)['path']; print(f\"   Distance: {d['total_distance_km']} km, Time: {d['total_time_hours']} h, Cost: {d['total_cost_eur']} EUR\")"

echo "   Osijek → Pula (cost):"
curl -s "http://localhost/api/network/routes?from=Osijek&to=Pula&optimize_by=cost" | python3 -c "import sys, json; d = json.load(sys.stdin)['path']; print(f\"   Distance: {d['total_distance_km']} km, Time: {d['total_time_hours']} h, Cost: {d['total_cost_eur']} EUR\")"
echo ""

echo "5. Create Test Shipment:"
TRACKING=$(curl -s -X POST http://localhost/api/shipments/ \
  -H "Content-Type: application/json" \
  -d '{"sender":{"name":"Zagreb DC"},"receiver":{"name":"Split Customer"},"weight":10.0,"pickup_address":"Zagreb, DC_ZG","delivery_address":"Split, DC_ST","products":[{"name":"Package","quantity":1}]}' | python3 -c "import sys, json; print(json.load(sys.stdin)['tracking_number'])")
echo "   Created shipment: $TRACKING"
echo ""

echo "6. Load Balancing Test:"
for i in {1..6}; do
  SERVER=$(curl -s http://localhost/health | python3 -c "import sys, json; print(json.load(sys.stdin)['server_id'])")
  echo "   Request $i: $SERVER"
done
echo ""

echo "=== Phase 2 Test Complete ==="
echo ""
echo "Available endpoints:"
echo "  - Web UI: http://localhost"
echo "  - Network UI: http://localhost/network"
echo "  - Neo4j Browser: http://localhost:7474"
echo ""
