resource "azurerm_resource_group" "default" {
  name     = var.name
  location = var.location

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
