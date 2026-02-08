# routes.py
from fastapi import APIRouter, Query
from datetime import datetime, timezone
from decimal import Decimal
from app.models import SensorData
from app.db import table
from fastapi import Depends
from app.auth import require_login
from boto3.dynamodb.conditions import Key
from app.db import table
from app.utils import utc_iso8601

# NOTE:
# user_id is a logical identifier for PoC.
# This will be replaced by Cognito 'sub' after authentication is migrated to AWS Cognito.

router = APIRouter()

@router.post("/write")
def write_sensor_data(
    data: SensorData,
    user=Depends(require_login),
    ):
    try:
        ts = utc_iso8601()
        # NOTE:
        # timestamp is ISO8601 UTC string (Sort Key)
        # This will be used as the single time axis for time-series queries.

        response = table.put_item(
            Item={
                "user_id": user["sub"],  # JWTから取得
                "timestamp": ts,   # Sort Key
                "temperature": Decimal(str(data.temperature)),
                "humidity": Decimal(str(data.humidity)),
            }
        )
        return {
            "message": "WRITE OK", 
            "timestamp": ts,
            "user_id": user["sub"]
        }
    except Exception as e:
        return {
            "message": "WRITE NG",
            "error": str(e)
        }
    
@router.get("/api/me")
def me(user=Depends(require_login)):
    return user

@router.get("/sensor-data")
def list_sensor_data(
    user_id: str = Query(...),
    limit: int = Query(10, ge=1, le=100),
):
    resp = table.query(
        KeyConditionExpression=Key("user_id").eq(user_id),
        ScanIndexForward=False,
        Limit=limit,
    )
    return {
        "items": resp.get("Items", [])
    }