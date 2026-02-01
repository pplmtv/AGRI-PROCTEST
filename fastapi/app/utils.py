# utils.py
from decimal import Decimal
from datetime import datetime, timezone

def to_decimal(val: float) -> Decimal:
    return Decimal(str(val))

def utc_iso8601() -> str:
    """
    Return UTC time in ISO8601 format with 'Z'
    Example: 2026-02-01T12:23:43.640990Z
    """
    return datetime.now(timezone.utc) \
        .isoformat(timespec="microseconds") \
        .replace("+00:00", "Z")