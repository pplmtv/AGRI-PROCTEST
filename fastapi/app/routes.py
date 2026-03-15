# routes.py
from fastapi import APIRouter, Query
from datetime import datetime, timezone
from decimal import Decimal
from app.models import SensorData
from fastapi import Depends
from app.auth import require_login,require_role
from boto3.dynamodb.conditions import Key
from app.utils import utc_iso8601
from app.db import sensor_table
from app.services.relationship_service import get_accessible_farmer_ids, list_all_farmers
from app.services.status_service import get_user_status

# NOTE:
# user_id is a logical identifier for PoC.
# This will be replaced by Cognito 'sub' after authentication is migrated to AWS Cognito.

router = APIRouter()

@router.get("/sensor-data")
def list_sensor_data(
    limit: int = Query(10, ge=1, le=100),
    user=Depends(require_login),
):
    farmer_ids = get_accessible_farmer_ids(user)

    if not farmer_ids:
        # familyで紐づきがないケースなど
        return {"items_by_farmer": {}}

    items_by_farmer = {}
    for farmer_id in farmer_ids:
        resp = sensor_table.query(
            KeyConditionExpression=Key("user_id").eq(farmer_id),
            ScanIndexForward=False,
            Limit=limit,
        )
        items_by_farmer[farmer_id] = resp.get("Items", [])

    return {"items_by_farmer": items_by_farmer}

@router.post("/sensor-data")
def write_sensor_data(
    data: SensorData,
    user=Depends(require_role("farmer")),  # adminも書けるのはROLE_LEVELで担保
    ):
    try:
        ts = utc_iso8601()
        # NOTE:
        # timestamp is ISO8601 UTC string (Sort Key)
        # This will be used as the single time axis for time-series queries.

        response = sensor_table.put_item(
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
    #TODO 内部情報漏洩に繋がるため、本番時はexcept Exception as e:を除外し、以下に変更
    # raise HTTPException(status_code=500, detail="Internal error")
    
@router.get("/api/me")
def me(user=Depends(require_login)):
    return user

@router.get("/users/me/status")
def get_my_status(user=Depends(require_login)):
    return get_user_status(user)

@router.get("/admin/farmers")
def list_farmers_status(
    user=Depends(require_role("admin"))
):
    farmers = list_all_farmers()

    results = []

    for farmer_id in farmers:
        farmer_user = {
            "sub": farmer_id,
            "role": "farmer"
        }

        status = get_user_status(farmer_user)

        results.append(status)

    return {"farmers": results}