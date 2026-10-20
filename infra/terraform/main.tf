locals {
  resource_group_name = "rg-ascendant-prd"
  static_web_app_name = "swa-ascendant-prd-${var.name_suffix}"
  tags = {
    project     = "ascendant"
    environment = "prod"
    managed-by  = "terraform"
  }
}

resource "azurerm_resource_group" "prd" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_static_web_app" "prd" {
  name                               = local.static_web_app_name
  resource_group_name                = azurerm_resource_group.prd.name
  location                           = azurerm_resource_group.prd.location
  sku_tier                           = "Free"
  sku_size                           = "Free"
  preview_environments_enabled       = false
  configuration_file_changes_enabled = true
  public_network_access_enabled      = true
  tags                               = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      repository_branch,
      repository_url,
    ]
  }
}
