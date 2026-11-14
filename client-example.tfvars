# Copy this file for each customer. Never commit customer secrets.
subscription_id       = "00000000-0000-0000-0000-000000000000"
client_code           = "contoso"
environment           = "prod"
location              = "West Europe"
resource_group_name   = "rg-contoso-avd-prod"
create_resource_group = true

# Network: use create_network=false and existing_subnet_id for a customer-managed VNet.
create_network          = true
vnet_name               = "vnet-contoso-avd-prod"
vnet_address_space      = ["10.60.0.0/16"]
subnet_name             = "snet-contoso-avd-hosts"
subnet_address_prefixes = ["10.60.10.0/24"]

host_pool_name         = "hp-contoso-prod"
workspace_name         = "ws-contoso-prod"
application_group_name = "dag-contoso-prod"
host_pool_type         = "Pooled"
load_balancer_type     = "BreadthFirst"
maximum_sessions_allowed = 10

session_host_count = 2
vm_size            = "Standard_D4s_v5"
admin_username     = "avdlocaladmin"
# Supply admin_password through TF_VAR_admin_password, not in this file.

# Confirm Marketplace image availability and licensing in the target region.
image_publisher = "MicrosoftWindowsDesktop"
image_offer     = "office-365"
image_sku       = "win11-24h2-avd-m365"
image_version   = "latest"

# Set true only when AD DS connectivity, DNS, and OU permissions are ready.
domain_join_enabled = false
# Supply these as secure TF_VAR_ environment variables if enabling domain join:
# domain_name = "corp.contoso.com"
# domain_ou_path = "OU=AVD,OU=Workstations,DC=corp,DC=contoso,DC=com"

registration_token_hours = 4
boot_diagnostics_storage_uri = null

tags = {
  Owner       = "CloudOperations"
  CostCenter  = "IT"
  Service     = "AVD"
}
