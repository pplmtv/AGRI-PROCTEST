# admin_flow.sh
#!/bin/bash

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x local-test/fastapi/app/admin_flow.sh
#   local-test/fastapi/app/admin_flow.sh
# ----------------------------

cd "$(dirname "$0")"

BASE_URL="http://localhost:8001"
COOKIE_FILE="cookies.txt"

rm -f $COOKIE_FILE

echo "================================"
echo "STEP 0: init relationship"
echo "================================"

./scripts/init-relationship.sh

echo ""
echo "================================"
echo "STEP 1: farmer login"
echo "================================"

curl -s -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=farmer&password=password" > /dev/null

echo "Farmer login OK"

echo ""
echo "================================"
echo "STEP 2: write sensor data"
echo "================================"

curl -s -b $COOKIE_FILE \
  -X POST $BASE_URL/sensor-data \
  -H "Content-Type: application/json" \
  -d '{"temperature":25.5,"humidity":60}'

echo ""
echo "Sensor data written"

echo ""
echo "================================"
echo "STEP 3: admin login"
echo "================================"

rm -f $COOKIE_FILE

curl -s -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=password" > /dev/null

echo "Admin login OK"

echo ""
echo "================================"
echo "STEP 4: admin fetch farmers"
echo "================================"

RESPONSE=$(curl -s -b $COOKIE_FILE \
  $BASE_URL/admin/farmers)

echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"state"'; then
  echo ""
  echo "Admin dashboard: SUCCESS"
else
  echo ""
  echo "Admin dashboard: FAILED"
  exit 1
fi

echo ""
echo "================================"
echo "DONE"
echo "================================"