data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

resource "azurerm_user_assigned_identity" "api_identity" {
    name                = "api-identity"
    resource_group_name = var.functions_resource_group_name
    location            = var.functions_resource_group_location
}

resource "azurerm_storage_account" "storage" {
    name                     = var.functions_storage_account_name
    resource_group_name      = var.functions_resource_group_name
    location                 = var.functions_resource_group_location
    account_tier             = "Standard"
    account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "app_plan" {
    name                         = var.functions_app_plan_name
    resource_group_name          = azurerm_storage_account.storage.resource_group_name
    location                     = azurerm_storage_account.storage.location
    kind                         = "elastic"
    maximum_elastic_worker_count = 4

    sku {
        tier = "ElasticPremium"
        size = "EP2"
    }
}

resource "azurerm_function_app" "functions_app" {
    name                       = var.functions_app_name
    resource_group_name        = azurerm_storage_account.storage.resource_group_name
    location                   = azurerm_storage_account.storage.location
    app_service_plan_id        = azurerm_app_service_plan.app_plan.id
    storage_account_name       = azurerm_storage_account.storage.name
    storage_account_access_key = azurerm_storage_account.storage.primary_access_key
    version                    = "~3"
    app_settings = {
        APPINSIGHTS_INSTRUMENTATIONKEY    = "@Microsoft.KeyVault(SecretUri=https://${var.key_vault_name}.vault.azure.net/secrets/ai-key/)"
        FUNCTIONS_WORKER_RUNTIME          = "dotnet"
        WEBSITE_RUN_FROM_PACKAGE          = "1"
        DatabaseOptions__ConnectionString = "@Microsoft.KeyVault(SecretUri=https://${var.key_vault_name}.vault.azure.net/secrets/sql-admin-password/)"
        StorageOptions__ConnectionString  = azurerm_storage_account.storage.primary_connection_string
    }

    identity {
        identity_ids = [
            azurerm_user_assigned_identity.api_identity.id
        ]
        type = "SystemAssigned, UserAssigned"
    }

    site_config {
        pre_warmed_instance_count = 5
        cors {
            allowed_origins = [
                "http://localhost:3000",
            ]
        }
    }

    lifecycle {
        ignore_changes = [
            app_settings["WEBSITE_RUN_FROM_PACKAGE"]
        ]
    }
}

resource "azurerm_key_vault_access_policy" "umikvap" {
    key_vault_id = var.key_vault_id

    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "get", "list", "set",
    ]
}

resource "azurerm_key_vault_access_policy" "sikvap" {
    key_vault_id = var.key_vault_id

    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "get", "list", "set",
    ]
}
