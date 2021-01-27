data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

module "resource_group" {
    source                  = "./modules/resource-group"
    resource_group_name     = var.resource_group_name
    resource_group_location = var.resource_group_location
}

module "key_vault" {
    source                            = "./modules/key-vault"
    key_vault_name                    = "${var.resource_prefix}akv${var.resource_postfix}"
    key_vault_resource_group_name     = module.resource_group.resource_group_name
    key_vault_resource_group_location = module.resource_group.resource_group_location
    key_vault_tenant_id               = data.azurerm_client_config.current.tenant_id
    pipeline_principal_object_id      = data.azurerm_client_config.current.object_id
}

module "sql_server" {
    source                             = "./modules/sql-server"
    key_vault_id                       = module.key_vault.key_vault_id
    sql_server_name                    = "${var.resource_prefix}sql${var.resource_postfix}"
    sql_server_resource_group_name     = module.resource_group.resource_group_name
    sql_server_resource_group_location = module.resource_group.resource_group_location
    sql_server_administrator_login     = "jwendl"
    sql_database_name                  = "OrdersDatabase"
    admin_tenant_id                    = data.azurerm_client_config.current.tenant_id
    admin_object_id                    = data.azurerm_client_config.current.object_id
}

module "functions" {
    source = "./modules/functions"
    key_vault_id                      = module.key_vault.key_vault_id
    key_vault_name                    = module.key_vault.name
    functions_resource_group_name     = module.resource_group.resource_group_name
    functions_resource_group_location = module.resource_group.resource_group_location
    functions_storage_account_name    = "${var.resource_prefix}fst${var.resource_postfix}"
    functions_app_plan_name           = "${var.resource_prefix}aap${var.resource_postfix}"
    functions_app_name                = "${var.resource_prefix}afn${var.resource_postfix}"
}

module "azure_monitor" {
    source                            = "./modules/azure-monitor"
    monitor_name                      = "${var.resource_prefix}amo${var.resource_postfix}"
    azurerm_application_insights_name = "${var.resource_prefix}aai${var.resource_postfix}"
    mon_resource_group_name           = module.resource_group.resource_group_name
    mon_resource_group_location       = module.resource_group.resource_group_location
    key_vault_id                      = module.key_vault.key_vault_id
}
