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

TABLE_NAME = os.getenv("DYNAMODB_TABLE", "SensorData")
table = dynamodb.Table(TABLE_NAME)