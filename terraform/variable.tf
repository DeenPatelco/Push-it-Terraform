variable "environment" {
}

variable "location" {
}

variable "app_name" {
}

variable "vnet_resource_group_name" {
}

variable "vnet_name" {
}

variable "subnet_name" {
}

variable "aspnetcore_environment" {
  description = "The ASP.NET Core environment"
  type        = string
}

#variable "app_insights_instrumentation_key" {
#  description = "The Instrumentation Key for Application Insights"
#  type        = string
#}

#variable "cdn_custom_domain_name" {
#  default = "api.patelco.org"
#}

#variable "frontdoor_name" {
#}

#variable "frontdoor_resource_group_name" {
#}
