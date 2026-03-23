# init-users.sh
#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "================================"
echo "Init Users START"
echo "================================"

NETWORK="agri-poctest_default"
ENDPOINT="http://dynamodb-local:8000"
REGION="ap-northeast-1"

# -----------------------------
# DynamoDB Local 起動待ち
# -----------------------------
echo "Waiting for DynamoDB Local..."

until docker run --rm \
  --network $NETWORK \
  amazon/aws-cli \
  dynamodb list-tables \
  --endpoint-url $ENDPOINT \
  --region $REGION > /dev/null 2>&1
do
  echo "DynamoDB not ready... retrying in 2s"
  sleep 2
done

echo "DynamoDB ready."

# -----------------------------
# usersテーブル存在チェック
# -----------------------------
echo "Checking users table..."

TABLE_EXISTS=$(docker run --rm \
  --network $NETWORK \
  amazon/aws-cli \
  dynamodb list-tables \
  --endpoint-url $ENDPOINT \
  --region $REGION \
  --query "TableNames" \
  --output text | grep -w users || true)

if [ -z "$TABLE_EXISTS" ]; then
  echo "Creating users table..."

  docker run --rm \
    --network $NETWORK \
    amazon/aws-cli \
    dynamodb create-table \
    --table-name users \
    --attribute-definitions \
      AttributeName=user_id,AttributeType=S \
    --key-schema \
      AttributeName=user_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url $ENDPOINT \
    --region $REGION

  echo "Users table created."
else
  echo "Users table already exists."
fi

# -----------------------------
# データ投入（idempotent）
# -----------------------------
echo "Seeding users..."

seed_user () {
  USER_ID=$1
  EMAIL=$2
  ROLE=$3

  docker run --rm \
    --network $NETWORK \
    amazon/aws-cli \
    dynamodb put-item \
    --table-name users \
    --endpoint-url $ENDPOINT \
    --region $REGION \
    --condition-expression "attribute_not_exists(user_id)" \
    --item "{
      \"user_id\": {\"S\": \"$USER_ID\"},
      \"email\": {\"S\": \"$EMAIL\"},
      \"role\": {\"S\": \"$ROLE\"},
      \"status\": {\"S\": \"active\"}
    }" \
  || echo "User $USER_ID already exists, skipped."
}

seed_user "admin" "admin@example.com" "admin"
seed_user "farmer" "farmer@example.com" "farmer"
seed_user "family" "family@example.com" "family"

echo "================================"
echo "Init Users DONE"
echo "================================"