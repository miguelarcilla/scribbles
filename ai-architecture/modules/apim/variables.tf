variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "apim_subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "app_insights_id" {
  type = string
}

variable "app_insights_instrumentation_key" {
  type      = string
  sensitive = true
}

variable "publisher_name" {
  type = string
}

variable "publisher_email" {
  type = string
}

variable "foundry_account_id" {
  type = string
}

variable "foundry_inference_endpoint" {
  type = string
}

variable "tags" {
  type = map(string)
}
