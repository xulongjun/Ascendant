output "resource_group_name" {
  value = azurerm_resource_group.prd.name
}

output "static_web_app_name" {
  value = azurerm_static_web_app.prd.name
}

output "default_host_name" {
  value = azurerm_static_web_app.prd.default_host_name
}

output "static_web_app_api_key" {
  value     = azurerm_static_web_app.prd.api_key
  sensitive = true
}
