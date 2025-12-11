// Initialize Logistics Network
// Distribution Centers and Warehouses for Croatia

// Clear existing data (for testing)
MATCH (n) DETACH DELETE n;

// Create Distribution Centers (Main hubs)
CREATE (dc_zg:DistributionCenter {
  id: 'DC_ZG',
  name: 'Zagreb Distribution Center',
  city: 'Zagreb',
  address: 'Zagrebačka avenija 100',
  type: 'main_hub',
  capacity: 10000,
  lat: 45.8150,
  lon: 15.9819
});

CREATE (dc_st:DistributionCenter {
  id: 'DC_ST',
  name: 'Split Distribution Center',
  city: 'Split',
  address: 'Put Supavla 1',
  type: 'main_hub',
  capacity: 5000,
  lat: 43.5081,
  lon: 16.4402
});

CREATE (dc_ri:DistributionCenter {
  id: 'DC_RI',
  name: 'Rijeka Distribution Center',
  city: 'Rijeka',
  address: 'Škurinjska cesta 28',
  type: 'main_hub',
  capacity: 4000,
  lat: 45.3271,
  lon: 14.4419
});

CREATE (dc_os:DistributionCenter {
  id: 'DC_OS',
  name: 'Osijek Distribution Center',
  city: 'Osijek',
  address: 'Industrijska zona Nemetin',
  type: 'main_hub',
  capacity: 3000,
  lat: 45.5550,
  lon: 18.6955
});

// Create Warehouses (Secondary hubs)
CREATE (wh_ka:Warehouse {
  id: 'WH_KA',
  name: 'Karlovac Warehouse',
  city: 'Karlovac',
  address: 'Industrijska 5',
  type: 'regional',
  capacity: 1500,
  lat: 45.4870,
  lon: 15.5478
});

CREATE (wh_zd:Warehouse {
  id: 'WH_ZD',
  name: 'Zadar Warehouse',
  city: 'Zadar',
  address: 'Gaženička cesta 12',
  type: 'regional',
  capacity: 2000,
  lat: 44.1194,
  lon: 15.2314
});

CREATE (wh_sb:Warehouse {
  id: 'WH_SB',
  name: 'Slavonski Brod Warehouse',
  city: 'Slavonski Brod',
  address: 'Industrijska zona',
  type: 'regional',
  capacity: 1000,
  lat: 45.1600,
  lon: 18.0158
});

CREATE (wh_pu:Warehouse {
  id: 'WH_PU',
  name: 'Pula Warehouse',
  city: 'Pula',
  address: 'Industrijska 8',
  type: 'regional',
  capacity: 1800,
  lat: 44.8666,
  lon: 13.8496
});

CREATE (wh_du:Warehouse {
  id: 'WH_DU',
  name: 'Dubrovnik Warehouse',
  city: 'Dubrovnik',
  address: 'Mokošica Shipyard Area',
  type: 'coastal',
  capacity: 800,
  lat: 42.6507,
  lon: 18.0944
});

CREATE (wh_vz:Warehouse {
  id: 'WH_VZ',
  name: 'Varaždin Warehouse',
  city: 'Varaždin',
  address: 'Industrijska zona Zapad',
  type: 'regional',
  capacity: 1200,
  lat: 46.3059,
  lon: 16.3366
});

CREATE (wh_si:Warehouse {
  id: 'WH_SI',
  name: 'Šibenik Warehouse',
  city: 'Šibenik',
  address: 'Industrijska zona',
  type: 'coastal',
  capacity: 900,
  lat: 43.7350,
  lon: 15.8952
});

// Create Routes between Distribution Centers (main highways)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'})
MATCH (dc_st:DistributionCenter {id: 'DC_ST'})
CREATE (dc_zg)-[:ROUTE {
  distance_km: 380,
  avg_time_hours: 4.0,
  cost_per_km: 1.5,
  road_type: 'highway',
  active: true
}]->(dc_st);

MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'})
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'})
CREATE (dc_zg)-[:ROUTE {
  distance_km: 165,
  avg_time_hours: 2.0,
  cost_per_km: 1.5,
  road_type: 'highway',
  active: true
}]->(dc_ri);

MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'})
MATCH (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE (dc_zg)-[:ROUTE {
  distance_km: 280,
  avg_time_hours: 3.5,
  cost_per_km: 1.5,
  road_type: 'highway',
  active: true
}]->(dc_os);

MATCH (dc_ri:DistributionCenter {id: 'DC_RI'})
MATCH (dc_st:DistributionCenter {id: 'DC_ST'})
CREATE (dc_ri)-[:ROUTE {
  distance_km: 420,
  avg_time_hours: 5.0,
  cost_per_km: 1.5,
  road_type: 'highway',
  active: true
}]->(dc_st);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'})
MATCH (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE (dc_st)-[:ROUTE {
  distance_km: 460,
  avg_time_hours: 5.5,
  cost_per_km: 1.5,
  road_type: 'highway',
  active: true
}]->(dc_os);

// Connect Warehouses to Distribution Centers
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'})
MATCH (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_zg)-[:ROUTE {
  distance_km: 55,
  avg_time_hours: 0.75,
  cost_per_km: 1.2,
  road_type: 'regional',
  active: true
}]->(wh_ka);

MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'})
MATCH (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (dc_zg)-[:ROUTE {
  distance_km: 80,
  avg_time_hours: 1.0,
  cost_per_km: 1.2,
  road_type: 'regional',
  active: true
}]->(wh_vz);

MATCH (dc_ri:DistributionCenter {id: 'DC_RI'})
MATCH (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (dc_ri)-[:ROUTE {
  distance_km: 105,
  avg_time_hours: 1.5,
  cost_per_km: 1.2,
  road_type: 'regional',
  active: true
}]->(wh_pu);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'})
MATCH (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (dc_st)-[:ROUTE {
  distance_km: 155,
  avg_time_hours: 2.0,
  cost_per_km: 1.2,
  road_type: 'highway',
  active: true
}]->(wh_zd);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'})
MATCH (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_st)-[:ROUTE {
  distance_km: 85,
  avg_time_hours: 1.25,
  cost_per_km: 1.2,
  road_type: 'regional',
  active: true
}]->(wh_si);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'})
MATCH (wh_du:Warehouse {id: 'WH_DU'})
CREATE (dc_st)-[:ROUTE {
  distance_km: 230,
  avg_time_hours: 3.0,
  cost_per_km: 1.3,
  road_type: 'coastal',
  active: true
}]->(wh_du);

MATCH (dc_os:DistributionCenter {id: 'DC_OS'})
MATCH (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_os)-[:ROUTE {
  distance_km: 60,
  avg_time_hours: 0.8,
  cost_per_km: 1.2,
  road_type: 'regional',
  active: true
}]->(wh_sb);

// Bidirectional routes (create reverse routes)
MATCH (a)-[r:ROUTE]->(b)
WHERE NOT EXISTS((b)-[:ROUTE]->(a))
CREATE (b)-[:ROUTE {
  distance_km: r.distance_km,
  avg_time_hours: r.avg_time_hours,
  cost_per_km: r.cost_per_km,
  road_type: r.road_type,
  active: r.active
}]->(a);

// Create indexes for performance
CREATE INDEX dc_id IF NOT EXISTS FOR (dc:DistributionCenter) ON (dc.id);
CREATE INDEX dc_city IF NOT EXISTS FOR (dc:DistributionCenter) ON (dc.city);
CREATE INDEX wh_id IF NOT EXISTS FOR (wh:Warehouse) ON (wh.id);
CREATE INDEX wh_city IF NOT EXISTS FOR (wh:Warehouse) ON (wh.city);

// Return summary
MATCH (dc:DistributionCenter) 
WITH count(dc) as dcCount
MATCH (wh:Warehouse)
WITH dcCount, count(wh) as whCount
MATCH ()-[r:ROUTE]->()
RETURN dcCount as DistributionCenters, 
       whCount as Warehouses, 
       count(r) as Routes;