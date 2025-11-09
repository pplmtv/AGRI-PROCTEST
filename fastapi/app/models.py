from pydantic import BaseModel

class SensorData(BaseModel):
    user_id: str
    temperature: float
    humidity: float