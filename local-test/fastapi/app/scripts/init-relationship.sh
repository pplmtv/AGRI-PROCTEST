# init-relationship.sh
#!/bin/bash

cd "$(dirname "$0")"

echo "Seeding relationship table..."

docker run --rm \
  --network agri-poctest_default \
  -e AWS_ACCESS_KEY_ID=dummy \
  -e AWS_SECRET_ACCESS_KEY=dummy \
  amazon/aws-cli \
  dynamodb put-item \
  --table-name agri-poc-relationship \
  --endpoint-url http://dynamodb-local:8000 \
  --region ap-northeast-1 \
  --item '{
    "family_id": {"S": "family"},
    "farmer_id": {"S": "farmer"}
  }'

echo "Done."