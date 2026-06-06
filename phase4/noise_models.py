import random
import math



DRIVER_TYPES = [
    ("junior",   1.10, 0.20),
    ("standard", 1.00, 0.60),
    ("senior",   0.92, 0.20),
]


def driver_delay(expected_hours: float) -> float:
    """Returns signed delay in hours due to driver experience."""
    label, factor, _ = random.choices(
        DRIVER_TYPES, weights=[d[2] for d in DRIVER_TYPES]
    )[0]
    return round((factor - 1.0) * expected_hours, 4)



def vehicle_delay() -> float:
    """Returns delay hours due to vehicle age / minor mechanical issue."""
    age_years = random.expovariate(1 / 5)          # mean 5 years
    breakdown_prob = (age_years / 20) * 0.30       # max ~15% at 10y
    if random.random() < breakdown_prob:
        return round(random.uniform(0.2, 0.8), 4)
    return 0.0



LOCAL_EVENTS = {
    "coastal": [
        {"name": "beach_traffic_peak",   "months": [6,7,8],    "hours": list(range(10,16)), "prob": 0.08, "delay": (0.3, 1.5)},
        {"name": "summer_festival",      "months": [6,7,8,9],  "hours": None,               "prob": 0.04, "delay": (0.5, 2.0)},
        {"name": "bura_slowdown",        "months": [10,11,1,2],"hours": None,               "prob": 0.06, "delay": (0.4, 1.8)},
    ],
    "highway": [
        {"name": "toll_queue",           "months": None,        "hours": [7,8,16,17,18],     "prob": 0.06, "delay": (0.1, 0.5)},
        {"name": "unpredicted_jam",      "months": None,        "hours": None,               "prob": 0.03, "delay": (0.5, 2.5)},
    ],
    "regional": [
        {"name": "tractor_on_road",      "months": [3,4,5,9,10],"hours": list(range(7,19)), "prob": 0.07, "delay": (0.2, 0.8)},
        {"name": "school_zone",          "months": None,        "hours": [7,8,14,15],        "prob": 0.04, "delay": (0.1, 0.3)},
        {"name": "market_day",           "months": None,        "hours": [8,9,10,11],        "prob": 0.04, "delay": (0.1, 0.4)},
    ],
    "mixed": [
        {"name": "road_works_minor",     "months": [4,5,6,9],  "hours": list(range(8,18)),  "prob": 0.06, "delay": (0.3, 1.2)},
        {"name": "unpredicted_jam",      "months": None,        "hours": None,               "prob": 0.03, "delay": (0.3, 1.5)},
    ],
}


def local_event_delay(road_type: str, month: int, hour: int) -> float:
    """Returns delay hours from local route events."""
    events = LOCAL_EVENTS.get(road_type, LOCAL_EVENTS["highway"])
    total  = 0.0
    for ev in events:
        month_ok = (ev["months"] is None) or (month in ev["months"])
        hour_ok  = (ev["hours"]  is None) or (hour  in ev["hours"])
        if month_ok and hour_ok and random.random() < ev["prob"]:
            total += random.uniform(*ev["delay"])
    return round(total, 4)



DELIVERY_ISSUES = [
    {"name": "wrong_address",        "prob": 0.012, "delay": (0.5, 1.5)},
    {"name": "recipient_not_home",   "prob": 0.025, "delay": (0.3, 1.0)},
    {"name": "loading_dock_busy",    "prob": 0.035, "delay": (0.2, 0.8)},
    {"name": "paperwork_issue",      "prob": 0.010, "delay": (0.3, 0.6)},
    {"name": "early_recipient",      "prob": 0.030, "delay": (-0.3, -0.1)},
]


def delivery_issue_delay() -> float:
    """Returns signed delay hours from delivery-point issues."""
    total = 0.0
    for issue in DELIVERY_ISSUES:
        if random.random() < issue["prob"]:
            total += random.uniform(*issue["delay"])
    return round(total, 4)



def residual_noise() -> float:
    """Small catch-all noise — everything we didn't model explicitly."""
    return round(random.gauss(0, 0.20), 4)



def total_hidden_delay(expected_hours: float, road_type: str,
                       month: int, hour: int) -> float:
    """
    Sum of all five noise sources.
    Positive = delayed, negative = early arrival.
    """
    total = (
        driver_delay(expected_hours)
        + vehicle_delay()
        + local_event_delay(road_type, month, hour)
        + delivery_issue_delay()
        + residual_noise()
    )
    return round(total, 4)