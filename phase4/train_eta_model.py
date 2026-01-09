import json
import os
from statistics import mean
from typing import Any, Dict, List

from pymongo import MongoClient


DEFAULT_SPEED = 45  # km/h fallback
DEFAULT_HANDLING = 0.25  # hours


def fetch_deliveries(uri: str, db_name: str) -> List[Dict[str, Any]]:
    client = MongoClient(uri)
    db = client[db_name]
    col = db.get_collection("shipments")
    cursor = col.find(
        {
            "delivery_time_seconds": {"$exists": True},
            "route.total_distance_km": {"$exists": True},
        },
        {
            "_id": 0,
            "delivery_time_seconds": 1,
            "route.total_distance_km": 1,
        },
    )
    return list(cursor)


def compute_stats(docs: List[Dict[str, Any]]) -> Dict[str, Any]:
    if not docs:
        return {"avg_speed_kmph": DEFAULT_SPEED, "handling_time_hours": DEFAULT_HANDLING, "count": 0}

    speeds = []
    for doc in docs:
        distance = float(doc.get("route", {}).get("total_distance_km", 0) or 0)
        delivery_seconds = float(doc.get("delivery_time_seconds", 0) or 0)
        if distance > 0 and delivery_seconds > 0:
            hours = delivery_seconds / 3600.0
            speeds.append(distance / hours)

    if not speeds:
        return {"avg_speed_kmph": DEFAULT_SPEED, "handling_time_hours": DEFAULT_HANDLING, "count": len(docs)}

    avg_speed = max(20.0, min(90.0, mean(speeds)))
    return {"avg_speed_kmph": avg_speed, "handling_time_hours": DEFAULT_HANDLING, "count": len(docs)}


def save_stats(stats: Dict[str, Any], path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(stats, fh, indent=2)


def main():
    mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/?replicaSet=rs0")
    mongo_db = os.getenv("MONGO_DB_NAME", "delivery_system")
    out_path = os.getenv("ETA_STATS_OUT", os.path.join(os.path.dirname(__file__), "model.json"))

    docs = fetch_deliveries(mongo_uri, mongo_db)
    stats = compute_stats(docs)
    save_stats(stats, out_path)
    print(f"ETA stats saved to {out_path}: {stats}")


if __name__ == "__main__":
    main()
