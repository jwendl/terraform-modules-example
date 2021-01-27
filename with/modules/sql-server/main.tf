data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

resource "random_password" "admin_password" {
    length = 16
    special = true
    override_special = "_%@"
}

resource "azurerm_key_vault_secret" "akvs" {
    name         = "sql-admin-password"
    value        = random_password.admin_password.result
    key_vault_id = var.key_vault_id
}

resource "azurerm_sql_server" "sql_server" {
    name                         = var.sql_server_name
    resource_group_name          = var.sql_server_resource_group_name
    location                     = var.sql_server_resource_group_location
    version                      = "12.0"
    administrator_login          = var.sql_server_administrator_login
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
