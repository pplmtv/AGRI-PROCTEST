#!/usr/bin/env bash
set -euo pipefail
set -a; source ../.env; set +a

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   cd fastapi
#   chmod +x ops/ecs_snapshot.sh
#   ops/ecs_snapshot.sh .
# ----------------------------

############################################
# Config（必要に応じて変更）
############################################
REGION=$AWS_REGION
CLUSTER_NAME=$CLUSTER_NAME
SERVICE_NAME=$SERVICE_NAME
TARGET_GROUP_ARN=$TARGET_GROUP_ARN

OUTPUT_DIR="$(cd "$(dirname "$0")" && pwd)/output/ecs_snapshot"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_FILE="${OUTPUT_DIR}/ecs_snapshot_${TIMESTAMP}.txt"

mkdir -p "${OUTPUT_DIR}"

############################################
# Helper
############################################
section () {
  echo
  echo "===== $1 "
}

############################################
# Snapshot start
############################################
{
echo "=================================================="
echo " AWS ECS SNAPSHOT"
echo " Generated at: $(date)"
echo "=================================================="

# ECS
section "ECS: CLUSTER"
aws ecs describe-clusters \
  --region "${REGION}" \
  --clusters "${CLUSTER_NAME}"

section "ECS: SERVICE"
aws ecs describe-services \
  --region "${REGION}" \
  --cluster "${CLUSTER_NAME}" \
  --services "${SERVICE_NAME}"

section "ECS: TASK LIST"
TASK_ARNS=$(aws ecs list-tasks \
  --region "${REGION}" \
  --cluster "${CLUSTER_NAME}" \
  --service-name "${SERVICE_NAME}" \
  --query 'taskArns[]' \
  --output text)

echo "${TASK_ARNS}"

if [[ -n "${TASK_ARNS}" ]]; then
  section "ECS: TASK DETAIL"
  aws ecs describe-tasks \
    --region "${REGION}" \
    --cluster "${CLUSTER_NAME}" \
    --tasks ${TASK_ARNS}
fi

section "ECS: TASK DEFINITION"
TASK_DEF_ARN=$(aws ecs describe-services \
  --region "${REGION}" \
  --cluster "${CLUSTER_NAME}" \
  --services "${SERVICE_NAME}" \
  --query 'services[0].taskDefinition' \
  --output text)

aws ecs describe-task-definition \
  --region "${REGION}" \
  --task-definition "${TASK_DEF_ARN}"

# Network
section "NETWORK: VPC"
aws ec2 describe-vpcs \
  --region "${REGION}"

section "NETWORK: SUBNET"
aws ec2 describe-subnets \
  --region "${REGION}"

section "NETWORK: ROUTE TABLE"
aws ec2 describe-route-tables \
  --region "${REGION}"

# ELB
section "ELB: TARGET GROUP HEALTH"
aws elbv2 describe-target-health \
  --region "${REGION}" \
  --target-group-arn "${TARGET_GROUP_ARN}"

# IAM
section "IAM: ECS RELATED ROLES"
aws iam list-roles \
  --query 'Roles[?contains(RoleName, `ecs`)]'

# Security Group
section "SECURITY GROUP"
aws ec2 describe-security-groups \
  --region "${REGION}"

echo
echo "===== SNAPSHOT COMPLETE ====="
} > "${OUT_FILE}"

echo "Snapshot written to:"
echo "  ${OUT_FILE}"
