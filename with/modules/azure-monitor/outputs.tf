output "log_analytics_workspace_id" {
    value = azurerm_log_analytics_workspace.monitor.id
}

output "app_insights_resource_id" {
    value = azurerm_application_insights.ai.id
}

output "app_insights_instance_name" {
    value = azurerm_application_insights.ai.name
}
