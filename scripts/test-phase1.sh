#!/bin/bash

echo "=== Testing Phase 1 Delivery System ==="
echo ""

# Create 3 test shipments
echo "1. Creating test shipments..."
TRACKING1=$(curl -s -X POST http://localhost/api/shipments/ \
  -H "Content-Type: application/json" \
  -d '{"sender":{"name":"Test Sender 1"},"receiver":{"name":"Test Receiver 1"},"weight":5.0,"pickup_address":"Zagreb","delivery_address":"Split","products":[{"name":"Test Product","quantity":1}]}' | grep -o 'DLV[0-9]*')

TRACKING2=$(curl -s -X POST http://localhost/api/shipments/ \
  -H "Content-Type: application/json" \
  -d '{"sender":{"name":"Test Sender 2"},"receiver":{"name":"Test Receiver 2"},"weight":10.0,"pickup_address":"Rijeka","delivery_address":"Osijek","products":[{"name":"Test Product","quantity":2}]}' | grep -o 'DLV[0-9]*')

echo "Created: $TRACKING1, $TRACKING2"
echo ""

# Update statuses
echo "2. Updating shipment statuses..."
curl -s -X PUT http://localhost/api/shipments/$TRACKING1/status \
  -H "Content-Type: application/json" \
  -d '{"status":"IN_WAREHOUSE","note":"Test warehouse"}' > /dev/null
echo "✓ $TRACKING1 -> IN_WAREHOUSE"

curl -s -X PUT http://localhost/api/shipments/$TRACKING1/status \
  -H "Content-Type: application/json" \
  -d '{"status":"IN_TRANSIT","note":"Test transit"}' > /dev/null
echo "✓ $TRACKING1 -> IN_TRANSIT"

curl -s -X PUT http://localhost/api/shipments/$TRACKING2/status \
  -H "Content-Type: application/json" \
  -d '{"status":"IN_WAREHOUSE","note":"Test warehouse"}' > /dev/null
echo "✓ $TRACKING2 -> IN_WAREHOUSE"
echo ""

# Test tracking
echo "3. Testing tracking..."
curl -s http://localhost/api/tracking/$TRACKING1 | grep -o '"status":"[^"]*"'
echo ""

# Test load balancing
echo "4. Testing load balancing (10 requests)..."
for i in {1..10}; do
  curl -s http://localhost/health | grep -o '"server_id":"[^"]*"'
done
echo ""

# List all shipments
echo "5. Total shipments in system:"
curl -s http://localhost/api/shipments/ | grep -o '"count":[0-9]*'
echo ""

echo "=== Test Complete ==="