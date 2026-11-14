variable "subscription_id" {
  description = "Customer Azure subscription ID."
  type        = string
}

variable "client_code" {
  description = "Short customer identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name, e.g. prod, test, dev."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name. Created when create_resource_group is true."
  type        = string
}

variable "create_resource_group" {
  description = "Whether this configuration creates the resource group."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
}

variable "vnet_name" {
  type        = string
  description = "VNet name. Used only when create_network is true."
  default     = "vnet-avd"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space."
  default     = ["10.50.0.0/16"]
}

variable "subnet_name" {
  type        = string
  description = "Session host subnet name."
  default     = "snet-avd-sessionhosts"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Session host subnet prefixes."
  default     = ["10.50.10.0/24"]
}

variable "create_network" {
  type        = bool
  description = "Create a VNet, subnet, and NSG. If false, provide existing_subnet_id."
  default     = true
}

variable "existing_subnet_id" {
  type        = string
  description = "Existing subnet resource ID when create_network is false."
  default     = null
}

variable "host_pool_name" {
  type        = string
  description = "AVD host pool name."
}

variable "workspace_name" {
  type        = string
  description = "AVD workspace name."
}

variable "application_group_name" {
  type        = string
  description = "AVD desktop application group name."
}

variable "host_pool_type" {
  type        = string
  description = "Pooled or Personal."
  default     = "Pooled"
  validation {
    condition     = contains(["Pooled", "Personal"], var.host_pool_type)
    error_message = "host_pool_type must be Pooled or Personal."
  }
}

variable "load_balancer_type" {
  type        = string
  description = "BreadthFirst or DepthFirst for pooled host pools."
  default     = "BreadthFirst"
}

variable "maximum_sessions_allowed" {
  type        = number
  description = "Maximum sessions per session host for pooled host pools."
  default     = 10
}

variable "friendly_name" {
  type        = string
  description = "Friendly name shown to users."
  default     = "Customer Desktop"
}

variable "description" {
  type        = string
  description = "Desktop application group description."
  default     = "Customer AVD desktop application group"
}

variable "session_host_count" {
  type        = number
  description = "Number of Windows session host VMs."
  default     = 2
  validation {
    condition     = var.session_host_count >= 1 && var.session_host_count <= 50
    error_message = "session_host_count must be between 1 and 50."
  }
}

variable "vm_size" {
  type        = string
  description = "Azure VM size for session hosts."
  default     = "Standard_D4s_v5"
}

variable "admin_username" {
  type        = string
  description = "Local Windows administrator username."
  default     = "avdlocaladmin"
}

variable "admin_password" {
  type        = string
  description = "Local Windows administrator password. Supply securely."
  sensitive   = true
}

variable "image_publisher" {
  type        = string
  default     = "MicrosoftWindowsDesktop"
  description = "Marketplace image publisher."
}

variable "image_offer" {
  type        = string
  default     = "office-365"
  description = "Marketplace image offer. Verify availability and licensing in the target region."
}

variable "image_sku" {
  type        = string
  default     = "win11-24h2-avd-m365"
  description = "Marketplace image SKU. Verify availability and licensing in the target region."
}

variable "image_version" {
  type        = string
  default     = "latest"
  description = "Marketplace image version."
}

variable "domain_join_enabled" {
  type        = bool
  description = "Enable traditional AD DS domain join extension."
  default     = false
}

variable "domain_name" {
  type        = string
  description = "AD DS domain DNS name."
  default     = null
}

variable "domain_ou_path" {
  type        = string
  description = "Optional distinguished name of target OU."
  default     = null
}

variable "domain_join_username" {
  type        = string
  description = "AD DS join account username. Supply securely."
  default     = null
  sensitive   = true
}

variable "domain_join_password" {
  type        = string
  description = "AD DS join account password. Supply securely."
  default     = null
  sensitive   = true
}

variable "registration_token_hours" {
  type        = number
  description = "AVD host pool registration token lifetime in hours."
  default     = 4
  validation {
    condition     = var.registration_token_hours >= 1 && var.registration_token_hours <= 720
    error_message = "registration_token_hours must be between 1 and 720."
  }
}

variable "boot_diagnostics_storage_uri" {
  type        = string
  description = "Optional storage account blob endpoint for boot diagnostics; null uses managed storage."
  default     = null
}
