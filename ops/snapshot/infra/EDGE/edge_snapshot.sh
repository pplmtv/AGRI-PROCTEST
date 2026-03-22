# edge_snapshot.sh
#!/usr/bin/env bash
set -euo pipefail
set -a; source .env; set +a

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x ops/snapshot/infra/EDGE/edge_snapshot.sh
#   ops/snapshot/infra/EDGE/edge_snapshot.sh .
# ----------------------------

############################################
# Config
############################################
REGION=$AWS_REGION
HOSTED_ZONE_ID=${HOSTED_ZONE_ID:-""}
DOMAIN_NAME=${DOMAIN_NAME:-""}
LOAD_BALANCER_ARN=${LOAD_BALANCER_ARN:-""}

OUTPUT_DIR="$(cd "$(dirname "$0")" && pwd)/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_FILE="${OUTPUT_DIR}/edge_snapshot_${TIMESTAMP}.txt"

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
echo " AWS EDGE SNAPSHOT (Route53 / ACM / ALB)"
echo " Generated at: $(date)"
echo "=================================================="

############################################
# Route53
############################################
section "Route53: Hosted Zones"

aws route53 list-hosted-zones

if [[ -n "${HOSTED_ZONE_ID}" ]]; then
  section "Route53: Record Sets (${HOSTED_ZONE_ID})"

  aws route53 list-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}"
else
  echo "HOSTED_ZONE_ID not set → skip record sets"
fi

############################################
# ACM（証明書）
############################################
section "ACM: Certificates"

aws acm list-certificates \
  --region "${REGION}"

if [[ -n "${DOMAIN_NAME}" ]]; then
  section "ACM: Describe Certificate (${DOMAIN_NAME})"

  CERT_ARN=$(aws acm list-certificates \
    --region "${REGION}" \
    --query "CertificateSummaryList[?DomainName=='${DOMAIN_NAME}'].CertificateArn" \
    --output text)

  if [[ -n "${CERT_ARN}" && "${CERT_ARN}" != "None" ]]; then
    aws acm describe-certificate \
      --region "${REGION}" \
      --certificate-arn "${CERT_ARN}"
  else
    echo "No certificate found for ${DOMAIN_NAME}"
  fi
else
  echo "DOMAIN_NAME not set → skip describe-certificate"
fi

############################################
# ALB（Load Balancer）
############################################
section "ELBv2: Load Balancers"

aws elbv2 describe-load-balancers \
  --region "${REGION}"

if [[ -n "${LOAD_BALANCER_ARN}" ]]; then

  section "ELBv2: Listeners (${LOAD_BALANCER_ARN})"

  aws elbv2 describe-listeners \
    --region "${REGION}" \
    --load-balancer-arn "${LOAD_BALANCER_ARN}"

  LISTENER_ARNS=$(aws elbv2 describe-listeners \
    --region "${REGION}" \
    --load-balancer-arn "${LOAD_BALANCER_ARN}" \
    --query "Listeners[].ListenerArn" \
    --output text)

  for L in ${LISTENER_ARNS}; do
    section "ELBv2: Listener Rules (${L})"
    aws elbv2 describe-rules \
      --region "${REGION}" \
      --listener-arn "${L}"
  done

else
  echo "LOAD_BALANCER_ARN not set → skip listeners"
fi

############################################
# Target Group
############################################
section "ELBv2: Target Groups"

aws elbv2 describe-target-groups \
  --region "${REGION}"

############################################
# Target Health（重要）
############################################
section "ELBv2: Target Health"

TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups \
  --region "${REGION}" \
  --query "TargetGroups[].TargetGroupArn" \
  --output text)

for TG in ${TARGET_GROUP_ARNS}; do
  section "Target Health (${TG})"
  aws elbv2 describe-target-health \
    --region "${REGION}" \
    --target-group-arn "${TG}"
done

############################################
# Security Groups（ALB周辺）
############################################
section "EC2: Security Groups"

aws ec2 describe-security-groups \
  --region "${REGION}"

############################################
# VPC Endpoints（Secrets / ACMなど）
############################################
section "EC2: VPC Endpoints"

aws ec2 describe-vpc-endpoints \
  --region "${REGION}"

echo
echo "===== SNAPSHOT COMPLETE ====="

} > "${OUT_FILE}"

echo "======================================"
echo "EDGE snapshot written to:"
echo "  ${OUT_FILE}"
echo "======================================"