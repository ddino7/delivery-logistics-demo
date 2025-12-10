#!/bin/bash

# MongoDB Replica Set Initialization Script
# This script initializes a MongoDB replica set with 1 primary and 2 secondary nodes

echo "Waiting for MongoDB to be ready..."
sleep 10

echo "Initializing replica set..."

mongosh --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
});
'

echo "Waiting for replica set to stabilize..."
sleep 5

echo "Checking replica set status..."
mongosh --eval 'rs.status();'

echo "Replica set initialization complete!"