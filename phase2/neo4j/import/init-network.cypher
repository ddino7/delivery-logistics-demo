// Clear existing data
MATCH (n) DETACH DELETE n;

// ============ CREATE NODES ============

// Distribution Centers (Main hubs)
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

// Warehouses (Regional hubs)
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

CREATE (wh_vz:Warehouse {id: 'WH_VZ', name: 'Varaždin Warehouse', city: 'Varaždin',
  address: 'Industrijska zona Zapad', type: 'regional', capacity: 1200, lat: 46.3059, lon: 16.3366});

CREATE (wh_si:Warehouse {id: 'WH_SI', name: 'Šibenik Warehouse', city: 'Šibenik',
  address: 'Industrijska zona', type: 'coastal', capacity: 900, lat: 43.7350, lon: 15.8952});

// ============ PRIMARY ROUTES (DC to DC) - Multiple alternatives ============

// Zagreb hub connections (fastest routes via highway)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (dc_st:DistributionCenter {id: 'DC_ST'})
CREATE (dc_zg)-[:ROUTE {distance_km: 380, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_st),
       (dc_st)-[:ROUTE {distance_km: 380, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg);

MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (dc_ri:DistributionCenter {id: 'DC_RI'})
CREATE (dc_zg)-[:ROUTE {distance_km: 165, avg_time_hours: 2.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_ri),
       (dc_ri)-[:ROUTE {distance_km: 165, avg_time_hours: 2.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg);

MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE (dc_zg)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.5, road_type: 'highway'}]->(dc_os),
       (dc_os)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.5, road_type: 'highway'}]->(dc_zg);

MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (dc_st:DistributionCenter {id: 'DC_ST'})
CREATE (dc_ri)-[:ROUTE {distance_km: 420, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_st),
       (dc_st)-[:ROUTE {distance_km: 420, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'highway'}]->(dc_ri);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE (dc_st)-[:ROUTE {distance_km: 460, avg_time_hours: 5.5, cost_per_km: 1.6, road_type: 'regional'}]->(dc_os),
       (dc_os)-[:ROUTE {distance_km: 460, avg_time_hours: 5.5, cost_per_km: 1.6, road_type: 'regional'}]->(dc_st);

MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (dc_os:DistributionCenter {id: 'DC_OS'})
CREATE (dc_ri)-[:ROUTE {distance_km: 340, avg_time_hours: 4.2, cost_per_km: 1.4, road_type: 'regional'}]->(dc_os),
       (dc_os)-[:ROUTE {distance_km: 340, avg_time_hours: 4.2, cost_per_km: 1.4, road_type: 'regional'}]->(dc_ri);

// ============ DC TO WAREHOUSE - Direct connections ============

// Zagreb DC to warehouses
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_zg)-[:ROUTE {distance_km: 55, avg_time_hours: 0.75, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 55, avg_time_hours: 0.75, cost_per_km: 1.2, road_type: 'regional'}]->(dc_zg);

MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (dc_zg)-[:ROUTE {distance_km: 80, avg_time_hours: 1.0, cost_per_km: 1.2, road_type: 'highway'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 80, avg_time_hours: 1.0, cost_per_km: 1.2, road_type: 'highway'}]->(dc_zg);

MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_zg)-[:ROUTE {distance_km: 200, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'highway'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 200, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'highway'}]->(dc_zg);

// Rijeka DC to warehouses
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (dc_ri)-[:ROUTE {distance_km: 105, avg_time_hours: 1.5, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 105, avg_time_hours: 1.5, cost_per_km: 1.3, road_type: 'coastal'}]->(dc_ri);

MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (dc_ri)-[:ROUTE {distance_km: 190, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 190, avg_time_hours: 2.5, cost_per_km: 1.3, road_type: 'coastal'}]->(dc_ri);

MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_ri)-[:ROUTE {distance_km: 120, avg_time_hours: 1.6, cost_per_km: 1.2, road_type: 'highway'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 120, avg_time_hours: 1.6, cost_per_km: 1.2, road_type: 'highway'}]->(dc_ri);

// Split DC to warehouses
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (dc_st)-[:ROUTE {distance_km: 155, avg_time_hours: 2.0, cost_per_km: 1.2, road_type: 'highway'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 155, avg_time_hours: 2.0, cost_per_km: 1.2, road_type: 'highway'}]->(dc_st);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_st)-[:ROUTE {distance_km: 85, avg_time_hours: 1.25, cost_per_km: 1.2, road_type: 'coastal'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 85, avg_time_hours: 1.25, cost_per_km: 1.2, road_type: 'coastal'}]->(dc_st);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (dc_st)-[:ROUTE {distance_km: 230, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 230, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'coastal'}]->(dc_st);

MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (dc_st)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.3, road_type: 'coastal'}]->(dc_st);

// Osijek DC to warehouses
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_os)-[:ROUTE {distance_km: 60, avg_time_hours: 0.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 60, avg_time_hours: 0.8, cost_per_km: 1.2, road_type: 'regional'}]->(dc_os);

MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (dc_os)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'highway'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'highway'}]->(dc_os);

// ============ WAREHOUSE TO WAREHOUSE - Alternative routes ============

// Northern route alternatives
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_ka)-[:ROUTE {distance_km: 95, avg_time_hours: 1.3, cost_per_km: 1.3, road_type: 'regional'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 95, avg_time_hours: 1.3, cost_per_km: 1.3, road_type: 'regional'}]->(wh_ka);

MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_ka)-[:ROUTE {distance_km: 125, avg_time_hours: 1.9, cost_per_km: 1.3, road_type: 'regional'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 125, avg_time_hours: 1.9, cost_per_km: 1.3, road_type: 'regional'}]->(wh_ka);

MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_ka)-[:ROUTE {distance_km: 190, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'regional'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 190, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'regional'}]->(wh_ka);

// Coastal route alternatives
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_zd)-[:ROUTE {distance_km: 72, avg_time_hours: 1.1, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 72, avg_time_hours: 1.1, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_zd);

MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_si)-[:ROUTE {distance_km: 185, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 185, avg_time_hours: 2.8, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_si);

MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_zd)-[:ROUTE {distance_km: 285, avg_time_hours: 3.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 285, avg_time_hours: 3.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_zd);

MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_pu)-[:ROUTE {distance_km: 165, avg_time_hours: 2.3, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 165, avg_time_hours: 2.3, cost_per_km: 1.3, road_type: 'coastal'}]->(wh_pu);

// Eastern connections
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_sb)-[:ROUTE {distance_km: 185, avg_time_hours: 2.4, cost_per_km: 1.3, road_type: 'regional'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 185, avg_time_hours: 2.4, cost_per_km: 1.3, road_type: 'regional'}]->(wh_sb);

MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_vz)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'regional'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'regional'}]->(wh_vz);

// ============ ALTERNATIVE ROUTES (slower but cheaper or vice versa) ============

// Zagreb to Split via Karlovac (cheaper, slower)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (dc_st:DistributionCenter {id: 'DC_ST'})
CREATE (wh_ka)-[:ROUTE {distance_km: 340, avg_time_hours: 4.5, cost_per_km: 1.1, road_type: 'regional'}]->(dc_st),
       (dc_st)-[:ROUTE {distance_km: 340, avg_time_hours: 4.5, cost_per_km: 1.1, road_type: 'regional'}]->(wh_ka);

// Zagreb to Split via Zadar (scenic coastal - expensive, slower)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (dc_zg)-[:ROUTE {distance_km: 285, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'regional'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 285, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'regional'}]->(dc_zg);

// Pula to Dubrovnik via Split (fast but expensive)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_pu)-[:ROUTE {distance_km: 510, avg_time_hours: 6.5, cost_per_km: 1.5, road_type: 'highway'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 510, avg_time_hours: 6.5, cost_per_km: 1.5, road_type: 'highway'}]->(wh_pu);

// Varaždin to Split (long route, budget option)
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (dc_st:DistributionCenter {id: 'DC_ST'})
CREATE (wh_vz)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(dc_st),
       (dc_st)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_vz);

// Osijek to Rijeka (cross-country expensive route)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (dc_ri:DistributionCenter {id: 'DC_RI'})
CREATE (dc_os)-[:ROUTE {distance_km: 380, avg_time_hours: 4.8, cost_per_km: 1.7, road_type: 'regional'}]->(dc_ri);

// Dubrovnik to Varaždin (longest route - very expensive)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_du)-[:ROUTE {distance_km: 680, avg_time_hours: 8.5, cost_per_km: 1.8, road_type: 'regional'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 680, avg_time_hours: 8.5, cost_per_km: 1.8, road_type: 'regional'}]->(wh_du);

// ============ DODATNE ALTERNATIVNE RUTE (nastavak) ============

//Distribucijski centar Zagreb (DC_ZG)
// 11. Zagreb (DC_ZG) -> Šibenik (WH_SI) - Autocesta (brza, skupa)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_zg)-[:ROUTE {distance_km: 320, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 320, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(dc_zg);

// 12. Zagreb (DC_ZG) -> Šibenik (WH_SI) - Regionalni put (jeftiniji, sporiji)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_zg)-[:ROUTE {distance_km: 350, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 350, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(dc_zg);

// 13. Zagreb (DC_ZG) -> Dubrovnik (WH_DU) - Kombinacija autoceste i obalnog puta
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (dc_zg)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.6, road_type: 'mixed'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.6, road_type: 'mixed'}]->(dc_zg);

// 14. Zagreb (DC_ZG) -> Slavonski Brod (WH_SB) - Izravna regionalna veza
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_zg)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'regional'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 220, avg_time_hours: 2.8, cost_per_km: 1.3, road_type: 'regional'}]->(dc_zg);

//Distribucijski centar Split (DC_ST)
// 15. Split (DC_ST) -> Karlovac (WH_KA) - Obalni put (scenski)
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_st)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(dc_st);

// 16. Split (DC_ST) -> Varaždin (WH_VZ) - Autocesta (brza)
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (dc_st)-[:ROUTE {distance_km: 400, avg_time_hours: 4.5, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 400, avg_time_hours: 4.5, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(dc_st);

// 17. Split (DC_ST) -> Karlovac (WH_KA) - Regionalni put (jeftin)
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_st)-[:ROUTE {distance_km: 320, avg_time_hours: 4.2, cost_per_km: 1.1, road_type: 'regional'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 320, avg_time_hours: 4.2, cost_per_km: 1.1, road_type: 'regional'}]->(dc_st);

//Distribucijski centar Rijeka (DC_RI)
// 18. Rijeka (DC_RI) -> Slavonski Brod (WH_SB) - Kombinacija autoceste i regionalnog puta
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_ri)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(dc_ri);

// 19. Rijeka (DC_RI) -> Šibenik (WH_SI) - Obalni put (scenski)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_ri)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 280, avg_time_hours: 3.8, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_ri);

// 20. Rijeka (DC_RI) -> Dubrovnik (WH_DU) - Autocesta (brza, skupa)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (dc_ri)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(dc_ri);

//Distribucijski centar Osijek (DC_OS)
// 21. Osijek (DC_OS) -> Zadar (WH_ZD) - Regionalni put (jeftin)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (dc_os)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 420, avg_time_hours: 5.2, cost_per_km: 1.2, road_type: 'regional'}]->(dc_os);

// 22. Osijek (DC_OS) -> Pula (WH_PU) - Kombinacija autoceste i obalnog puta
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (dc_os)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os);

//Skladista
// 23. Karlovac (WH_KA) -> Šibenik (WH_SI) - Regionalni put
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_ka)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka);

// 24. Karlovac (WH_KA) -> Dubrovnik (WH_DU) - Autocesta (brza)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_ka)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_ka);

// 25. Zadar (WH_ZD) -> Varaždin (WH_VZ) - Kombinacija autoceste i regionalnog puta
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_zd)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd);

// 26. Pula (WH_PU) -> Slavonski Brod (WH_SB) - Regionalni put (jeftin)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_pu)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu);

// 27. Šibenik (WH_SI) -> Varaždin (WH_VZ) - Obalni put (scenski)
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_si)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_si);

// 28. Dubrovnik (WH_DU) -> Karlovac (WH_KA) - Autocesta (brza)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_du)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_du);

// 29. Slavonski Brod (WH_SB) -> Zadar (WH_ZD) - Kombinacija autoceste i regionalnog puta
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_sb)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb);

// 30. Varaždin (WH_VZ) -> Pula (WH_PU) - Regionalni put (jeftin)
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_vz)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 280, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_vz);

//Dodatne kombinacije
// 31. Zagreb (DC_ZG) -> Dubrovnik (WH_DU) - Obalni put (scenski, dugačak)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (dc_zg)-[:ROUTE {distance_km: 620, avg_time_hours: 8.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 620, avg_time_hours: 8.0, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_zg);

// 32. Split (DC_ST) -> Varaždin (WH_VZ) - Autocesta (brza)
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (dc_st)-[:ROUTE {distance_km: 380, avg_time_hours: 4.2, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 380, avg_time_hours: 4.2, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(dc_st);

// 33. Rijeka (DC_RI) -> Slavonski Brod (WH_SB) - Regionalni put (jeftin)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_ri)-[:ROUTE {distance_km: 370, avg_time_hours: 4.7, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 370, avg_time_hours: 4.7, cost_per_km: 1.2, road_type: 'regional'}]->(dc_ri);

// 34. Osijek (DC_OS) -> Šibenik (WH_SI) - Kombinacija autoceste i obalnog puta
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_os)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os);

// 35. Karlovac (WH_KA) -> Dubrovnik (WH_DU) - Regionalni put (jeftin, spor)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_ka)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka);

// 36. Zadar (WH_ZD) -> Varaždin (WH_VZ) - Autocesta (brza)
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_zd)-[:ROUTE {distance_km: 330, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 330, avg_time_hours: 3.8, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_zd);

// 37. Pula (WH_PU) -> Šibenik (WH_SI) - Obalni put (scenski)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_pu)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 300, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_pu);

// 38. Dubrovnik (WH_DU) -> Slavonski Brod (WH_SB) - Kombinacija autoceste i regionalnog puta
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_du)-[:ROUTE {distance_km: 550, avg_time_hours: 6.8, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 550, avg_time_hours: 6.8, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_du);

// 39. Varaždin (WH_VZ) -> Dubrovnik (WH_DU) - Autocesta (brza, skupa)
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_vz)-[:ROUTE {distance_km: 600, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 600, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_vz);

// 40. Šibenik (WH_SI) -> Karlovac (WH_KA) - Regionalni put (jeftin)
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_si)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 270, avg_time_hours: 3.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si);

// 41. Slavonski Brod (WH_SB) -> Pula (WH_PU) - Obalni put (scenski, dugačak)
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_sb)-[:ROUTE {distance_km: 500, avg_time_hours: 6.3, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 500, avg_time_hours: 6.3, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_sb);

// 42. Zadar (WH_ZD) -> Dubrovnik (WH_DU) - Autocesta (brza)
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_zd)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_zd);

// 43. Pula (WH_PU) -> Varaždin (WH_VZ) - Regionalni put (jeftin)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_pu)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu);

// 44. Dubrovnik (WH_DU) -> Zadar (WH_ZD) - Obalni put (scenski)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_du)-[:ROUTE {distance_km: 320, avg_time_hours: 4.2, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 320, avg_time_hours: 4.2, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du);

// 45. Varaždin (WH_VZ) -> Šibenik (WH_SI) - Kombinacija autoceste i regionalnog puta
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_vz)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 380, avg_time_hours: 4.7, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_vz);

// 46. Karlovac (WH_KA) -> Pula (WH_PU) - Autocesta (brza)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_ka)-[:ROUTE {distance_km: 220, avg_time_hours: 2.7, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 220, avg_time_hours: 2.7, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_ka);

// 47. Slavonski Brod (WH_SB) -> Zadar (WH_ZD) - Regionalni put (jeftin)
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_sb)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb);

// 48. Šibenik (WH_SI) -> Pula (WH_PU) - Obalni put (scenski)
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_si)-[:ROUTE {distance_km: 280, avg_time_hours: 3.7, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 280, avg_time_hours: 3.7, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_si);

// 49. Zadar (WH_ZD) -> Karlovac (WH_KA) - Kombinacija autoceste i regionalnog puta
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_zd)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 250, avg_time_hours: 3.2, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd);

// 50. Pula (WH_PU) -> Dubrovnik (WH_DU) - Regionalni put (jeftin, spor)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_pu)-[:ROUTE {distance_km: 520, avg_time_hours: 6.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 520, avg_time_hours: 6.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu);
// ============ DODATNE RUTE (51-100) ============

//Distribucijski centar Zagreb (DC_ZG)
// 51. Zagreb (DC_ZG) -> Šibenik (WH_SI) - Brza autocesta (skuplja)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_zg)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(dc_zg);

// 52. Zagreb (DC_ZG) -> Pula (WH_PU) - Regionalni put (jeftin)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (dc_zg)-[:ROUTE {distance_km: 260, avg_time_hours: 3.3, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 260, avg_time_hours: 3.3, cost_per_km: 1.2, road_type: 'regional'}]->(dc_zg);

// 53. Zagreb (DC_ZG) -> Dubrovnik (WH_DU) - Obalni put (scenski, dugačak)
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (dc_zg)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_zg);

//Distribucijski centar Split (DC_ST)
// 54. Split (DC_ST) -> Karlovac (WH_KA) - Autocesta (brza)
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_st)-[:ROUTE {distance_km: 280, avg_time_hours: 3.2, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 280, avg_time_hours: 3.2, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(dc_st);

// 55. Split (DC_ST) -> Varaždin (WH_VZ) - Regionalni put (jeftin)
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (dc_st)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.1, road_type: 'regional'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.1, road_type: 'regional'}]->(dc_st);

// 56. Split (DC_ST) -> Slavonski Brod (WH_SB) - Kombinacija autoceste i regionalnog puta
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_st)-[:ROUTE {distance_km: 380, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 380, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(dc_st);

//Distribucijski centar Rijeka (DC_RI)
// 57. Rijeka (DC_RI) -> Šibenik (WH_SI) - Autocesta (brza)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_ri)-[:ROUTE {distance_km: 260, avg_time_hours: 3.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 260, avg_time_hours: 3.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(dc_ri);

// 58. Rijeka (DC_RI) -> Varaždin (WH_VZ) - Regionalni put (jeftin)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (dc_ri)-[:ROUTE {distance_km: 180, avg_time_hours: 2.2, cost_per_km: 1.1, road_type: 'regional'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 180, avg_time_hours: 2.2, cost_per_km: 1.1, road_type: 'regional'}]->(dc_ri);

// 59. Rijeka (DC_RI) -> Slavonski Brod (WH_SB) - Obalni put (scenski)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (dc_ri)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_ri);

//Distribucijski centar Osijek (DC_OS)
// 60. Osijek (DC_OS) -> Karlovac (WH_KA) - Autocesta (brza)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_os)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 300, avg_time_hours: 3.5, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(dc_os);

// 61. Osijek (DC_OS) -> Zadar (WH_ZD) - Regionalni put (jeftin)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (dc_os)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 450, avg_time_hours: 5.5, cost_per_km: 1.2, road_type: 'regional'}]->(dc_os);

// 62. Osijek (DC_OS) -> Pula (WH_PU) - Kombinacija autoceste i obalnog puta
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (dc_os)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 520, avg_time_hours: 6.2, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_os);

//Skladista
// 63. Karlovac (WH_KA) -> Šibenik (WH_SI) - Autocesta (brza)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_ka)-[:ROUTE {distance_km: 240, avg_time_hours: 2.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 240, avg_time_hours: 2.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_ka);

// 64. Karlovac (WH_KA) -> Dubrovnik (WH_DU) - Regionalni put (jeftin)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_ka)-[:ROUTE {distance_km: 530, avg_time_hours: 6.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 530, avg_time_hours: 6.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka);

// 65. Zadar (WH_ZD) -> Varaždin (WH_VZ) - Obalni put (scenski)
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_zd)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 360, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_zd);

// 66. Pula (WH_PU) -> Slavonski Brod (WH_SB) - Autocesta (brza)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_pu)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 480, avg_time_hours: 5.5, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_pu);

// 67. Šibenik (WH_SI) -> Varaždin (WH_VZ) - Kombinacija autoceste i regionalnog puta
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_si)-[:ROUTE {distance_km: 390, avg_time_hours: 4.8, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 390, avg_time_hours: 4.8, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_si);

// 68. Dubrovnik (WH_DU) -> Karlovac (WH_KA) - Obalni put (scenski)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_du)-[:ROUTE {distance_km: 540, avg_time_hours: 6.8, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 540, avg_time_hours: 6.8, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du);

// 69. Slavonski Brod (WH_SB) -> Zadar (WH_ZD) - Regionalni put (jeftin)
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_sb)-[:ROUTE {distance_km: 370, avg_time_hours: 4.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 370, avg_time_hours: 4.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb);

// 70. Varaždin (WH_VZ) -> Dubrovnik (WH_DU) - Autocesta (brza)
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_vz)-[:ROUTE {distance_km: 620, avg_time_hours: 7.2, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 620, avg_time_hours: 7.2, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_vz);

//Dodatne kombinacije
// 71. Zagreb (DC_ZG) -> Šibenik (WH_SI) - Kombinacija autoceste i obalnog puta
MATCH (dc_zg:DistributionCenter {id: 'DC_ZG'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_zg)-[:ROUTE {distance_km: 330, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 330, avg_time_hours: 4.0, cost_per_km: 1.5, road_type: 'mixed'}]->(dc_zg);

// 72. Split (DC_ST) -> Karlovac (WH_KA) - Regionalni put (jeftin)
MATCH (dc_st:DistributionCenter {id: 'DC_ST'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (dc_st)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.1, road_type: 'regional'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 300, avg_time_hours: 3.8, cost_per_km: 1.1, road_type: 'regional'}]->(dc_st);

// 73. Rijeka (DC_RI) -> Šibenik (WH_SI) - Regionalni put (jeftin)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (dc_ri)-[:ROUTE {distance_km: 290, avg_time_hours: 3.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 290, avg_time_hours: 3.6, cost_per_km: 1.2, road_type: 'regional'}]->(dc_ri);

// 74. Osijek (DC_OS) -> Zadar (WH_ZD) - Autocesta (brza)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (dc_os)-[:ROUTE {distance_km: 430, avg_time_hours: 5.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 430, avg_time_hours: 5.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(dc_os);

// 75. Karlovac (WH_KA) -> Slavonski Brod (WH_SB) - Kombinacija autoceste i regionalnog puta
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_ka)-[:ROUTE {distance_km: 280, avg_time_hours: 3.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 280, avg_time_hours: 3.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_ka);

// 76. Zadar (WH_ZD) -> Dubrovnik (WH_DU) - Regionalni put (jeftin)
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_zd)-[:ROUTE {distance_km: 330, avg_time_hours: 4.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 330, avg_time_hours: 4.2, cost_per_km: 1.2, road_type: 'regional'}]->(wh_zd);

// 77. Pula (WH_PU) -> Šibenik (WH_SI) - Autocesta (brza)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_pu)-[:ROUTE {distance_km: 260, avg_time_hours: 3.1, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 260, avg_time_hours: 3.1, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_pu);

// 78. Dubrovnik (WH_DU) -> Slavonski Brod (WH_SB) - Obalni put (scenski)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_du)-[:ROUTE {distance_km: 560, avg_time_hours: 7.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 560, avg_time_hours: 7.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du);

// 79. Varaždin (WH_VZ) -> Šibenik (WH_SI) - Regionalni put (jeftin)
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_vz)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.1, road_type: 'regional'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 400, avg_time_hours: 5.0, cost_per_km: 1.1, road_type: 'regional'}]->(wh_vz);

// 80. Šibenik (WH_SI) -> Karlovac (WH_KA) - Autocesta (brza)
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_si)-[:ROUTE {distance_km: 250, avg_time_hours: 2.9, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 250, avg_time_hours: 2.9, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_si);

// 81. Slavonski Brod (WH_SB) -> Pula (WH_PU) - Kombinacija autoceste i obalnog puta
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_sb)-[:ROUTE {distance_km: 490, avg_time_hours: 5.8, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 490, avg_time_hours: 5.8, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_sb);

// 82. Zadar (WH_ZD) -> Varaždin (WH_VZ) - Autocesta (brza)
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_zd)-[:ROUTE {distance_km: 340, avg_time_hours: 4.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 340, avg_time_hours: 4.0, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_zd);

// 83. Pula (WH_PU) -> Dubrovnik (WH_DU) - Regionalni put (jeftin)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_pu)-[:ROUTE {distance_km: 530, avg_time_hours: 6.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 530, avg_time_hours: 6.6, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu);

// 84. Dubrovnik (WH_DU) -> Zadar (WH_ZD) - Autocesta (brza)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_du)-[:ROUTE {distance_km: 310, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 310, avg_time_hours: 3.8, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_du);

// 85. Varaždin (WH_VZ) -> Pula (WH_PU) - Obalni put (scenski)
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_vz)-[:ROUTE {distance_km: 310, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 310, avg_time_hours: 4.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_vz);

// 86. Šibenik (WH_SI) -> Slavonski Brod (WH_SB) - Regionalni put (jeftin)
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_si)-[:ROUTE {distance_km: 330, avg_time_hours: 4.1, cost_per_km: 1.1, road_type: 'regional'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 330, avg_time_hours: 4.1, cost_per_km: 1.1, road_type: 'regional'}]->(wh_si);

// 87. Karlovac (WH_KA) -> Zadar (WH_ZD) - Autocesta (brza)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_ka)-[:ROUTE {distance_km: 220, avg_time_hours: 2.6, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 220, avg_time_hours: 2.6, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_ka);

// 88. Zadar (WH_ZD) -> Slavonski Brod (WH_SB) - Kombinacija autoceste i regionalnog puta
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_zd)-[:ROUTE {distance_km: 370, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 370, avg_time_hours: 4.5, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd);

// 89. Pula (WH_PU) -> Karlovac (WH_KA) - Regionalni put (jeftin)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_pu)-[:ROUTE {distance_km: 230, avg_time_hours: 2.9, cost_per_km: 1.2, road_type: 'regional'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 230, avg_time_hours: 2.9, cost_per_km: 1.2, road_type: 'regional'}]->(wh_pu);

// 90. Dubrovnik (WH_DU) -> Varaždin (WH_VZ) - Autocesta (brza)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_vz:Warehouse {id: 'WH_VZ'})
CREATE (wh_du)-[:ROUTE {distance_km: 630, avg_time_hours: 7.3, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_vz),
       (wh_vz)-[:ROUTE {distance_km: 630, avg_time_hours: 7.3, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_du);

// 91. Slavonski Brod (WH_SB) -> Zadar (WH_ZD) - Obalni put (scenski)
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_sb)-[:ROUTE {distance_km: 380, avg_time_hours: 4.8, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 380, avg_time_hours: 4.8, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_sb);

// 92. Varaždin (WH_VZ) -> Šibenik (WH_SI) - Autocesta (brza)
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_vz)-[:ROUTE {distance_km: 370, avg_time_hours: 4.3, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 370, avg_time_hours: 4.3, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_vz);

// 93. Šibenik (WH_SI) -> Karlovac (WH_KA) - Regionalni put (jeftin)
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_ka:Warehouse {id: 'WH_KA'})
CREATE (wh_si)-[:ROUTE {distance_km: 260, avg_time_hours: 3.3, cost_per_km: 1.1, road_type: 'regional'}]->(wh_ka),
       (wh_ka)-[:ROUTE {distance_km: 260, avg_time_hours: 3.3, cost_per_km: 1.1, road_type: 'regional'}]->(wh_si);

// 94. Karlovac (WH_KA) -> Dubrovnik (WH_DU) - Kombinacija autoceste i obalnog puta
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE (wh_ka)-[:ROUTE {distance_km: 540, avg_time_hours: 6.5, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_du),
       (wh_du)-[:ROUTE {distance_km: 540, avg_time_hours: 6.5, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_ka);

// 95. Zadar (WH_ZD) -> Pula (WH_PU) - Autocesta (brza)
MATCH (wh_zd:Warehouse {id: 'WH_ZD'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_zd)-[:ROUTE {distance_km: 200, avg_time_hours: 2.4, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 200, avg_time_hours: 2.4, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_zd);

// 96. Pula (WH_PU) -> Šibenik (WH_SI) - Regionalni put (jeftin)
MATCH (wh_pu:Warehouse {id: 'WH_PU'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE (wh_pu)-[:ROUTE {distance_km: 290, avg_time_hours: 3.7, cost_per_km: 1.1, road_type: 'regional'}]->(wh_si),
       (wh_si)-[:ROUTE {distance_km: 290, avg_time_hours: 3.7, cost_per_km: 1.1, road_type: 'regional'}]->(wh_pu);

// 97. Dubrovnik (WH_DU) -> Slavonski Brod (WH_SB) - Regionalni put (jeftin)
MATCH (wh_du:Warehouse {id: 'WH_DU'}), (wh_sb:Warehouse {id: 'WH_SB'})
CREATE (wh_du)-[:ROUTE {distance_km: 570, avg_time_hours: 7.1, cost_per_km: 1.2, road_type: 'regional'}]->(wh_sb),
       (wh_sb)-[:ROUTE {distance_km: 570, avg_time_hours: 7.1, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du);

// 98. Varaždin (WH_VZ) -> Zadar (WH_ZD) - Kombinacija autoceste i obalnog puta
MATCH (wh_vz:Warehouse {id: 'WH_VZ'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_vz)-[:ROUTE {distance_km: 360, avg_time_hours: 4.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 360, avg_time_hours: 4.4, cost_per_km: 1.4, road_type: 'mixed'}]->(wh_vz);

// 99. Šibenik (WH_SI) -> Pula (WH_PU) - Autocesta (brza)
MATCH (wh_si:Warehouse {id: 'WH_SI'}), (wh_pu:Warehouse {id: 'WH_PU'})
CREATE (wh_si)-[:ROUTE {distance_km: 270, avg_time_hours: 3.2, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_pu),
       (wh_pu)-[:ROUTE {distance_km: 270, avg_time_hours: 3.2, cost_per_km: 1.7, road_type: 'highway', toll: true}]->(wh_si);

// 100. Karlovac (WH_KA) -> Zadar (WH_ZD) - Obalni put (scenski)
MATCH (wh_ka:Warehouse {id: 'WH_KA'}), (wh_zd:Warehouse {id: 'WH_ZD'})
CREATE (wh_ka)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_zd),
       (wh_zd)-[:ROUTE {distance_km: 240, avg_time_hours: 3.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_ka);

// Dodatne rute za potpunu povezanost
// 1. Rijeka (DC_RI) ↔ Dubrovnik (WH_DU)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE
  (dc_ri)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 500, avg_time_hours: 6.0, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(dc_ri);

// 2. Osijek (DC_OS) ↔ Dubrovnik (WH_DU)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE
  (dc_os)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.7, road_type: 'mixed'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 600, avg_time_hours: 7.5, cost_per_km: 1.7, road_type: 'mixed'}]->(dc_os);

// 3. Slavonski Brod (WH_SB) ↔ Šibenik (WH_SI)
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE
  (wh_sb)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'regional'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 350, avg_time_hours: 4.3, cost_per_km: 1.4, road_type: 'regional'}]->(wh_sb);

// 1. Rijeka (DC_RI) ↔ Dubrovnik (WH_DU)
// Alternativa 1: Obalni put (scenski, duži)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE
  (dc_ri)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.4, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 550, avg_time_hours: 7.0, cost_per_km: 1.4, road_type: 'coastal'}]->(dc_ri);

// Alternativa 2: Regionalni put (jeftin, spor)
MATCH (dc_ri:DistributionCenter {id: 'DC_RI'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE
  (dc_ri)-[:ROUTE {distance_km: 580, avg_time_hours: 7.5, cost_per_km: 1.2, road_type: 'regional'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 580, avg_time_hours: 7.5, cost_per_km: 1.2, road_type: 'regional'}]->(dc_ri);


// 2. Osijek (DC_OS) ↔ Dubrovnik (WH_DU)
// Alternativa 1: Autocesta (brža, skuplja)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE
  (dc_os)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 580, avg_time_hours: 7.0, cost_per_km: 1.8, road_type: 'highway', toll: true}]->(dc_os);

// Alternativa 2: Obalni put (scenski, duži)
MATCH (dc_os:DistributionCenter {id: 'DC_OS'}), (wh_du:Warehouse {id: 'WH_DU'})
CREATE
  (dc_os)-[:ROUTE {distance_km: 650, avg_time_hours: 8.0, cost_per_km: 1.5, road_type: 'coastal'}]->(wh_du),
  (wh_du)-[:ROUTE {distance_km: 650, avg_time_hours: 8.0, cost_per_km: 1.5, road_type: 'coastal'}]->(dc_os);

// 3. Slavonski Brod (WH_SB) ↔ Šibenik (WH_SI)
// Alternativa 1: Autocesta (brža, skuplja)
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE
  (wh_sb)-[:ROUTE {distance_km: 320, avg_time_hours: 4.0, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 320, avg_time_hours: 4.0, cost_per_km: 1.6, road_type: 'highway', toll: true}]->(wh_sb);

// Alternativa 2: Kombinacija autoceste i regionalnog puta
MATCH (wh_sb:Warehouse {id: 'WH_SB'}), (wh_si:Warehouse {id: 'WH_SI'})
CREATE
  (wh_sb)-[:ROUTE {distance_km: 330, avg_time_hours: 4.2, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_si),
  (wh_si)-[:ROUTE {distance_km: 330, avg_time_hours: 4.2, cost_per_km: 1.5, road_type: 'mixed'}]->(wh_sb);

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