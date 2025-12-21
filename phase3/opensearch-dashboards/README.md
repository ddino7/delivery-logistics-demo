Phase 3 — OpenSearch Dashboards

This folder contains a saved objects export and instructions to import a simple analytics dashboard and a logs Discover saved search.

Files
- `saved_objects.json` — saved objects export (index patterns, visualizations, search, dashboard)

Quick import (UI)
1. Open OpenSearch Dashboards: http://localhost:5601
2. Go to Stack Management → Saved Objects (or "Saved Objects" section)
3. Click "Import" and upload `phase3/opensearch-dashboards/saved_objects.json`.
4. After import, open "Dashboards" → "Phase 3 — Analytics".

Quick import (API)
You can POST the saved objects to the Dashboards API (replace host/port if different):

```bash
curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
	-H "kbn-xsrf: true" \
	-F "file=@phase3/opensearch-dashboards/saved_objects.json"
```

If API fails, use the UI import.

Data views
- `shipments` index pattern — used by the shipments visualizations
- `logs-delivery*` index pattern — used by Discover and saved search

Demo script (60s)

1) Send a location event (0–10s):
```bash
curl -X POST http://localhost:5000/api/location \
	-H 'Content-Type: application/json' \
	-d '{"vehicle_id":"demo-1","lat":46.7,"lng":16.8,"timestamp":"2025-12-21T13:00:00Z"}'
```

2) Show the map in the web UI (10–25s).

3) Open OpenSearch Dashboards → Discover → choose `shipments` or search → show indexed shipment (25–35s).

4) Open Dashboards → "Phase 3 — Analytics" and show the pie and metric (35–45s).

5) Open Discover → `logs-delivery*` and apply filter `service : "location-consumer"` to show structured logs (45–60s).

Structured log format
Use this minimal JSON shape for logs (one JSON object per line):

```json
{"@timestamp":"2025-12-21T13:33:00Z","service":"location-consumer","level":"INFO","event_type":"location_upsert","vehicle_id":"test-1","lat":46.7,"lng":16.8,"message":"location upserted"}
```

This lets Dashboards treat `@timestamp` as the time field and filter/aggregate on `service`, `level`, and `event_type`.

Notes
- I kept the `phase3/fluent-bit/test-logs/test.log` tail flow for proof-of-concept ingestion. To switch to real container logs, make sure host `/var/lib/docker/containers` contains `json-file` logs and adjust Fluent Bit input back to that path (and ensure permissions).
- If you want, I can import `saved_objects.json` automatically and/or update the consumer to use a JSON logger module instead of `print()`.
