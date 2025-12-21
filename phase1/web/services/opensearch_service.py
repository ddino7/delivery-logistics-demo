import requests
from datetime import datetime
try:
    from bson import ObjectId
except Exception:
    ObjectId = None


class OpenSearchService:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")

    def is_available(self) -> bool:
        try:
            # cluster health is a lightweight way to check availability
            r = requests.get(f"{self.base_url}/_cluster/health", timeout=2)
            return r.status_code == 200
        except Exception:
            return False

    def index_shipment(self, shipment: dict):
        doc_id = shipment.get("tracking_number") or shipment.get("id")
        if not doc_id:
            return

        def _serialize(obj):
            if isinstance(obj, datetime):
                # use ISO format
                return obj.isoformat()
            if ObjectId is not None and isinstance(obj, ObjectId):
                return str(obj)
            if isinstance(obj, dict):
                return {k: _serialize(v) for k, v in obj.items()}
            if isinstance(obj, list):
                return [_serialize(v) for v in obj]
            return obj

        payload = _serialize(shipment)
        try:
            requests.put(
                f"{self.base_url}/shipments/_doc/{doc_id}",
                json=payload,
                timeout=3,
            )
        except Exception:
            # don't raise — indexing failures should not break main flow
            raise

    def search_shipments(self, q: str, size: int = 50):
        query = {
            "size": size,
            "query": {
                "multi_match": {
                    "query": q,
                    "fields": [
                        "tracking_number^3",
                        "status^2",
                        "receiver.name^2",
                        "delivery_address",
                        "sender.name",
                        "pickup_address",
                        "products.name",
                    ],
                }
            },
        }
        r = requests.get(f"{self.base_url}/shipments/_search", json=query, timeout=3)
        r.raise_for_status()
        return r.json()
