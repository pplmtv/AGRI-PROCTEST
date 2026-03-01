# pre_deploy_security_check.sh
#!/bin/bash

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x local-test/fastapi/app/pre_deploy_security_check.sh
#   local-test/fastapi/app/pre_deploy_security_check.sh
# ----------------------------

cd "$(dirname "$0")"

BASE_URL="http://localhost:8001"
COOKIE_FILE="cookies.txt"

echo "================================"
echo "PRE DEPLOY SECURITY CHECK START"
echo "================================"

########################################
# 1. 未ログインアクセス拒否確認
########################################

echo ""
echo "[1] Unauthenticated access check"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  $BASE_URL/sensor-data)

if [ "$HTTP_STATUS" -eq 401 ]; then
  echo "PASS: /sensor-data requires login (401)"
else
  echo "FAIL: /sensor-data returned $HTTP_STATUS"
  exit 1
fi

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  $BASE_URL/users/me/status)

if [ "$HTTP_STATUS" -eq 401 ]; then
  echo "PASS: /users/me/status requires login (401)"
else
  echo "FAIL: /users/me/status returned $HTTP_STATUS"
  exit 1
fi


########################################
# 2. Farmer 正常系確認
########################################

echo ""
echo "[2] Farmer normal flow"

rm -f $COOKIE_FILE

curl -s -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=farmer&password=password" > /dev/null

WRITE_RESPONSE=$(curl -s -b $COOKIE_FILE \
  -X POST $BASE_URL/sensor-data \
  -H "Content-Type: application/json" \
  -d '{"temperature":30.5,"humidity":60}')

if echo "$WRITE_RESPONSE" | grep -q '"WRITE OK"'; then
  echo "PASS: Farmer write OK"
else
  echo "FAIL: Farmer write failed"
  exit 1
fi


########################################
# 3. Family がPOSTできない確認
########################################

echo ""
echo "[3] Family cannot write"

rm -f $COOKIE_FILE

curl -s -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=family&password=password" > /dev/null

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -b $COOKIE_FILE \
  -X POST $BASE_URL/sensor-data \
  -H "Content-Type: application/json" \
  -d '{"temperature":30.5,"humidity":60}')

if [ "$HTTP_STATUS" -eq 403 ]; then
  echo "PASS: Family write blocked (403)"
else
  echo "FAIL: Family write returned $HTTP_STATUS"
  exit 1
fi


########################################
# 4. Status 正常確認
########################################

echo ""
echo "[4] Status endpoint works"

rm -f $COOKIE_FILE

curl -s -c $COOKIE_FILE \
  -X POST $BASE_URL/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=farmer&password=password" > /dev/null

STATUS_RESPONSE=$(curl -s -b $COOKIE_FILE \
  $BASE_URL/users/me/status)

if echo "$STATUS_RESPONSE" | grep -q '"state"'; then
  echo "PASS: Status endpoint OK"
else
  echo "FAIL: Status endpoint failed"
  exit 1
fi


echo ""
echo "================================"
echo "ALL CHECKS PASSED"
echo "READY FOR DEPLOY"
echo "================================"