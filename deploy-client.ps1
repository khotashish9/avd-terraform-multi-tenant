param(
  [Parameter(Mandatory=$true)][string]$Client
)
$ErrorActionPreference = "Stop"
az account show | Out-Null
terraform init -reconfigure -backend-config="backends/$Client.hcl"
terraform fmt -recursive
terraform validate
terraform plan -var-file="clients/$Client.tfvars" -out="$Client.tfplan"
Write-Host "Review $Client.tfplan, then run: terraform apply $Client.tfplan"
