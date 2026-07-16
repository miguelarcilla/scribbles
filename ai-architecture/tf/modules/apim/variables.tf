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

variable "apim_sku_name" {
  type        = string
  description = "SKU name for API Management. Use 'Developer_1' for dev/test (no SLA, no zones). For production, use 'Premium_1' or higher and enable availability zones."
  default     = "Developer_1"

  validation {
    condition     = can(regex("^(Developer|Basic|StandardV2|Premium)_[0-9]+$", var.apim_sku_name))
    error_message = "apim_sku_name must be a valid APIM SKU like 'Developer_1', 'BasicV2_1', 'StandardV2_1', or 'Premium_1'."
  }
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

variable "foundry_api_version" {
  type        = string
  default     = "2024-08-01-preview"
  description = "Azure OpenAI API version to expose through APIM"
}

variable "tags" {
  type = map(string)
}
