variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "random_suffix" {
  type = string
}

variable "private_endpoints_subnet_id" {
  type = string
}

variable "agents_egress_subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "gpt_model" {
  type = object({
    name     = string
    version  = string
    sku_name = string
    capacity = number
  })
}

variable "storage_account_id" {
  type = string
}

variable "cosmosdb_account_id" {
  type = string
}

variable "private_dns_zone_ids" {
  type = object({
    cognitiveservices = string
    openai            = string
    aiservices        = string
    search            = string
  })
}

variable "tags" {
  type = map(string)
}
