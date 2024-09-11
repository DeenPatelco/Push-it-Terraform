# Resource Group
resource "azurerm_resource_group" "dev-rg" {
#  provider = azurerm.staging
  name     = "rg-${var.environment}-${var.app_name}-${var.location}"
  location = var.location
}

# App Service Plan
resource "azurerm_service_plan" "my-plan" {
#  provider = azurerm.staging
  name                = "plan-${var.environment}-${var.app_name}-${var.location}"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  os_type             = "Windows"
  sku_name            = "P1v2"
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = "appinsights-${var.environment}-${var.app_name}-${var.location}"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name
  application_type    = "web"
}

# Windows Web App
resource "azurerm_windows_web_app" "my-webapp" {
  name                = "app-${var.environment}-${var.app_name}-${var.location}-001"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.my-plan.id
  virtual_network_subnet_id = data.azurerm_subnet.my-subnet.id

  app_settings = {
    ASPNETCORE_ENVIRONMENT = var.aspnetcore_environment
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app_insights.instrumentation_key
    WEBSITE_ENABLE_SYNC_UPDATE_SITE = "true"
    # WEBSITE_VNET_ROUTE_ALL = "1" #when working with terraform this can not be set as envrionment variable under app_settings for windows web app instead have to set it under site_block block.
  }

  site_config {
    always_on = false
    # Enable HTTP/2 support as by default this value is taken as false. Right now keeping it false only as we are using 1.1 version for HTTP in exisiting webapps.
    #http2_enabled = true

    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v8.0"
    }

    ip_restriction {
      action     = "Allow"
      priority   = 100
      name       = "AllowADOserviceTag"
      service_tag = "AzureDevOps"
    }
    # Enable routing all outbound traffic through VNet
    #vnet_route_all_enabled = true
    # Set FTP state to FTPS only
    ftps_state = "FtpsOnly"
  }
  # Enable HTTPS only as by default this value is taken as false
  https_only = true

  lifecycle {
    ignore_changes = [
      site_config[0].virtual_application
    ]
  }
}

# data block to fetch existing vnet/subnet details which we want to integrate with WebApp outbound traffic
data "azurerm_virtual_network" "existing_vnet" {
#  provider = azurerm.staging
  name                = "${var.vnet_name}"
  resource_group_name = "${var.vnet_resource_group_name}" # Vnet resource group name
}

data "azurerm_subnet" "my-subnet" {
#  provider = azurerm.staging
  name                 = "${var.subnet_name}"
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = "${var.vnet_resource_group_name}"
}

# resource "azurerm_app_service_virtual_network_swift_connection" "my-webapp-vnet-integration" {
#  app_service_id = azurerm_windows_web_app.my-webapp.id
#  subnet_id      = data.azurerm_subnet.my-subnet.id
# }

data "azurerm_cdn_frontdoor_profile" "my-frondoor" {
  provider = azurerm.connectivity
  #name                = "${var.frontdoor_name}"
  name = "afd-cnct-west-001"
  #resource_group_name = "${var.frontdoor_resource_group_name}"   # Front Door resource group name
  resource_group_name = "rg-cnct-core-west"
}

# getting subscription id
# data "azurerm_subscription" "current" {}

resource "azurerm_cdn_frontdoor_origin_group" "origin-group" {
  provider = azurerm.connectivity
  name                     = "${var.app_name}-${var.environment}-${var.location}-001"
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.my-frondoor.id

  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  provider = azurerm.connectivity
  name                          = "${var.app_name}-${var.environment}-${var.location}-001"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = "app-${var.environment}-${var.app_name}-${var.location}-001.azurewebsites.net"
  origin_host_header             = "app-${var.environment}-${var.app_name}-${var.location}-001.azurewebsites.net"
  priority                       = 1
  weight                         = 1000
  http_port                      = 80
  https_port                     = 443

  private_link {
    request_message        = "Request access for Frontdoor Private Endpoint"
    target_type            = "sites"
    location               = "westus3"
    private_link_target_id = azurerm_windows_web_app.my-webapp.id
  }
}

# Enable this when we were using existing endpoint named api in route but i have commented out all domain related things as instead of custom domain we are creating new endpoint and using that endpoint in the route instead of domain.
data "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  provider = azurerm.connectivity
  name                = "api"
  profile_name        = data.azurerm_cdn_frontdoor_profile.my-frondoor.name
  resource_group_name = "rg-cnct-core-west"
}

# Create endpoint in front door manager for having same route "/*" in all envs (dev/qa/uat/staging/prod) else was getting error that "The route domains, paths and protocols configuration has a conflict". We can not have same route (say /* for dev & qa) defined under same endpoint.
# resource "azurerm_cdn_frontdoor_endpoint" "frontdoor_endpoint" {
#   provider = azurerm.connectivity
#   name                     = "${var.app_name}-${var.environment}"
#   cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.my-frondoor.id
#   enabled = true
  
#   tags = {
#     ENV = "${var.environment}"
#   }
# }

resource "azurerm_cdn_frontdoor_route" "route" {
  provider = azurerm.connectivity
  name                          = "${var.app_name}-${var.environment}-${var.location}-001"
  # Enable below when we were passing id of existing endpoint - api
  cdn_frontdoor_endpoint_id     = data.azurerm_cdn_frontdoor_endpoint.endpoint.id
  # cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin.id]
  # cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.example.id]
  enabled                       = true

  # forwarding_protocol    = "HttpsOnly"
  forwarding_protocol         = "MatchRequest"
  https_redirect_enabled = true
  # patterns_to_match      = ["/${var.environment}/", "/${var.app_name}/*"]
  patterns_to_match      = ["/tf/${var.environment}/${var.app_name}/*"]
  # patterns_to_match      = ["/${var.environment}/${var.app_name}/*","/*"]
  supported_protocols    = ["Http", "Https"]
  # accepted_protocols          = ["Http", "Https"]

  # Enable below 2 when using custom domain
  cdn_frontdoor_custom_domain_ids = [data.azurerm_cdn_frontdoor_custom_domain.domain.id]
  link_to_default_domain          = false
}

data "azurerm_cdn_frontdoor_custom_domain" "domain" {
  provider = azurerm.connectivity
  name                = "api-patelco-org"
  profile_name        = data.azurerm_cdn_frontdoor_profile.my-frondoor.name
  resource_group_name = "rg-cnct-core-west"
}

# Enable this when using above custom domain and want to add that domain in the route
resource "azurerm_cdn_frontdoor_custom_domain_association" "domain-association" {
  provider = azurerm.connectivity
  cdn_frontdoor_custom_domain_id = data.azurerm_cdn_frontdoor_custom_domain.domain.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.route.id]
}
