output "resource_group_name" {
  value = var.resource_group_name
}

output "host_pool_id" {
  value = azurerm_virtual_desktop_host_pool.avd.id
}

output "workspace_id" {
  value = azurerm_virtual_desktop_workspace.avd.id
}

output "desktop_application_group_id" {
  value = azurerm_virtual_desktop_application_group.desktop.id
}

output "session_host_private_ips" {
  value = [for nic in azurerm_network_interface.session_host : nic.private_ip_address]
}

output "host_pool_registration_token" {
  value       = azurerm_virtual_desktop_host_pool_registration_info.avd.token
  sensitive   = true
  description = "Sensitive AVD registration token. Do not publish or log."
}
