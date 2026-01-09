import json
import os
from typing import Any, Dict, Tuple

try:
    import joblib  # type: ignore
except Exception:
    joblib = None


class EtaService:
    """
    Lightweight ETA predictor that prefers a saved model when present and falls
    back to simple heuristics (distance / avg_speed).
    """

    def __init__(self, model_path: str = "/app/phase4/model.joblib", stats_path: str = "/app/phase4/model.json"):
        self.model_path = model_path
        self.stats_path = stats_path
        self.model = self._load_model(model_path)
        self.stats = self._load_stats(stats_path)

    @property
    def has_model(self) -> bool:
        return self.model is not None

    def predict(self, shipment: Dict[str, Any], route: Dict[str, Any]) -> Tuple[float, str]:
        """
        Returns (eta_hours, source) where source is 'model' or 'heuristic'.
        """
        if self.model:
            try:
                features = self._build_features(shipment, route)
                eta = float(self.model.predict([features])[0])
                return eta, "model"
            except Exception:
                pass

        eta = self._heuristic_eta(route, shipment)
        return eta, "heuristic"

    def _load_model(self, path: str):
        if not joblib or not os.path.exists(path):
            return None
        try:
            return joblib.load(path)
        except Exception:
            return None

    def _load_stats(self, path: str) -> Dict[str, Any]:
        if not os.path.exists(path):
            return {}
        try:
            with open(path, "r", encoding="utf-8") as fh:
                return json.load(fh) or {}
        except Exception:
            return {}

    def _build_features(self, shipment: Dict[str, Any], route: Dict[str, Any]):
        distance = float(route.get("total_distance_km", 0) or 0)
        planned_time = float(route.get("total_time_hours", 0) or 0)
        weight = float(shipment.get("weight", 0) or 0)
        return [distance, planned_time, weight]

    def _heuristic_eta(self, route: Dict[str, Any], shipment: Dict[str, Any]) -> float:
        distance_km = float(route.get("total_distance_km", 0) or 0)
        planned_time = float(route.get("total_time_hours", 0) or 0)
        avg_speed = float(self.stats.get("avg_speed_kmph", 45) or 45)
        handling_hours = float(self.stats.get("handling_time_hours", 0.25) or 0.25)
        weight_factor = 1 + min(float(shipment.get("weight", 0) or 0) / 1000.0, 0.25)

        drive_time = distance_km / avg_speed if avg_speed > 0 else 0
        eta = max(planned_time, drive_time) * weight_factor + handling_hours
        return max(eta, planned_time or 0.1)
