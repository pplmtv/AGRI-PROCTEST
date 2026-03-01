# db.py
import os
import boto3

APP_ENV = os.getenv("APP_ENV", "local")
print(f"### DynamoDB Init: APP_ENV={APP_ENV}")

if APP_ENV == "local":
    dynamodb = boto3.resource(
        "dynamodb",
        endpoint_url="http://dynamodb-local:8000",
        region_name="ap-northeast-1",
        aws_access_key_id="dummy",
        aws_secret_access_key="dummy"
    )
else:
    dynamodb = boto3.resource("dynamodb")

SENSOR_TABLE_NAME = os.environ["DYNAMODB_TABLE"]
REL_TABLE_NAME = os.environ["RELATIONSHIP_TABLE"]

sensor_table = dynamodb.Table(SENSOR_TABLE_NAME)
relationship_table = dynamodb.Table(REL_TABLE_NAME)