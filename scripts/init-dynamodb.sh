#!/bin/sh
set -e
# ↑ 途中でエラーが出たら即終了（CI / docker-compose向け安全策）

# NOTE:
# This script is intended for DynamoDB Local (PoC / local dev only).
# Do NOT use this script against production DynamoDB.
#
# Time design:
# - timestamp is stored as ISO8601 UTC string (Z)
# - Used as Sort Key for time-series queries

# TODO:
# - Add GSI when cross-user or analytical queries are required
# - Revisit PK/SK design if aggregation unit changes

# -----------------------------
# DynamoDB Local 起動待ち
# -----------------------------
echo "Waiting for DynamoDB Local to be ready..."

until curl -s http://dynamodb-local:8000 > /dev/null; do
  echo "DynamoDB Local not ready yet... retrying in 2s"
  sleep 2
done

echo "DynamoDB Local is ready."

# -----------------------------
# 既存テーブルの確認
# -----------------------------
echo "Checking DynamoDB tables..."

TABLES=$(aws dynamodb list-tables \
  --endpoint-url http://dynamodb-local:8000 \
  --output text \
  --query 'TableNames[]')

# -----------------------------
# SensorData テーブルの作成
# -----------------------------
if echo "$TABLES" | grep -q "SensorData"; then
  echo "Table SensorData already exists."
else
  echo "Creating table SensorData..."

  # SensorData table (PoC design)
  # - PK : user_id (logical user ID, future Cognito sub)
  # - SK : timestamp (ISO8601 UTC string)

  aws dynamodb create-table \
    --table-name SensorData \
    --attribute-definitions \
      AttributeName=user_id,AttributeType=S \
      AttributeName=timestamp,AttributeType=S \
    --key-schema \
      AttributeName=user_id,KeyType=HASH \
      AttributeName=timestamp,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url http://dynamodb-local:8000 \
    --region ap-northeast-1

  echo "Table SensorData created!"
fi
