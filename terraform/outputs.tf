output "frontdoor_url" {
  value = "https://api.patelco.org/tf/${var.environment}/${var.app_name}/"
}

output "resource_group_name" {
  value = azurerm_resource_group.dev-rg.name
}

output "webapp_name" {
  value = azurerm_windows_web_app.my-webapp.name
}

output "webapp_hostname" {
  value = azurerm_windows_web_app.my-webapp.default_hostname
}

#output "envrionment_variables" {
#  value = azurerm_windows_web_app.my-webapp.app_settings
#  sensitive = true
#}

output "application_insights_name" {
  value = azurerm_application_insights.app_insights.name
}

#output "frontdoor_endpoint_host_name" {
#  value = azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint.host_name
#  description = "The host name of the CDN Front Door endpoint."
#}

#output "webapp_location" {
#  value = azurerm_windows_web_app.my-webapp.location
#}

#output "dotnet_runtime_stack" {
#  value = azurerm_windows_web_app.my-webapp.site_config[0].application_stack[0].current_stack
#}

#output "app_service_plan_name" {
#  value = azurerm_service_plan.my-plan.name
#}

#output "environment_variables" {
  #value = azurerm_app_service.example.app_settings  # Example for app settings/environment variables
#}

# output "subscription_id" {
#  value = data.azurerm_subscription.current.id
#}
