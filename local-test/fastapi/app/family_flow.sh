# family_flow.sh
#!/bin/bash

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x local-test/fastapi/app/family_flow.sh
#   local-test/fastapi/app/family_flow.sh
# ----------------------------

cd "$(dirname "$0")"

BASE_URL="http://localhost:8001"
COOKIE_FILE="cookies.txt"

# Cookie初期化
rm -f $COOKIE_FILE

echo "================================"
echo "STEP 0: init-relationship.sh"
echo "================================"
./scripts/init-relationship.sh

echo ""
echo "================================"
echo "STEP 1: Farmer login & write"
echo "================================"

curl -s -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=farmer&password=password" > /dev/null

curl -s -b $COOKIE_FILE \
  -X POST $BASE_URL/sensor-data \
  -H "Content-Type: application/json" \
  -d '{"temperature":30.5,"humidity":60}'

echo ""
echo "================================"
echo "STEP 2: Family login"
echo "================================"

rm -f $COOKIE_FILE

STATUS=$(curl -s -o /dev/null -w "%{http_code}" -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=family&password=password")

if [ "$STATUS" = "303" ]; then
  echo "Family login: SUCCESS (HTTP $STATUS)"
else
  echo "Family login: FAILED (HTTP $STATUS)"
  exit 1
fi

echo ""
echo "================================"
echo "STEP 3: Family reads data"
echo "================================"

RESPONSE=$(curl -s -b $COOKIE_FILE \
  "$BASE_URL/sensor-data?limit=5")

if echo "$RESPONSE" | grep -q '"items_by_farmer"'; then
  echo "Family read: SUCCESS"
else
  echo "Family read: FAILED"
  exit 1
fi

echo ""
echo ""
echo "================================"
echo "DONE"
echo "================================"