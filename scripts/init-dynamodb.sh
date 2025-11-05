#!/bin/sh
set -e

echo "Waiting for DynamoDB Local to be ready..."

until curl -s http://dynamodb-local:8000 > /dev/null; do
  echo "DynamoDB Local not ready yet... retrying in 2s"
  sleep 2
done

echo "Checking DynamoDB tables..."

TABLES=$(aws dynamodb list-tables \
  --endpoint-url http://dynamodb-local:8000 \
  --output text --query 'TableNames[]')

if echo "$TABLES" | grep -q "SensorData"; then
  echo "Table SensorData already exists."
else
  echo "Creating table SensorData..."
  aws dynamodb create-table \
    --table-name SensorData \
    --attribute-definitions AttributeName=user_id,AttributeType=S \
    --key-schema AttributeName=user_id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --endpoint-url http://dynamodb-local:8000 \
    --region ap-northeast-1
  echo "Table SensorData created!"
fi