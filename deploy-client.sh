#!/usr/bin/env bash
set -euo pipefail
CLIENT="${1:?Usage: ./scripts/deploy-client.sh <client-code>}"
az account show >/dev/null
terraform init -reconfigure -backend-config="backends/${CLIENT}.hcl"
terraform fmt -recursive
terraform validate
terraform plan -var-file="clients/${CLIENT}.tfvars" -out="${CLIENT}.tfplan"
echo "Review ${CLIENT}.tfplan, then run: terraform apply ${CLIENT}.tfplan"
