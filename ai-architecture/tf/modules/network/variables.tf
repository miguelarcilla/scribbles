variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "tags" {
  type = map(string)
}
