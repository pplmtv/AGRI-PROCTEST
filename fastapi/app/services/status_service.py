# status_service.py
from boto3.dynamodb.conditions import Key
from app.db import sensor_table
from datetime import datetime, timezone

WORKING = "WORKING"
UNKNOWN = "UNKNOWN"
WORKING_THRESHOLD_MINUTES = 5


# -----------------------------
# Pure functions (Domain logic)
# -----------------------------

def calculate_diff_minutes(now: datetime, last_time: datetime) -> int:
    diff = (now - last_time).total_seconds() / 60
    if diff < 0:
        raise ValueError("Timestamp is in the future")
    return int(diff)


def judge_state(diff_minutes: int) -> str:
    if diff_minutes <= WORKING_THRESHOLD_MINUTES:
        return WORKING
    return UNKNOWN


# -----------------------------
# Application layer
# -----------------------------

def get_user_status(user: dict) -> dict:
    user_id = user["sub"]

    resp = sensor_table.query(
        KeyConditionExpression=Key("user_id").eq(user_id),
        ScanIndexForward=False,
        Limit=1,
    )

    items = resp.get("Items", [])

    if not items:
        return {
            "user_id": user_id,
            "state": UNKNOWN,
            "minutes_since_last_update": None,
            "latest_timestamp": None,
        }

    latest = items[0]
    ts = latest["timestamp"]

    last_time = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    now = datetime.now(timezone.utc)

    diff_minutes = calculate_diff_minutes(now, last_time)
    state = judge_state(diff_minutes)

    return {
        "user_id": user_id,
        "state": state,
        "minutes_since_last_update": diff_minutes,
        "latest_timestamp": ts,
    }