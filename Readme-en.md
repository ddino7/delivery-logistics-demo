# Delivery Logistics System - README

**Delivery and Logistics Management System**

**Authors:** Tin Barbarić, Dino Drčec

---

## Table of Contents

- [System Overview](#system-overview)
- [Features by Phase](#features-by-phase)
- [Prerequisites](#prerequisites)
- [Installation and Deployment](#installation-and-deployment)
- [Accessing Services](#accessing-services)
- [Web Interface](#web-interface)
- [Demo Script](#demo-script)
- [System Architecture](#system-architecture)
- [System Management](#system-management)
- [Troubleshooting](#troubleshooting)

---

## System Overview

The **Delivery Logistics System** is a comprehensive platform for managing deliveries, integrating shipment management, route optimization across a distribution network, real-time GPS vehicle tracking, and advanced analytics and search capabilities.

### Estimated Deployment Time

- **Normal Deployment:** 4-6 minutes
- **With Full Cleanup:** 5-7 minutes
- **First Run (Downloading Images):** 8-12 minutes

### Minimum System Requirements

- **RAM:** 8 GB (16 GB recommended)
- **Disk Space:** 10 GB free
- **CPU:** Dual-core processor (Quad-core recommended)
- **OS:** Linux (Tested on WSL2/Windows 11, likely works on native Linux environments)

---

## Features by Phase

### **Phase 1: Shipment Management**

Basic functionality for creating and managing shipments.

**Features:**
- Create shipments with details (sender, recipient, weight, addresses, products)
- Update shipment status (CREATED, WAREHOUSE, IN_TRANSIT, DELIVERED)
- Search shipments by tracking number
- Load balancing via Nginx server

**Technologies:**
- **Web Server:** Python Flask (3 instances)
- **Load Balancer:** Nginx
- **Database:** MongoDB replica set (1 primary + 2 secondary)

**Why MongoDB:** Allows easy modeling of shipments as documents with variable product lists and easier horizontal scalability.

---

### **Phase 2: Network Optimization and Routes**

Adds a graph database to model the logistics network and calculate optimal routes.

**Features:**
- Display the network of distribution centers and warehouses
- Calculate optimal routes between locations
- Visualize connections between shipments, vehicles, and distribution centers
- Graph analysis of the logistics network

**Technologies:**
- **Graph Database:** Neo4j (distribution centers as nodes, routes as edges)
- **Route Attributes:** Distance, time, cost

**Why Neo4j:** Ideal for modeling complex distribution networks with fast shortest path calculations and route optimization.

---

### **Phase 3: Real-Time Tracking and Analytics**

Adds stream processing, log aggregation, and advanced analytics.

**Features:**
- Real-time GPS vehicle tracking
- Display current vehicle positions on a map
- Advanced shipment search (tracking number, status, recipient)
- Visualization of key metrics:
  - Number of shipments by status
  - Average delivery time
  - Delays and performance
- Centralized logging and analysis

**Technologies:**
- **Message Broker:** Redpanda (Kafka-compatible)
- **Log Aggregation:** Fluent Bit
- **Search:** OpenSearch
- **Visualization:** OpenSearch Dashboards (Kibana-compatible)
- **GPS Consumer:** Python (Kafka consumer)

---

### **Phase 4: Machine Learning (APVO - Optional)**

Predict estimated delivery time using historical data.

**Features:**
- Predict ETA (Estimated Time of Arrival)
- Analyze historical data
- Model training based on:
  - Historical deliveries
  - Distance between locations
  - Current GPS data

**Technologies:**
- **ML Serving:** TBD
- **Batch Processing:** TBD

---

## Prerequisites

### Required Software

1. **Docker** (version 20.10 or newer)
   ```bash
   docker --version
   ```

2. **Docker Compose** (version 2.0 or newer)
   ```bash
   docker compose version
   # or
   docker-compose --version
   ```

3. **Sudo Access** (required for Neo4j initialization)

### Installing Docker on WSL2/Ubuntu

```bash
# Update package list
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Restart terminal or logout/login
```

---

## Installation and Deployment

### 1. Clone the Project

```bash
cd ~
git clone <repository-url> delivery-logistics-demo
cd delivery-logistics-demo
```

### 2. Prepare the Deployment Script

The project includes two versions of the deployment script:
- **`deploy.sh`** - Croatian version (recommended)
- **`deploy-en.sh`** - English version

```bash
cd scripts

# Grant executable permissions
chmod +x ./deploy.sh

# Or for the English version
chmod +x ./deploy-en.sh
```

### 3. Run the Deployment

```bash
# Start deployment
./deploy.sh
```

### 4. Interactive Setup

The script will guide you through the process:

#### **Step 1: Check Prerequisites**
Automatically checks for Docker and Docker Compose.

#### **Step 2: Optional Cleanup**
```
Do you want to perform a full cleanup before deployment?
This will delete all containers, networks, and volumes (all data will be lost!).
Recommended if you have network issues or want a fresh start. (Y/n):
```

**Recommendations:**
- **Press `Y`** for the first time or if you have issues
- **Press `n`** for a faster restart without data loss

#### **Step 3: Automatic Deployment**

The script will automatically:

1. Stop existing services (if any)
2. Start MongoDB replica set (primary + 2 secondary)
   - Waits 15 seconds for stabilization
3. Initialize MongoDB replica set
   - Configures replication
4. Start Neo4j graph database
   - Waits 20 seconds for startup
   - **REQUIRES SUDO PASSWORD** for network initialization
5. Start Phase 3 services (Kafka, GPS, ELK)
   - Waits 15 seconds for Kafka
6. Start web services (Flask + Nginx)

#### **Step 4: Verify Service Status**

The script displays the status of all services:

```
=== Service Status Overview ===

Phase 2:
NAME                      STATUS              PORTS
phase2_mongo_primary      Up (healthy)        0.0.0.0:27017->27017/tcp
phase2_mongo_secondary1   Up (healthy)        0.0.0.0:27018->27017/tcp
phase2_mongo_secondary2   Up (healthy)        0.0.0.0:27019->27017/tcp
phase2_neo4j              Up (healthy)        0.0.0.0:7474->7474/tcp, 0.0.0.0:7687->7687/tcp
phase2_nginx              Up                  0.0.0.0:80->80/tcp
phase2_opensearch         Up                  0.0.0.0:9200->9200/tcp
phase2_web1               Up                  5000/tcp
phase2_web2               Up                  5000/tcp
phase2_web3               Up                  5000/tcp

Phase 3:
NAME                           STATUS              PORTS
phase3_redpanda                Up                  0.0.0.0:9092->9092/tcp
phase3_location_consumer       Up
phase3_fluentbit_v2            Up                  2020/tcp
phase3_opensearch_dashboards   Up                  0.0.0.0:5601->5601/tcp
```

---

## Accessing Services

After deployment, the following services are available:

| Service | URL | Description | Credentials |
|---------|-----|-------------|-------------|
| **Web Application** | http://localhost | Main interface for managing shipments | - |
| **Neo4j Browser** | http://localhost:7474 | Graph database - view distribution network | user: `neo4j`<br>pass: `deliverypass123` |
| **OpenSearch** | http://localhost:9200 | Search engine API | - |
| **Kibana/Dashboards** | http://localhost:5601 | Visualization of metrics and logs | - |

---

## Web Interface

The system has an intuitive web interface available at **http://localhost** for managing shipments.

### Creating Shipments

1. **Navigation:** Open http://localhost/create
2. **Enter Data:**
   - Sender and recipient (name, address)
   - Shipment weight
   - Products
   - **Select City** (automatically used for route calculation)
3. **Route Optimization:**
   - The system automatically calculates the optimal route
   - You can choose the attribute for optimization:
     - **Distance** - shortest route
     - **Time** - fastest route
     - **Cost** - cheapest route
4. **Create:** The shipment receives a unique tracking number and is saved in MongoDB

### Shipment Database - CRUD Operations

After creation, all shipments are available in the database where you can perform:

- **Create:** Add new shipments
- **Read:** View all shipments and their details
- **Update:**
  - Edit shipment data
  - **Change Status** (CREATED → WAREHOUSE → IN_TRANSIT → DELIVERED)
  - Edit route or other attributes
- **Delete:** Remove shipments from the system

### Real-Time Tracking (IN_TRANSIT Status)

When the shipment status changes to **"IN_TRANSIT"**, GPS tracking is activated:

1. **Automatic Start:** The shipment starts its calculated route
2. **Visualization:** Open http://localhost/map
3. **Truck Tracking:**
   - The truck is displayed on an interactive map
   - Follows the exact route calculated at creation
   - **Scaled Time:** Simulation runs 100x faster than real time
   - Real-time position updates
4. **GPS Events:** Each GPS event is sent via Kafka and stored in OpenSearch

### Search and Filtering

The system allows advanced shipment search by:
- **Tracking Number:** Find a specific shipment
- **Status:** Filter by current state (IN_TRANSIT, DELIVERED, etc.)
- **Recipient:** Search by recipient name
- **City:** Filter by destination

---

## Demo Script

The project includes a **`demo.sh`** script that automatically tests all system functionalities through 38 different tests organized by phase.

### Running the Demo Script

```bash
cd scripts
chmod +x ./demo.sh
./demo.sh
```

### What the Demo Script Does

The demo script performs comprehensive system testing organized into 4 phases plus end-to-end tests:

#### **PHASE 1: Shipment Management and Load Balancing (7 tests)**

1. **Load Balancer Test (Enhanced):**
   - Sends 50 HTTP requests to Nginx
   - Analyzes request distribution across web1, web2, web3
   - Displays percentage distribution and average response time
   - Verifies balanced load distribution (max deviation < 10%)

2. **MongoDB Replica Set Configuration:**
   - Checks the status of all replica set members
   - Verifies 1 PRIMARY + 2 SECONDARY configuration
   - Displays a table with all members and their statuses

3. **MongoDB Replication (Write/Read Separation):**
   - Tests writing to the PRIMARY node
   - Verifies data propagation to SECONDARY-1
   - Verifies data propagation to SECONDARY-2
   - Checks logical data consistency across all nodes

4. **Read Preference (Demonstration of Read Distribution):**
   - Creates a test dataset of 10 documents
   - Reads data from all nodes (PRIMARY and both SECONDARY)
   - Demonstrates the ability to distribute reads across the replica set
   - Verifies identical data on all nodes

5. **Creating a Shipment:**
   - Creates a test shipment via API
   - Verifies tracking number generation
   - Checks route calculation (distance, time, cost)

6. **Updating Status:**
   - Tests status transitions
   - IN_WAREHOUSE → IN_TRANSIT → DELIVERED

7. **Tracking Functionality:**
   - Tests search by tracking number

#### **PHASE 2: Logistics Network and Graph Database (5 tests)**

1. **Neo4j Connection:**
   - Checks Neo4j database availability

2. **Network Nodes:**
   - Counts Distribution Centers (4)
   - Counts Warehouses (7)

3. **Routes and Relationships:**
   - Verifies the existence of 334 routes in the network
   - Checks dynamic calculation of attributes (distance, time, cost)

4. **Optimal Route Calculation:**
   - Tests the shortest path algorithm (Zagreb → Rijeka)
   - Verifies route calculation functionality

5. **Network Visualization:**
   - Checks the API for network statistics

#### **PHASE 3: Real-Time Tracking and Analytics (7 tests)**

1. **Event Streaming (Kafka/Redpanda):**
   - Checks Kafka cluster health
   - Verifies the existence of the 'vehicle-location-events' topic

2. **GPS Event Streaming:**
   - Checks the status of the location consumer service

3. **Real-Time Vehicle Tracking:**
   - Verifies that the vehicle simulator is running
   - Displays the number of currently tracked vehicles

4. **Centralized Logging (Fluent Bit):**
   - Checks if Fluent Bit is running
   - Verifies log processing

5. **Indexing (OpenSearch):**
   - Checks OpenSearch cluster health
   - Counts indexed shipments

6. **Advanced Search:**
   - Tests search API functionality

7. **Dashboards:**
   - Verifies OpenSearch Dashboards availability on port 5601

#### **PHASE 4: Predictive Delivery - Optional (1 test)**

1. **ETA Service:**
   - Tests estimated delivery time prediction
   - Uses heuristic predictions (ML model is optional)
   - Displays the source of prediction (heuristic or ML)

#### **End-to-End Integration Test (1 test)**

1. **Complete Shipment Lifecycle:**
   - Step 1: Create a shipment
   - Step 2: Set status to IN_TRANSIT
   - Step 3: Track via API
   - Step 4: Verify route and vehicle simulation

### Visual Features of the Demo Script

- **Tabular Display:** Load distribution, replica set members, route attributes
- **Progress Bar:** Shows progress during load balancer testing
- **Graphical Displays:** Visual distribution of requests across servers
- **Colors and Icons:** Green checkmarks for success, yellow for warnings
- **Structured Output:** Clearly organized by phase with graphics

### Uses of the Demo Script

- **Automatic Verification:** Quickly check if all components are working after deployment
- **Regression Testing:** Verify that changes haven't broken existing functionality
- **Feature Demonstration:** Show all system features in 2-3 minutes
- **Debugging Tool:** Identify which component is not working correctly
- **Documentation:** See practical examples of how to use each part of the system

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS / BROWSERS                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  NGINX (LB)    │  ← Load Balancer
                    └────────┬───────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         ┌────────┐     ┌────────┐     ┌────────┐
         │ Web 1  │     │ Web 2  │     │ Web 3  │  ← Flask Apps
         └────┬───┘     └────┬───┘     └────┬───┘
              └──────────────┼──────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
    ┌─────────┐         ┌─────────┐        ┌─────────┐
    │ MongoDB │◄───────►│ MongoDB │◄──────►│ MongoDB │
    │ Primary │         │ Second1 │        │ Second2 │
    └─────────┘         └─────────┘        └─────────┘
         ▲
         │                   ┌──────────────┐
         │                   │    Neo4j     │  ← Graph DB
         │                   └──────────────┘
         │
         │              ┌────────────────────────────┐
         └──────────────┤  GPS Location Producer     │
                        └────────────┬───────────────┘
                                     ▼
                             ┌───────────────┐
                             │   Redpanda    │  ← Kafka
                             │   (Kafka)     │
                             └───────┬───────┘
                                     ▼
                        ┌─────────────────────┐
                        │ Location Consumer   │
                        └──────────┬──────────┘
                                   ▼
                         ┌──────────────────┐
                         │   OpenSearch     │  ← Search & Analytics
                         └──────────┬───────┘
                                    │
                           ┌────────┴─────────┐
                           │  Fluent Bit      │  ← Log Aggregation
                           └──────────────────┘
                                    │
                                    ▼
                         ┌──────────────────┐
                         │ OpenSearch       │  ← Visualization
                         │ Dashboards       │
                         └──────────────────┘
```

### Components

#### **Load Balancing Layer**
- **Nginx:** Round-robin distribution of requests to 3 Flask instances

#### **Application Layer**
- **Flask Web Servers (x3):** Python web applications
  - Shipment management
  - REST API
  - GPS tracking

#### **Data Layer**
- **MongoDB Replica Set:**
  - 1x Primary (port 27017)
  - 2x Secondary (ports 27018, 27019)
  - Automatic failover

- **Neo4j Graph Database:**
  - Models the logistics network
  - Route optimization

#### **Streaming Layer**
- **Redpanda (Kafka):** Message broker for GPS events
- **Location Consumer:** Python service for processing GPS streams
- **Fluent Bit:** Log aggregation from all containers

#### **Analytics Layer**
- **OpenSearch:** Indexing and search
- **OpenSearch Dashboards:** Metrics visualization

---

## System Management

### Viewing Logs

#### All Services at Once (Phase 2)
```bash
docker-compose -f phase2/docker-compose.phase2.yml logs -f
```

#### All Services at Once (Phase 3)
```bash
docker-compose -f docker-compose.phase3.yml logs -f
```

#### Individual Services
```bash
# MongoDB Primary
docker logs -f phase2_mongo_primary

# Neo4j
docker logs -f phase2_neo4j

# Web Services
docker logs -f phase2_web1
docker logs -f phase2_web2
docker logs -f phase2_web3

# Nginx
docker logs -f phase2_nginx

# Kafka/Redpanda
docker logs -f phase3_redpanda

# GPS Consumer
docker logs -f phase3_location_consumer

# OpenSearch
docker logs -f phase2_opensearch
```

### Stopping the System

#### Stop All Services (Phase 2)
```bash
cd phase2
docker-compose -f docker-compose.phase2.yml down
```

#### Stop All Services (Phase 3)
```bash
docker-compose -f docker-compose.phase3.yml down
```

#### Stop ALL and Delete Data
```bash
cd phase2
docker-compose -f docker-compose.phase2.yml down -v

cd ..
docker-compose -f docker-compose.phase3.yml down -v
```

**WARNING:** The `-v` flag deletes volumes (all data)!

### Restarting

```bash
# Simply rerun the deployment script
cd scripts
./deploy.sh

# Answer 'n' to the cleanup question if you want to keep data
```

### Checking Service Status

```bash
# Phase 2
docker-compose -f phase2/docker-compose.phase2.yml ps

# Phase 3
docker-compose -f docker-compose.phase3.yml ps

# Or all Docker containers
docker ps -a
```

### Restarting an Individual Service

```bash
# Example: restart web1 service
docker restart phase2_web1

# Example: restart MongoDB primary
docker restart phase2_mongo_primary
```

---

## Troubleshooting

### Issue: Port Already in Use

**Symptoms:**
```
Error: bind: address already in use
```

**Solution:**
```bash
# Find which process is using the port (e.g., 80)
sudo lsof -i :80

# Stop the process or change the port in docker-compose.yml
```

### Issue: MongoDB Replica Set Not Initializing

**Symptoms:**
```
Error: Replica set not initialized
```

**Solution:**
```bash
# Manual initialization
docker exec -it phase2_mongo_primary mongosh

# In the mongo shell:
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
});

# Check status
rs.status();
```

### Issue: Neo4j Not Accepting Connections

**Symptoms:**
```
ServiceUnavailable: WebSocket connection failure
```

**Solution:**
```bash
# Wait longer (may take up to 30-60 seconds)
docker logs -f phase2_neo4j

# When you see "Started.", open the browser
# http://localhost:7474
```

### Issue: Missing Sudo Access for Neo4j Init

**Symptoms:**
```
Permission denied: cannot chown neo4j directory
```

**Solution:**
```bash
# Manually change ownership
sudo chown -R $USER:$USER ./phase2/neo4j/

# Rerun init
docker exec -i phase2_neo4j cypher-shell -u neo4j -p deliverypass123 \
  < ./phase2/neo4j/import/init-network.cypher
```

### Issue: Kafka/Redpanda Not Starting

**Symptoms:**
```
Redpanda startup timeout
```

**Solution:**
```bash
# Check logs
docker logs phase3_redpanda

# Restart
docker restart phase3_redpanda

# Wait 20-30 seconds
```

### Issue: Insufficient RAM

**Symptoms:**
```
Cannot allocate memory
Killed
```

**Solution:**
```bash
# Check Docker memory
docker stats

# Increase in Docker Desktop settings:
# Settings → Resources → Memory → 8GB+

# Or stop unnecessary services
```

### Issue: "Network not found" Error

**Symptoms:**
```
Error: network phase2_delivery-network not found
```

**Solution:**
```bash
# Full cleanup and restart
./deploy.sh
# Answer 'Y' to the cleanup question
```

### Debugging Checklist

When something isn't working:

1. **Check if Docker is running:**
   ```bash
   docker ps
   ```

2. **Check logs:**
   ```bash
   docker-compose -f phase2/docker-compose.phase2.yml logs
   ```

3. **Check disk space:**
   ```bash
   df -h
   ```

4. **Check memory:**
   ```bash
   free -h
   docker stats
   ```

5. **Full restart:**
   ```bash
   ./deploy.sh  # Answer 'Y' to cleanup
   ```

---

## Contact and Support

**Authors:**
- Tin Barbarić
- Dino Drčec

---

**Successful deployment!**

The system is now ready for use. Access the web application at **http://localhost** and start managing your deliveries!