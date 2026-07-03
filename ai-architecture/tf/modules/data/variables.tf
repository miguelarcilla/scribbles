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

variable "log_analytics_workspace_id" {
  type = string
}

variable "private_dns_zone_ids" {
  type = object({
    blob       = string
    cosmos_sql = string
  })
}

variable "tags" {
  type = map(string)
}
