# dynamodb_schema_snapshot.sh
#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# Load .env (same behavior as dynamodb_schema_snapshot.sh)
# --------------------------------------------
set -a; source ./.env; set +a

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x ops/snapshot/infra/DynamoDB/dynamodb_schema_snapshot.sh
#   ops/snapshot/infra/DynamoDB/dynamodb_schema_snapshot.sh .
# ----------------------------

############################################
# Config
############################################
REGION="${AWS_REGION}"
SENSOR_TABLE="${DYNAMODB_TABLE}"
REL_TABLE="${RELATIONSHIP_TABLE}"

# Output directory
OUTPUT_DIR="$(cd "$(dirname "$0")" && pwd)/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_FILE="${OUTPUT_DIR}/dynamodb_snapshot_${TIMESTAMP}.txt"
mkdir -p "${OUTPUT_DIR}"

############################################
# Helper
############################################
section () {
  echo
  echo "===== $1 "
}

############################################
# Snapshot Start
############################################
{
echo "=================================================="
echo " AWS DynamoDB SCHEMA SNAPSHOT"
echo " Generated at: $(date)"
echo "=================================================="

echo "REGION               = ${REGION}"
echo "DYNAMODB_TABLE       = ${SENSOR_TABLE}"
echo "RELATIONSHIP_TABLE   = ${REL_TABLE}"

############################################
# SENSOR DATA TABLE
############################################
section "DynamoDB: SENSOR TABLE (${SENSOR_TABLE})"

aws dynamodb describe-table \
  --region "${REGION}" \
  --table-name "${SENSOR_TABLE}" \
  --query "{ 
      TableName:Table.TableName,
      KeySchema:Table.KeySchema,
      AttributeDefinitions:Table.AttributeDefinitions,
      BillingModeSummary:Table.BillingModeSummary
  }"

############################################
# RELATIONSHIP TABLE
############################################
section "DynamoDB: RELATIONSHIP TABLE (${REL_TABLE})"

aws dynamodb describe-table \
  --region "${REGION}" \
  --table-name "${REL_TABLE}" \
  --query "{ 
      TableName:Table.TableName,
      KeySchema:Table.KeySchema,
      AttributeDefinitions:Table.AttributeDefinitions,
      BillingModeSummary:Table.BillingModeSummary
  }"

############################################
# OPTIONAL: List All DynamoDB Tables
############################################
section "DynamoDB: LIST ALL TABLES"

aws dynamodb list-tables \
  --region "${REGION}"

echo
echo "===== SNAPSHOT COMPLETE ====="

} > "${OUT_FILE}"

echo "Snapshot written to:"
echo "  ${OUT_FILE}"