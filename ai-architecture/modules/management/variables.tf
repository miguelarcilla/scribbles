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

variable "tenant_id" {
  type = string
}

variable "private_endpoints_subnet_id" {
  type = string
}

variable "keyvault_dns_zone_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
