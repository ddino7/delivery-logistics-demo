import json
import os
from datetime import date

_BASE_DIR         = os.path.dirname(os.path.abspath(__file__))
_HAC_DATA_FILE    = os.path.join(_BASE_DIR, "hac_traffic.json")

ROUTE_TO_SEGMENT = {
    frozenset(["Zagreb",        "Split"]):          "A1_Zagreb_Split",
    frozenset(["Zagreb",        "Dubrovnik"]):       "A1_Zagreb_Dubrovnik",
    frozenset(["Zagreb",        "Zadar"]):           "A1_Zagreb_Zadar",
    frozenset(["Zagreb",        "Sibenik"]):         "A1_Zagreb_Sibenik",
    frozenset(["Zagreb",        "Rijeka"]):          "A6_Zagreb_Rijeka",
    frozenset(["Zagreb",        "Pula"]):            "A6_Zagreb_Pula",
    frozenset(["Zagreb",        "Osijek"]):          "A3_Zagreb_Osijek",
    frozenset(["Zagreb",        "Slavonski Brod"]):  "A3_Zagreb_SlavonskiBrod",
    frozenset(["Zagreb",        "Karlovac"]):        "A1_Zagreb_Karlovac",
    frozenset(["Zagreb",        "Varazdin"]):        "A4_Zagreb_Varazdin",
    frozenset(["Split",         "Dubrovnik"]):       "A1_Split_Dubrovnik",
    frozenset(["Split",         "Zadar"]):           "A1_Split_Zadar",
    frozenset(["Split",         "Sibenik"]):         "A1_Split_Sibenik",
    frozenset(["Rijeka",        "Pula"]):            "A8_Rijeka_Pula",
    frozenset(["Osijek",        "Slavonski Brod"]):  "A3_Osijek_SlavonskiBrod",
}



_SEGMENT_PROFILES = {
    # Strong tourist seasonality — A1 towards the coast
    "A1_Zagreb_Split":       [1.00,1.02,1.08,1.20,1.35,1.65,2.50,2.80,1.80,1.25,1.05,0.95],
    "A1_Zagreb_Dubrovnik":   [1.00,1.02,1.08,1.22,1.38,1.70,2.65,2.90,1.85,1.28,1.05,0.94],
    "A1_Zagreb_Zadar":       [1.00,1.02,1.07,1.18,1.32,1.60,2.40,2.70,1.72,1.22,1.04,0.95],
    "A1_Zagreb_Sibenik":     [1.00,1.02,1.07,1.19,1.33,1.62,2.42,2.72,1.74,1.23,1.04,0.95],
    "A1_Zagreb_Karlovac":    [1.00,1.03,1.10,1.25,1.38,1.55,1.80,1.90,1.50,1.28,1.06,0.96],
    "A1_Split_Dubrovnik":    [1.00,1.02,1.06,1.20,1.40,1.75,2.70,2.95,1.90,1.30,1.04,0.93],
    "A1_Split_Zadar":        [1.00,1.02,1.06,1.18,1.35,1.65,2.45,2.75,1.75,1.24,1.04,0.94],
    "A1_Split_Sibenik":      [1.00,1.02,1.06,1.18,1.35,1.65,2.45,2.75,1.75,1.24,1.04,0.94],

    # Moderate tourist seasonality — A6/A8 Istria & Kvarner
    "A6_Zagreb_Rijeka":      [1.00,1.03,1.10,1.22,1.35,1.55,2.10,2.25,1.60,1.28,1.07,0.97],
    "A6_Zagreb_Pula":        [1.00,1.03,1.10,1.22,1.38,1.60,2.20,2.35,1.65,1.30,1.07,0.97],
    "A8_Rijeka_Pula":        [1.00,1.03,1.10,1.25,1.42,1.70,2.30,2.50,1.72,1.32,1.08,0.96],

    # Mostly flat — continental/Slavonia routes
    "A3_Zagreb_Osijek":      [1.00,1.02,1.06,1.10,1.14,1.18,1.22,1.20,1.12,1.08,1.02,0.97],
    "A3_Zagreb_SlavonskiBrod":[1.00,1.02,1.05,1.09,1.13,1.16,1.20,1.18,1.11,1.07,1.02,0.97],
    "A3_Osijek_SlavonskiBrod":[1.00,1.01,1.04,1.08,1.11,1.13,1.16,1.15,1.08,1.05,1.01,0.97],
    "A4_Zagreb_Varazdin":    [1.00,1.02,1.05,1.10,1.14,1.17,1.20,1.19,1.12,1.08,1.02,0.97],
}

_WEEKEND_MULT = {
    "A1_Zagreb_Split":       1.35,
    "A1_Zagreb_Dubrovnik":   1.38,
    "A1_Zagreb_Zadar":       1.30,
    "A1_Zagreb_Sibenik":     1.30,
    "A1_Zagreb_Karlovac":    1.20,
    "A1_Split_Dubrovnik":    1.40,
    "A1_Split_Zadar":        1.32,
    "A1_Split_Sibenik":      1.32,
    "A6_Zagreb_Rijeka":      1.28,
    "A6_Zagreb_Pula":        1.30,
    "A8_Rijeka_Pula":        1.32,
    "A3_Zagreb_Osijek":      1.10,
    "A3_Zagreb_SlavonskiBrod":1.10,
    "A3_Osijek_SlavonskiBrod":1.08,
    "A4_Zagreb_Varazdin":    1.12,
}

_HOLIDAY_MULT = {
    "Velika Gospa":   {"A1_Zagreb_Split": 1.55, "A1_Zagreb_Dubrovnik": 1.60,
                       "A1_Split_Dubrovnik": 1.65, "default": 1.20},
    "Uskrs":          {"A1_Zagreb_Split": 1.35, "A1_Zagreb_Dubrovnik": 1.38,
                       "default": 1.18},
    "Tijelovo":       {"default": 1.12},
    "Dan pobjede":    {"A1_Zagreb_Split": 1.45, "A1_Zagreb_Dubrovnik": 1.50,
                       "default": 1.20},
    "Blagdan svih svetih": {"default": 1.08},
    "Božić":          {"default": 0.75},
    "Nova godina":    {"default": 0.70},
}

_DEFAULT_SEGMENT = "A3_Zagreb_Osijek"


def _get_segment(origin: str, destination: str) -> str:
    key = frozenset([origin, destination])
    return ROUTE_TO_SEGMENT.get(key, _DEFAULT_SEGMENT)


def get_traffic_load_factor(origin: str, destination: str,
                             target_date: date,
                             holiday_name: str | None = None) -> float:
    """
    Returns traffic load factor for the given route and date.
    1.0 = average January baseline. Values above 1.0 mean heavier traffic.

    Steps:
      1. Seasonal factor from HAC monthly profile
      2. Weekend multiplier if applicable
      3. Holiday multiplier if it's a public holiday
    """
    segment = _get_segment(origin, destination)
    profile = _SEGMENT_PROFILES.get(segment, _SEGMENT_PROFILES[_DEFAULT_SEGMENT])

    seasonal = profile[target_date.month - 1]

    is_weekend = target_date.weekday() >= 5
    weekend_mult = _WEEKEND_MULT.get(segment, 1.10) if is_weekend else 1.0

    holiday_mult = 1.0
    if holiday_name and holiday_name in _HOLIDAY_MULT:
        hm = _HOLIDAY_MULT[holiday_name]
        holiday_mult = hm.get(segment, hm.get("default", 1.0))

    factor = round(seasonal * weekend_mult * holiday_mult, 3)
    return factor