data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "kv" {
    name                = var.key_vault_name
    resource_group_name = var.key_vault_resource_group_name
    location            = var.key_vault_resource_group_location
    tenant_id           = data.azurerm_subscription.current.tenant_id
    sku_name            = var.sku_name
}

resource "azurerm_key_vault_access_policy" "azdokvap" {
    key_vault_id = azurerm_key_vault.kv.id

    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "get", "list", "set",
    ]
}
