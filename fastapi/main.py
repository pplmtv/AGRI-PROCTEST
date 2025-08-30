from fastapi import FastAPI
from pydantic import BaseModel
import boto3
from datetime import datetime
from decimal import Decimal

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "FastAPI is running!"}

@app.get("/ping")
def ping():
    return {"message": "pong"}

# DynamoDB テーブル設定
dynamodb = boto3.resource("dynamodb", region_name="ap-northeast-1")
table = dynamodb.Table("agri-poc")

# リクエストモデル
class SensorData(BaseModel):
    user_id: str
    temperature: float
    humidity: float

@app.post("/write")
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