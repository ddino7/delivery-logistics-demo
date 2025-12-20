from flask import Blueprint, jsonify, request, current_app
from kafka import KafkaProducer
import json
import os
import time

location_bp = Blueprint("location_bp", __name__)

def _get_producer() -> KafkaProducer:
    """
    Lazy-init producer and keep it on current_app to reuse connections.
    """
    producer = getattr(current_app, "kafka_producer", None)
    if producer is not None:
        return producer

    bootstrap = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "redpanda:9092")

    producer = KafkaProducer(
        bootstrap_servers=bootstrap.split(","),
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda k: str(k).encode("utf-8"),
        retries=5,
        linger_ms=20,
    )
    current_app.kafka_producer = producer
    return producer


@location_bp.route("/events", methods=["POST"])
def ingest_location_event():
    """
    Driver sends location event -> publish to Kafka topic.
    """
    data = request.get_json(silent=True) or {}

    vehicle_id = data.get("vehicle_id")
    driver_id = data.get("driver_id", "unknown")
    lat = data.get("lat")
    lng = data.get("lng")
    ts = data.get("ts")  # optional, can be unix or ISO

    # basic validation
    if not vehicle_id or lat is None or lng is None:
        return jsonify({"ok": False, "error": "vehicle_id, lat, lng are required"}), 400

    event = {
        "vehicle_id": str(vehicle_id),
        "driver_id": str(driver_id),
        "lat": float(lat),
        "lng": float(lng),
        "ts": ts or time.time(),
        "server_id": current_app.config.get("SERVER_ID"),
    }

    topic = os.getenv("KAFKA_LOCATION_TOPIC", "vehicle-location-events")

    try:
        producer = _get_producer()
        producer.send(topic, key=event["vehicle_id"], value=event)
        producer.flush(timeout=2)
        return jsonify({"ok": True, "published_to": topic, "event": event})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500


@location_bp.route("/latest", methods=["GET"])
def get_latest_locations():
    """
    Frontend polling endpoint -> reads latest locations from Mongo.
    """
    try:
        col = current_app.db_service.get_collection("vehicle_latest_locations")
        docs = list(col.find({}, {"_id": 0}).limit(200))
        return jsonify({"ok": True, "count": len(docs), "data": docs})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500