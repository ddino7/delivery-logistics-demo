// Clear existing data
MATCH (n) DETACH DELETE n;

// ============ CREATE NODES ============

// Distribution Centers
CREATE (dc_zg:DistributionCenter {
  id: 'DC_ZG', name: 'Zagreb Distribution Center', city: 'Zagreb',
  address: 'Zagrebačka avenija 100', type: 'main_hub', capacity: 10000,
  lat: 45.8150, lon: 15.9819
});

CREATE (dc_st:DistributionCenter {
  id: 'DC_ST', name: 'Split Distribution Center', city: 'Split',
  address: 'Put Supavla 1', type: 'main_hub', capacity: 5000,
  lat: 43.5081, lon: 16.4402
});

CREATE (dc_ri:DistributionCenter {
  id: 'DC_RI', name: 'Rijeka Distribution Center', city: 'Rijeka',
  address: 'Škurinjska cesta 28', type: 'main_hub', capacity: 4000,
  lat: 45.3271, lon: 14.4419
});

CREATE (dc_os:DistributionCenter {
  id: 'DC_OS', name: 'Osijek Distribution Center', city: 'Osijek',
  address: 'Industrijska zona Nemetin', type: 'main_hub', capacity: 3000,
  lat: 45.5550, lon: 18.6955
});

// Warehouses
CREATE (wh_ka:Warehouse {id: 'WH_KA', name: 'Karlovac Warehouse', city: 'Karlovac',
  address: 'Industrijska 5', type: 'regional', capacity: 1500, lat: 45.4870, lon: 15.5478});

CREATE (wh_zd:Warehouse {id: 'WH_ZD', name: 'Zadar Warehouse', city: 'Zadar',
  address: 'Gaženička cesta 12', type: 'regional', capacity: 2000, lat: 44.1194, lon: 15.2314});

CREATE (wh_sb:Warehouse {id: 'WH_SB', name: 'Slavonski Brod Warehouse', city: 'Slavonski Brod',
  address: 'Industrijska zona', type: 'regional', capacity: 1000, lat: 45.1600, lon: 18.0158});

CREATE (wh_pu:Warehouse {id: 'WH_PU', name: 'Pula Warehouse', city: 'Pula',
  address: 'Industrijska 8', type: 'regional', capacity: 1800, lat: 44.8666, lon: 13.8496});

CREATE (wh_du:Warehouse {id: 'WH_DU', name: 'Dubrovnik Warehouse', city: 'Dubrovnik',
  address: 'Mokošica Shipyard Area', type: 'coastal', capacity: 800, lat: 42.6507, lon: 18.0944});

CREATE (wh_vz:Warehouse {id: 'WH_VZ', name: 'Varaždin Warehouse', city: 'Varazdin',
  address: 'Industrijska zona Zapad', type: 'regional', capacity: 1200, lat: 46.3059, lon: 16.3366});

CREATE (wh_si:Warehouse {id: 'WH_SI', name: 'Šibenik Warehouse', city: 'Sibenik',
  address: 'Industrijska zona', type: 'coastal', capacity: 900, lat: 43.7350, lon: 15.8952});

// ============ RUTE IZMEĐU SVIH GRADOVA (3+ po paru) ============

// ZAGREB ↔ SPLIT
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (dc_st:DistributionCenter {id: 'DC_ST'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 380, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 380, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 400, avg_time_hours: 4.5, cost_per_km: 1.3, road_type: 'regional'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 400, avg_time_hours: 4.5, cost_per_km: 1.3, road_type: 'regional'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 370, avg_time_hours: 3.9, cost_per_km: 1.7, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 370, avg_time_hours: 3.9, cost_per_km: 1.7, road_type: 'highway'}]->(dc_zg);

// ZAGREB ↔ RIJEKA
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (dc_ri:DistributionCenter {id: 'DC_RI'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 165, avg_time_hours: 2.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 165, avg_time_hours: 2.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 150, avg_time_hours: 1.8, cost_per_km: 1.6, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 150, avg_time_hours: 1.8, cost_per_km: 1.6, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 180, avg_time_hours: 2.3, cost_per_km: 1.3, road_type: 'regional'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 180, avg_time_hours: 2.3, cost_per_km: 1.3, road_type: 'regional'}]->(dc_zg);

// ZAGREB ↔ OSIJEK
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.5, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 260, avg_time_hours: 3.2, cost_per_km: 1.6, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 260, avg_time_hours: 3.2, cost_per_km: 1.6, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.3, road_type: 'regional'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.3, road_type: 'regional'}]->(dc_zg);

// ZAGREB ↔ ZADAR
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 285, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 285, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'regional'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.7, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.7, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 295, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 295, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'regional'}]->(dc_zg);

// ZAGREB ↔ PULA
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 260, avg_time_hours: 3.3, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 260, avg_time_hours: 3.3, cost_per_km: 1.2, road_type: 'regional'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.5, road_type: 'highway'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.3, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.3, road_type: 'regional'}]->(dc_zg);

// ZAGREB ↔ DUBROVNIK
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.6, road_type: 'mixed'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.6, road_type: 'mixed'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 570, avg_time_hours: 6.8, cost_per_km: 1.7, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 570, avg_time_hours: 6.8, cost_per_km: 1.7, road_type: 'highway'}]->(dc_zg);

// ZAGREB ↔ KARLOVAC
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 55, avg_time_hours: 0.75, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 55, avg_time_hours: 0.75, cost_per_km: 1.2, road_type: 'regional'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 50, avg_time_hours: 0.7, cost_per_km: 1.4, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 50, avg_time_hours: 0.7, cost_per_km: 1.4, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 60, avg_time_hours: 0.9, cost_per_km: 1.1, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 60, avg_time_hours: 0.9, cost_per_km: 1.1, road_type: 'regional'}]->(dc_zg);

// ZAGREB ↔ VARAŽDIN
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 80, avg_time_hours: 1.0, cost_per_km: 1.2, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 80, avg_time_hours: 1.0, cost_per_km: 1.2, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 75, avg_time_hours: 0.9, cost_per_km: 1.4, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 75, avg_time_hours: 0.9, cost_per_km: 1.4, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 85, avg_time_hours: 1.2, cost_per_km: 1.1, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 85, avg_time_hours: 1.2, cost_per_km: 1.1, road_type: 'regional'}]->(dc_zg);

// ZAGREB ↔ SLAVONSKI BROD
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 200, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'highway'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 200, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'regional'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 190, avg_time_hours: 2.4, cost_per_km: 1.5, road_type: 'highway'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 190, avg_time_hours: 2.4, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg);

// ZAGREB ↔ ŠIBENIK
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (dc_zg)-[:ROUTE {distance_km: 320, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 320, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 350, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 350, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(dc_zg),
  (dc_zg)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.8, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.8, road_type: 'highway'}]->(dc_zg);

// SPLIT ↔ RIJEKA
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (dc_ri:DistributionCenter {id: 'DC_RI'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 420, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 420, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 400, avg_time_hours: 4.7, cost_per_km: 1.6, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 400, avg_time_hours: 4.7, cost_per_km: 1.6, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 440, avg_time_hours: 5.3, cost_per_km: 1.3, road_type: 'regional'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 440, avg_time_hours: 5.3, cost_per_km: 1.3, road_type: 'regional'}]->(dc_ri);

// SPLIT ↔ OSIJEK
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 460, avg_time_hours: 5.5, cost_per_km: 1.6, road_type: 'regional'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 460, avg_time_hours: 5.5, cost_per_km: 1.6, road_type: 'regional'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 440, avg_time_hours: 5.2, cost_per_km: 1.5, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 440, avg_time_hours: 5.2, cost_per_km: 1.5, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 480, avg_time_hours: 6.0, cost_per_km: 1.3, road_type: 'regional'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 480, avg_time_hours: 6.0, cost_per_km: 1.3, road_type: 'regional'}]->(dc_st);

// SPLIT ↔ ZADAR
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 155, avg_time_hours: 2.0, cost_per_km: 1.2, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 155, avg_time_hours: 2.0, cost_per_km: 1.2, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 145, avg_time_hours: 1.8, cost_per_km: 1.4, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 145, avg_time_hours: 1.8, cost_per_km: 1.4, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 165, avg_time_hours: 2.2, cost_per_km: 1.1, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 165, avg_time_hours: 2.2, cost_per_km: 1.1, road_type: 'regional'}]->(dc_st);

// SPLIT ↔ PULA
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.3, road_type: 'coastal'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 260, avg_time_hours: 3.5, cost_per_km: 1.5, road_type: 'highway'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 260, avg_time_hours: 3.5, cost_per_km: 1.5, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 290, avg_time_hours: 4.0, cost_per_km: 1.2, road_type: 'coastal'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 290, avg_time_hours: 4.0, cost_per_km: 1.2, road_type: 'coastal'}]->(dc_st);

// SPLIT ↔ DUBROVNIK
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 230, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 230, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'coastal'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.6, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.6, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 240, avg_time_hours: 3.2, cost_per_km: 1.3, road_type: 'regional'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 240, avg_time_hours: 3.2, cost_per_km: 1.3, road_type: 'regional'}]->(dc_st);

// SPLIT ↔ KARLOVAC
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 340, avg_time_hours: 4.5, cost_per_km: 1.1, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 340, avg_time_hours: 4.5, cost_per_km: 1.1, road_type: 'regional'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 280, avg_time_hours: 3.2, cost_per_km: 1.7, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 280, avg_time_hours: 3.2, cost_per_km: 1.7, road_type: 'highway'}]->(dc_st);

// SPLIT ↔ VARAŽDIN
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 400, avg_time_hours: 4.5, cost_per_km: 1.6, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 400, avg_time_hours: 4.5, cost_per_km: 1.6, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 380, avg_time_hours: 4.2, cost_per_km: 1.7, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 380, avg_time_hours: 4.2, cost_per_km: 1.7, road_type: 'highway'}]->(dc_st);

// SPLIT ↔ SLAVONSKI BROD
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 380, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 380, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 360, avg_time_hours: 4.2, cost_per_km: 1.5, road_type: 'highway'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 360, avg_time_hours: 4.2, cost_per_km: 1.5, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 400, avg_time_hours: 4.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 400, avg_time_hours: 4.8, cost_per_km: 1.2, road_type: 'regional'}]->(dc_st);

// SPLIT ↔ ŠIBENIK
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (dc_st)-[:ROUTE {distance_km: 85, avg_time_hours: 1.25, cost_per_km: 1.2, road_type: 'coastal'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 85, avg_time_hours: 1.25, cost_per_km: 1.2, road_type: 'coastal'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 80, avg_time_hours: 1.1, cost_per_km: 1.4, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 80, avg_time_hours: 1.1, cost_per_km: 1.4, road_type: 'highway'}]->(dc_st),
  (dc_st)-[:ROUTE {distance_km: 90, avg_time_hours: 1.4, cost_per_km: 1.1, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 90, avg_time_hours: 1.4, cost_per_km: 1.1, road_type: 'regional'}]->(dc_st);

// RIJEKA ↔ OSIJEK
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 340, avg_time_hours: 4.2, cost_per_km: 1.4, road_type: 'regional'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 340, avg_time_hours: 4.2, cost_per_km: 1.4, road_type: 'regional'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_ri),
  (dc_os)-[:ROUTE {distance_km: 380, avg_time_hours: 4.8, cost_per_km: 1.7, road_type: 'regional'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 380, avg_time_hours: 4.8, cost_per_km: 1.7, road_type: 'regional'}]->(dc_os);

// RIJEKA ↔ ZADAR
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 190, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 190, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'coastal'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 170, avg_time_hours: 2.2, cost_per_km: 1.5, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 170, avg_time_hours: 2.2, cost_per_km: 1.5, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 200, avg_time_hours: 2.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 200, avg_time_hours: 2.8, cost_per_km: 1.2, road_type: 'regional'}]->(dc_ri);

// RIJEKA ↔ PULA
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 105, avg_time_hours: 1.5, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 105, avg_time_hours: 1.5, cost_per_km: 1.3, road_type: 'coastal'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 95, avg_time_hours: 1.3, cost_per_km: 1.5, road_type: 'highway'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 95, avg_time_hours: 1.3, cost_per_km: 1.5, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 110, avg_time_hours: 1.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 110, avg_time_hours: 1.6, cost_per_km: 1.2, road_type: 'regional'}]->(dc_ri);

// RIJEKA ↔ DUBROVNIK
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.8, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.8, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.6, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.6, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.4, road_type: 'coastal'}]->(dc_ri);

// RIJEKA ↔ KARLOVAC
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 120, avg_time_hours: 1.6, cost_per_km: 1.2, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 120, avg_time_hours: 1.6, cost_per_km: 1.2, road_type: 'highway'}]->(dc_ri),
  (wh_ka)-[:ROUTE {distance_km: 115, avg_time_hours: 1.5, cost_per_km: 1.35, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 115, avg_time_hours: 1.5, cost_per_km: 1.35, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 125, avg_time_hours: 1.7, cost_per_km: 1.1, road_type: 'regional'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 125, avg_time_hours: 1.7, cost_per_km: 1.1, road_type: 'regional'}]->(wh_ka);

// RIJEKA ↔ VARAŽDIN
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 180, avg_time_hours: 2.2, cost_per_km: 1.1, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 180, avg_time_hours: 2.2, cost_per_km: 1.1, road_type: 'regional'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 160, avg_time_hours: 1.9, cost_per_km: 1.6, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 160, avg_time_hours: 1.9, cost_per_km: 1.6, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 190, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 190, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'regional'}]->(dc_ri);

// RIJEKA ↔ SLAVONSKI BROD
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 370, avg_time_hours: 4.7, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 370, avg_time_hours: 4.7, cost_per_km: 1.2, road_type: 'regional'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_ri);

// RIJEKA ↔ ŠIBENIK
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (dc_ri)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 260, avg_time_hours: 3.0, cost_per_km: 1.7, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 260, avg_time_hours: 3.0, cost_per_km: 1.7, road_type: 'highway'}]->(dc_ri),
  (dc_ri)-[:ROUTE {distance_km: 290, avg_time_hours: 3.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 290, avg_time_hours: 3.6, cost_per_km: 1.2, road_type: 'regional'}]->(dc_ri);

// OSIJEK ↔ ZADAR
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE 
  (dc_os)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 430, avg_time_hours: 5.0, cost_per_km: 1.7, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 430, avg_time_hours: 5.0, cost_per_km: 1.7, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(dc_os);

// OSIJEK ↔ PULA
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE 
  (dc_os)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os),
  (wh_pu)-[:ROUTE {distance_km: 510, avg_time_hours: 5.9, cost_per_km: 1.6, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 510, avg_time_hours: 5.9, cost_per_km: 1.6, road_type: 'highway'}]->(wh_pu);

// OSIJEK ↔ DUBROVNIK
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE 
  (dc_os)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.7, road_type: 'mixed'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.7, road_type: 'mixed'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 650, avg_time_hours: 8.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 650, avg_time_hours: 8.0, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_os);

// OSIJEK ↔ KARLOVAC
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE 
  (dc_os)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.7, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.7, road_type: 'highway'}]->(dc_os),
  (wh_ka)-[:ROUTE {distance_km: 280, avg_time_hours: 3.3, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 280, avg_time_hours: 3.3, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 320, avg_time_hours: 4.0, cost_per_km: 1.2, road_type: 'regional'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 320, avg_time_hours: 4.0, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka);

// OSIJEK ↔ VARAŽDIN
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (dc_os)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 200, avg_time_hours: 2.5, cost_per_km: 1.4, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 200, avg_time_hours: 2.5, cost_per_km: 1.4, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 230, avg_time_hours: 3.0, cost_per_km: 1.1, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 230, avg_time_hours: 3.0, cost_per_km: 1.1, road_type: 'regional'}]->(dc_os);

// OSIJEK ↔ SLAVONSKI BROD
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (dc_os)-[:ROUTE {distance_km: 60, avg_time_hours: 0.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 60, avg_time_hours: 0.8, cost_per_km: 1.2, road_type: 'regional'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 70, avg_time_hours: 0.9, cost_per_km: 1.4, road_type: 'highway'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 70, avg_time_hours: 0.9, cost_per_km: 1.4, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 55, avg_time_hours: 0.7, cost_per_km: 1.1, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 55, avg_time_hours: 0.7, cost_per_km: 1.1, road_type: 'regional'}]->(dc_os);

// OSIJEK ↔ ŠIBENIK
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (dc_os)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 420, avg_time_hours: 5.0, cost_per_km: 1.3, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 420, avg_time_hours: 5.0, cost_per_km: 1.3, road_type: 'regional'}]->(dc_os),
  (wh_si)-[:ROUTE {distance_km: 440, avg_time_hours: 5.3, cost_per_km: 1.6, road_type: 'highway'}]->(dc_os),
  (dc_os)-[:ROUTE {distance_km: 440, avg_time_hours: 5.3, cost_per_km: 1.6, road_type: 'highway'}]->(wh_si);

// ZADAR ↔ PULA
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE 
  (wh_pu)-[:ROUTE {distance_km: 165, avg_time_hours: 2.3, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 165, avg_time_hours: 2.3, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 155, avg_time_hours: 2.1, cost_per_km: 1.4, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 155, avg_time_hours: 2.1, cost_per_km: 1.4, road_type: 'highway'}]->(wh_pu),
  (wh_zd)-[:ROUTE {distance_km: 200, avg_time_hours: 2.4, cost_per_km: 1.6, road_type: 'highway'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 200, avg_time_hours: 2.4, cost_per_km: 1.6, road_type: 'highway'}]->(wh_zd);

// ZADAR ↔ DUBROVNIK
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE 
  (wh_zd)-[:ROUTE {distance_km: 285, avg_time_hours: 3.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 285, avg_time_hours: 3.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 330, avg_time_hours: 4.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 330, avg_time_hours: 4.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd);

// ZADAR ↔ KARLOVAC
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE 
  (wh_ka)-[:ROUTE {distance_km: 190, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 190, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 220, avg_time_hours: 2.6, cost_per_km: 1.7, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 220, avg_time_hours: 2.6, cost_per_km: 1.7, road_type: 'highway'}]->(wh_ka),
  (wh_zd)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd);

// ZADAR ↔ VARAŽDIN
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (wh_zd)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 330, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 330, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_zd),
  (wh_vz)-[:ROUTE {distance_km: 340, avg_time_hours: 4.0, cost_per_km: 1.7, road_type: 'highway'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 340, avg_time_hours: 4.0, cost_per_km: 1.7, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 360, avg_time_hours: 4.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 360, avg_time_hours: 4.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_vz);

// ZADAR ↔ SLAVONSKI BROD
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (wh_sb)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
  (wh_zd)-[:ROUTE {distance_km: 370, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 370, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd);

// ZADAR ↔ ŠIBENIK
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (wh_zd)-[:ROUTE {distance_km: 72, avg_time_hours: 1.1, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 72, avg_time_hours: 1.1, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 65, avg_time_hours: 0.9, cost_per_km: 1.4, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 65, avg_time_hours: 0.9, cost_per_km: 1.4, road_type: 'highway'}]->(wh_zd),
  (wh_si)-[:ROUTE {distance_km: 75, avg_time_hours: 1.2, cost_per_km: 1.2, road_type: 'coastal'}]->(wh_zd),
  (wh_zd)-[:ROUTE {distance_km: 75, avg_time_hours: 1.2, cost_per_km: 1.2, road_type: 'coastal'}]->(wh_si);

// PULA ↔ DUBROVNIK
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE 
  (wh_pu)-[:ROUTE {distance_km: 510, avg_time_hours: 6.5, cost_per_km: 1.5, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 510, avg_time_hours: 6.5, cost_per_km: 1.5, road_type: 'highway'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 520, avg_time_hours: 6.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 520, avg_time_hours: 6.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 530, avg_time_hours: 6.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 530, avg_time_hours: 6.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu);

// PULA ↔ KARLOVAC
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE 
  (wh_ka)-[:ROUTE {distance_km: 125, avg_time_hours: 1.9, cost_per_km: 1.3, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 125, avg_time_hours: 1.9, cost_per_km: 1.3, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 220, avg_time_hours: 2.7, cost_per_km: 1.6, road_type: 'highway'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 220, avg_time_hours: 2.7, cost_per_km: 1.6, road_type: 'highway'}]->(wh_ka),
  (wh_pu)-[:ROUTE {distance_km: 230, avg_time_hours: 2.9, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 230, avg_time_hours: 2.9, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu);

// PULA ↔ VARAŽDIN
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (wh_vz)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 310, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 310, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_vz);

// PULA ↔ SLAVONSKI BROD
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (wh_pu)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.7, road_type: 'highway'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.7, road_type: 'highway'}]->(wh_pu),
  (wh_sb)-[:ROUTE {distance_km: 500, avg_time_hours: 6.3, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 500, avg_time_hours: 6.3, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_sb);

// PULA ↔ ŠIBENIK
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (wh_pu)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 260, avg_time_hours: 3.1, cost_per_km: 1.7, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 260, avg_time_hours: 3.1, cost_per_km: 1.7, road_type: 'highway'}]->(wh_pu),
  (wh_pu)-[:ROUTE {distance_km: 290, avg_time_hours: 3.7, cost_per_km: 1.1, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 290, avg_time_hours: 3.7, cost_per_km: 1.1, road_type: 'regional'}]->(wh_pu);

// DUBROVNIK ↔ KARLOVAC
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE 
  (wh_ka)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.7, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.7, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
  (wh_du)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.8, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.8, road_type: 'highway'}]->(wh_du);

// DUBROVNIK ↔ VARAŽDIN
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (wh_du)-[:ROUTE {distance_km: 680, avg_time_hours: 8.5, cost_per_km: 1.8, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 680, avg_time_hours: 8.5, cost_per_km: 1.8, road_type: 'regional'}]->(wh_du),
  (wh_vz)-[:ROUTE {distance_km: 600, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 600, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 620, avg_time_hours: 7.2, cost_per_km: 1.8, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 620, avg_time_hours: 7.2, cost_per_km: 1.8, road_type: 'highway'}]->(wh_vz);

// DUBROVNIK ↔ SLAVONSKI BROD
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (wh_du)-[:ROUTE {distance_km: 550, avg_time_hours: 6.8, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 550, avg_time_hours: 6.8, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 560, avg_time_hours: 7.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 560, avg_time_hours: 7.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 570, avg_time_hours: 7.1, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 570, avg_time_hours: 7.1, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du);

// DUBROVNIK ↔ ŠIBENIK
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (wh_si)-[:ROUTE {distance_km: 185, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 185, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_si),
  (wh_du)-[:ROUTE {distance_km: 175, avg_time_hours: 2.6, cost_per_km: 1.5, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 175, avg_time_hours: 2.6, cost_per_km: 1.5, road_type: 'highway'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 190, avg_time_hours: 2.9, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 190, avg_time_hours: 2.9, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_du);

// KARLOVAC ↔ VARAŽDIN
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE 
  (wh_ka)-[:ROUTE {distance_km: 95, avg_time_hours: 1.3, cost_per_km: 1.3, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 95, avg_time_hours: 1.3, cost_per_km: 1.3, road_type: 'regional'}]->(wh_ka),
  (wh_vz)-[:ROUTE {distance_km: 85, avg_time_hours: 1.1, cost_per_km: 1.4, road_type: 'highway'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 85, avg_time_hours: 1.1, cost_per_km: 1.4, road_type: 'highway'}]->(wh_vz),
  (wh_ka)-[:ROUTE {distance_km: 100, avg_time_hours: 1.4, cost_per_km: 1.2, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 100, avg_time_hours: 1.4, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka);

// KARLOVAC ↔ SLAVONSKI BROD
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (wh_sb)-[:ROUTE {distance_km: 185, avg_time_hours: 2.4, cost_per_km: 1.3, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 185, avg_time_hours: 2.4, cost_per_km: 1.3, road_type: 'regional'}]->(wh_sb),
  (wh_ka)-[:ROUTE {distance_km: 280, avg_time_hours: 3.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 280, avg_time_hours: 3.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 290, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 290, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka);

// KARLOVAC ↔ ŠIBENIK
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (wh_ka)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 240, avg_time_hours: 2.8, cost_per_km: 1.7, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 240, avg_time_hours: 2.8, cost_per_km: 1.7, road_type: 'highway'}]->(wh_ka),
  (wh_si)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
  (wh_ka)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si);

// VARAŽDIN ↔ SLAVONSKI BROD
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE 
  (wh_vz)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'regional'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 220, avg_time_hours: 2.7, cost_per_km: 1.5, road_type: 'highway'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 220, avg_time_hours: 2.7, cost_per_km: 1.5, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.3, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.3, road_type: 'regional'}]->(wh_vz);

// VARAŽDIN ↔ ŠIBENIK
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (wh_si)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_si),
  (wh_vz)-[:ROUTE {distance_km: 370, avg_time_hours: 4.3, cost_per_km: 1.7, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 370, avg_time_hours: 4.3, cost_per_km: 1.7, road_type: 'highway'}]->(wh_vz),
  (wh_vz)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_vz);

// SLAVONSKI BROD ↔ ŠIBENIK
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE 
  (wh_sb)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 320, avg_time_hours: 4.0, cost_per_km: 1.6, road_type: 'highway'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 320, avg_time_hours: 4.0, cost_per_km: 1.6, road_type: 'highway'}]->(wh_sb),
  (wh_si)-[:ROUTE {distance_km: 330, avg_time_hours: 4.1, cost_per_km: 1.1, road_type: 'regional'}]->(wh_sb),
  (wh_sb)-[:ROUTE {distance_km: 330, avg_time_hours: 4.1, cost_per_km: 1.1, road_type: 'regional'}]->(wh_si);

// Create indexes
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