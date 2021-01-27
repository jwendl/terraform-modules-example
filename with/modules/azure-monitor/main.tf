resource "azurerm_log_analytics_workspace" "monitor" {
    name                = var.monitor_name
    resource_group_name = var.mon_resource_group_name
    location            = var.mon_resource_group_location
    sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "ci" {
    solution_name         = "ContainerInsights"
    resource_group_name   = azurerm_log_analytics_workspace.monitor.resource_group_name
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
    resource_group_name   = azurerm_log_analytics_workspace.monitor.resource_group_name
    location              = azurerm_log_analytics_workspace.monitor.location
    application_type      = "web"
}

resource "azurerm_key_vault_secret" "akvsai" {
    name         = "ai-key"
    value        = azurerm_application_insights.ai.instrumentation_key
    key_vault_id = var.key_vault_id
}
