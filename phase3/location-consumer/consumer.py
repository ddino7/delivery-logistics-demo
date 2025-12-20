import os
import json
import time
from kafka import KafkaConsumer
from pymongo import MongoClient, UpdateOne

BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "redpanda:9092")
TOPIC = os.getenv("KAFKA_LOCATION_TOPIC", "vehicle-location-events")

MONGO_URI = os.getenv("MONGO_URI")
MONGO_DB = os.getenv("MONGO_DB_NAME", "delivery_db")

if not MONGO_URI:
    raise RuntimeError("MONGO_URI is required")

client = MongoClient(MONGO_URI)
db = client[MONGO_DB]
col = db["vehicle_latest_locations"]

def main():
    while True:
        try:
            consumer = KafkaConsumer(
                TOPIC,
                bootstrap_servers=BOOTSTRAP.split(","),
                auto_offset_reset="latest",
                enable_auto_commit=True,
                group_id="location-consumer",
                value_deserializer=lambda b: json.loads(b.decode("utf-8")),
                key_deserializer=lambda b: b.decode("utf-8") if b else None,
            )

            print(f"[consumer] connected. topic={TOPIC} bootstrap={BOOTSTRAP}")

            for msg in consumer:
                event = msg.value
                vehicle_id = str(event.get("vehicle_id"))
                if not vehicle_id:
                    continue

                # upsert latest
                event["updated_at"] = time.time()

                col.update_one(
                    {"vehicle_id": vehicle_id},
                    {"$set": event},
                    upsert=True
                )

        except Exception as e:
            print(f"[consumer] error: {e}. retrying in 3s")
            time.sleep(3)

if __name__ == "__main__":
    main()