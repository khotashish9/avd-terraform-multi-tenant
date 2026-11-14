locals {
  name_prefix = lower("${var.client_code}-${var.environment}")
  subnet_id   = var.create_network ? azurerm_subnet.avd[0].id : var.existing_subnet_id
  common_tags = merge(var.tags, {
    Client      = var.client_code
    Environment = var.environment
    Workload    = "AVD"
    ManagedBy   = "Terraform"
  })
}

resource "azurerm_resource_group" "avd" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_id       = var.create_resource_group ? azurerm_resource_group.avd[0].id : data.azurerm_resource_group.existing[0].id
  resource_group_location = var.create_resource_group ? azurerm_resource_group.avd[0].location : data.azurerm_resource_group.existing[0].location
}

resource "azurerm_network_security_group" "avd" {
  count               = var.create_network ? 1 : 0
  name                = "${local.name_prefix}-avd-nsg"
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "avd" {
  count               = var.create_network ? 1 : 0
  name                = var.vnet_name
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

resource "azurerm_subnet" "avd" {
  count                = var.create_network ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.avd[0].name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "avd" {
  count                     = var.create_network ? 1 : 0
  subnet_id                 = azurerm_subnet.avd[0].id
  network_security_group_id = azurerm_network_security_group.avd[0].id
}

resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                     = var.host_pool_name
  location                 = local.resource_group_location
  resource_group_name      = var.resource_group_name
  type                     = var.host_pool_type
  load_balancer_type       = var.host_pool_type == "Pooled" ? var.load_balancer_type : null
  maximum_sessions_allowed = var.host_pool_type == "Pooled" ? var.maximum_sessions_allowed : null
  validate_environment     = false
  start_vm_on_connect      = true
  tags                     = local.common_tags
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = timeadd(timestamp(), "${var.registration_token_hours}h")
  lifecycle {
    ignore_changes = [expiration_date]
  }
}

resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = var.workspace_name
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name
  friendly_name       = var.friendly_name
  description         = "Workspace for ${var.client_code} ${var.environment}"
  tags                = local.common_tags
}

resource "azurerm_virtual_desktop_application_group" "desktop" {
  name                = var.application_group_name
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd.id
  friendly_name       = var.friendly_name
  description         = var.description
  default_desktop_display_name = var.friendly_name
  tags                = local.common_tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "desktop" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.desktop.id
}

resource "azurerm_network_interface" "session_host" {
  count               = var.session_host_count
  name                = "${local.name_prefix}-avd-nic-${format("%02d", count.index + 1)}"
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.common_tags
}

resource "azurerm_windows_virtual_machine" "session_host" {
  count               = var.session_host_count
  name                = "${local.name_prefix}-avd-${format("%02d", count.index + 1)}"
  computer_name       = "${substr(replace(local.name_prefix, "-", ""), 0, 8)}-${format("%02d", count.index + 1)}"
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.session_host[count.index].id
  ]

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  os_disk {
    name                 = "${local.name_prefix}-avd-os-${format("%02d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_uri
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_virtual_machine_extension" "domain_join" {
  count                      = var.domain_join_enabled ? var.session_host_count : 0
  name                       = "joindomain"
  virtual_machine_id          = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = var.domain_ou_path
    User    = var.domain_join_username
    Restart = "true"
    Options = "3"
  })

  protected_settings = jsonencode({
    Password = var.domain_join_password
  })
}

resource "azurerm_virtual_machine_extension" "avd_agent" {
  count                      = var.session_host_count
  name                       = "AVD-Registration"
  virtual_machine_id          = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  depends_on = [
    azurerm_virtual_machine_extension.domain_join
  ]

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"$ErrorActionPreference='Stop'; $agent='https://aka.ms/avdagent'; $boot='https://aka.ms/avdbootloader'; Invoke-WebRequest -Uri $agent -OutFile $env:TEMP\\AVDAgent.msi; Invoke-WebRequest -Uri $boot -OutFile $env:TEMP\\AVDBootLoader.msi; Start-Process msiexec.exe -ArgumentList '/i', $env:TEMP\\AVDAgent.msi, '/quiet', '/norestart', 'REGISTRATIONTOKEN=${azurerm_virtual_desktop_host_pool_registration_info.avd.token}' -Wait -PassThru; Start-Process msiexec.exe -ArgumentList '/i', $env:TEMP\\AVDBootLoader.msi, '/quiet', '/norestart' -Wait; Restart-Service RDAgentBootLoader -ErrorAction SilentlyContinue\""
  })
}
