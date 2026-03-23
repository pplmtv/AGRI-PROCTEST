# user_service.py
import os
from datetime import datetime, timezone
from boto3.dynamodb.conditions import Key
from app.db import dynamodb

USER_TABLE_NAME = os.environ.get("USER_TABLE", "users")
user_table = dynamodb.Table(USER_TABLE_NAME)


def get_user(user_id: str):
    resp = user_table.get_item(Key={"user_id": user_id})
    return resp.get("Item")


def create_user(user_id: str, email: str, role: str = "family"):
    now = datetime.now(timezone.utc).isoformat()

    item = {
        "user_id": user_id,
        "email": email,
        "role": role,
        "created_at": now,
        "status": "active",
    }

    user_table.put_item(Item=item)
    return item