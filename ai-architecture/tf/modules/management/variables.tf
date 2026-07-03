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

variable "jumpbox_subnet_id" {
  type = string
}

variable "virtual_network_id" {
  type = string
}

variable "jumpbox_admin_username" {
  type    = string
  default = "badmin"
}

variable "jumpbox_admin_password" {
  type      = string
  sensitive = true
}

variable "jumpbox_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "jumpbox_license_type" {
  type    = string
  default = "Windows_Client"
}

variable "jumpbox_os_disk_storage_account_type" {
  type    = string
  default = "Premium_LRS"
}

variable "jumpbox_os_disk_size_gb" {
  type    = number
  default = 127
}

variable "jumpbox_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  default = {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-11"
    sku       = "win11-25h2-ent"
    version   = "latest"
  }
}

variable "tags" {
  type = map(string)
}
