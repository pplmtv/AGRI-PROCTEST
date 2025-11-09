from fastapi import APIRouter
from datetime import datetime
from decimal import Decimal
from app.models import SensorData
from app.db import table

router = APIRouter()

@router.post("/write")
def write_sensor_data(data: SensorData):
    try:
        response = table.put_item(
            Item={
                "user_id": data.user_id,
                "timestamp": datetime.utcnow().isoformat(),
                "temperature": Decimal(str(data.temperature)),
                "humidity": Decimal(str(data.humidity))
            }
        )
        return {"message": "データ書き込み成功", "aws_response": response}
    except Exception as e:
        return {"message": "エラー発生", "error": str(e)}