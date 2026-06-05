variable "location" {
  description = "Azure region for all resources. Microsoft Foundry Agent Service and Container Apps must be supported in this region."
  type        = string
  default     = "eastus2"
}

variable "workload_name" {
  description = "Short workload identifier used to compose resource names (lowercase, alphanumeric)."
  type        = string
  default     = "foundryref"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.workload_name))
    error_message = "workload_name must be 3-12 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment short name (e.g. dev, test, prod)."
  type        = string
  default     = "prod"
}

variable "vnet_address_space" {
  description = "Address space for the workload virtual network. 192.168.0.0/16 is used because the Foundry Agent Service delegated subnet historically rejected the 10.0.0.0/8 range."
  type        = string
  default     = "192.168.0.0/16"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    workload = "microsoft-foundry-baseline"
    iac      = "terraform"
    purpose  = "reference-architecture"
  }
}

variable "gpt_model" {
  description = "Model deployed to Microsoft Foundry and exposed through API Management."
  type = object({
    name     = string
    version  = string
    sku_name = string
    capacity = number
  })
  default = {
    name     = "gpt-4o"
    version  = "2024-11-20"
    sku_name = "GlobalStandard"
    capacity = 50
  }
}

variable "publisher_name" {
  description = "API Management publisher name."
  type        = string
  default     = "Contoso AI Platform"
}

variable "publisher_email" {
  description = "API Management publisher email."
  type        = string
  default     = "platform-team@contoso.example"
}
