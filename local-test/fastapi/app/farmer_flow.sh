# farmer_flow.sh
#!/bin/bash

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x local-test/fastapi/app/farmer_flow.sh
#   local-test/fastapi/app/farmer_flow.sh
# ----------------------------

cd "$(dirname "$0")"

BASE_URL="http://localhost:8001"
COOKIE_FILE="cookies.txt"

# Cookie初期化
rm -f $COOKIE_FILE

echo "================================"
echo "STEP 1: Login"
echo "================================"

curl -i -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=farmer&password=password"

echo ""
echo "================================"
echo "STEP 2: Post sensor data"
echo "================================"

curl -b $COOKIE_FILE \
  -X POST $BASE_URL/sensor-data \
  -H "Content-Type: application/json" \
  -d @sample_payloads/sensor.json

echo ""
echo "================================"
echo "STEP 3: List sensor data"
echo "================================"

curl -b $COOKIE_FILE \
  $BASE_URL/sensor-data?limit=5

echo ""
echo "================================"
echo "STEP 4: Status check"
echo "================================"

STATUS_RESPONSE=$(curl -s -b $COOKIE_FILE \
  $BASE_URL/users/me/status)

echo "$STATUS_RESPONSE"

if echo "$STATUS_RESPONSE" | grep -q '"state"'; then
  echo "Status check: SUCCESS"
else
  echo "Status check: FAILED"
  exit 1
fi

echo ""
echo "================================"
echo "DONE"
echo "================================"