# farmer_inactive_flow.sh
#!/bin/bash

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x local-test/fastapi/app/farmer_inactive_flow.sh
#   local-test/fastapi/app/farmer_inactive_flow.sh
# ----------------------------

cd "$(dirname "$0")"

BASE_URL="http://localhost:8001"
COOKIE_FILE="cookies.txt"

echo "================================"
echo "INACTIVE TEST (REQUIRES CLEAN DB)"
echo "================================"

echo ""
echo "IMPORTANT:"
echo "Run 'docker-compose down -v && docker-compose up -d'"
echo "before executing this script."
echo ""

read -p "Have you reset the DB? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
  echo "Aborted."
  exit 1
fi

rm -f $COOKIE_FILE

echo ""
echo "[1] Login as farmer (no post)"

curl -s -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=farmer&password=password" > /dev/null

echo "Login done."

echo ""
echo "[2] Status check (without posting)"

STATUS_RESPONSE=$(curl -s -b $COOKIE_FILE \
  $BASE_URL/users/me/status)

echo "$STATUS_RESPONSE"

if echo "$STATUS_RESPONSE" | grep -q '"state":"UNKNOWN"'; then
  echo ""
  echo "Inactive test: SUCCESS (UNKNOWN as expected)"
else
  echo ""
  echo "Inactive test: FAILED"
  exit 1
fi

echo ""
echo "================================"
echo "INACTIVE TEST PASSED"
echo "================================"