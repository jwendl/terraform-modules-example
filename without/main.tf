data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.resource_group_location
}

resource "azurerm_user_assigned_identity" "api_identity" {
    name                = "api-identity"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
}

resource "azurerm_key_vault" "kv" {
    name                = var.key_vault_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
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

resource "azurerm_log_analytics_workspace" "monitor" {
    name                = var.monitor_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "ci" {
    solution_name         = "ContainerInsights"
    resource_group_name   = azurerm_resource_group.rg.name
    location              = azurerm_log_analytics_workspace.monitor.location
    workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
    workspace_name        = azurerm_log_analytics_workspace.monitor.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_application_insights" "ai" {
    name                  = var.azurerm_application_insights_name
    resource_group_name   = azurerm_resource_group.rg.name
    location              = azurerm_log_analytics_workspace.monitor.location
    application_type      = "web"
}

resource "azurerm_key_vault_secret" "akvsai" {
    name         = "ai-key"
    value        = azurerm_application_insights.ai.instrumentation_key
    key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_storage_account" "storage" {
    name                     = var.functions_storage_account_name
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
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
    resource_group_name        = azurerm_resource_group.rg.name
    location                   = azurerm_resource_group.rg.location
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
    key_vault_id = azurerm_key_vault.kv.id

    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "get", "list", "set",
    ]
}

resource "azurerm_key_vault_access_policy" "sikvap" {
    key_vault_id = azurerm_key_vault.kv.id

    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "get", "list", "set",
    ]
}

resource "random_password" "admin_password" {
    length = 16
    special = true
    override_special = "_%@"
}

resource "azurerm_key_vault_secret" "akvs" {
    name         = "sql-admin-password"
    value        = random_password.admin_password.result
    key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_sql_server" "sql_server" {
    name                         = var.sql_server_name
    resource_group_name          = azurerm_resource_group.rg.name
    location                     = azurerm_resource_group.rg.location
    version                      = "12.0"
    administrator_login          = "sqladmin"
    administrator_login_password = azurerm_key_vault_secret.akvs.value
}

resource "azurerm_sql_firewall_rule" "sql_server_rule" {
    name                = "AllowAllRule"
    resource_group_name = azurerm_sql_server.sql_server.resource_group_name
    server_name         = azurerm_sql_server.sql_server.name
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "255.255.255.255"
}

resource "azurerm_sql_database" "sql_database" {
    name                             = var.sql_database_name
    resource_group_name              = azurerm_sql_server.sql_server.resource_group_name
    location                         = azurerm_sql_server.sql_server.location
    server_name                      = azurerm_sql_server.sql_server.name
    edition                          = "BusinessCritical"
    read_scale                       = true
    requested_service_objective_name = "BC_Gen5_8"
    max_size_bytes                   = 34359738368
}

resource "azurerm_sql_active_directory_administrator" "sql_database_administrator" {
    server_name         = azurerm_sql_server.sql_server.name
    resource_group_name = azurerm_sql_server.sql_server.resource_group_name
    login               = "sqladmin"
    tenant_id           = data.azurerm_subscription.current.tenant_id
    object_id           = data.azurerm_client_config.current.object_id
}
