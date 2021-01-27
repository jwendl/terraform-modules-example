variable "resource_prefix" {
    description = "The resource prefix"
}

variable "resource_postfix" {
    description = "The resource postfix"
}

variable "resource_group_name" {
    description = "The resource group name"
}

variable "resource_group_location" {
    description = "The resource group location"
}

variable "monitor_name" {
    description = "The monitor instance name"
}

variable "azurerm_application_insights_name" {
    description = "The azurerm application insights resource name"
}

variable "functions_storage_account_name" {
    description = "The functions app storage account name"
}

variable "functions_app_plan_name" {
    description = "The functions application service plan name"
}

variable "functions_app_name" {
    description = "The functions application name"
}

variable "key_vault_name" {
    description = "The key vault name."
}

variable "sku_name" {
    default     = "standard"
    description = "The SKU for Key Vault. Acceptable values are: standard, premium."
}

variable "sql_server_name" {
    description = "The SQL Server Name"
}

variable "sql_database_name" {
    description = "The SQL Database name"
}
