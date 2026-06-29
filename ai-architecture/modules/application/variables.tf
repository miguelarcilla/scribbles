variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "container_apps_subnet_id" {
  type = string
}

variable "private_endpoints_subnet_id" {
  type = string
}

variable "container_apps_environment_private_dns_zone_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "azure_openai_endpoint" {
  type = string
}

variable "azure_openai_deployment" {
  type = string
}

variable "azure_openai_api_version" {
  type    = string
  default = "2025-01-01-preview"
}

variable "container_registry_id" {
  type = string
}

variable "foundry_account_id" {
  type = string
}

variable "container_registry_login_server" {
  type = string
}

variable "app_image_name" {
  type = string
}

variable "app_image_tag" {
  type = string
}

variable "tags" {
  type = map(string)
}
