# OpenSearch Dashboards saved objects

This folder contains a minimal saved objects export to get started with visualizations for the `shipments` index.

Files:
- `saved_objects.json` — export containing an index pattern (`shipments`), a pie visualization (`shipments-status-pie`), a metric (`avg-delivery-time-metric`) and a dashboard (`shipments-dashboard`).

How to import:

1. Start OpenSearch and OpenSearch Dashboards (see `docker-compose.phase3.yml`).
2. Open OpenSearch Dashboards at `http://localhost:5601`.
3. In Dashboards > Stack Management > Saved Objects, click `Import` and upload `saved_objects.json`.
4. If the `shipments` index pattern is not auto-created, create a new index pattern named `shipments` and set the time field to `created_at` (if available).
5. Open the dashboard `Shipments Overview` and adjust panels as needed.

Notes:
- The saved objects file is a minimal example; depending on Dashboards/OpenSearch versions you may need to rewire the visualization's `index` reference via the UI.
- The metric visualization expects the numeric field `delivery_time_seconds` to exist on at least some documents.
