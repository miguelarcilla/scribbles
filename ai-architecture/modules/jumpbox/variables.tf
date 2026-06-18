variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "jumpbox_subnet_id" {
  type = string
}

variable "virtual_network_id" {
  type = string
}

variable "admin_username" {
  type    = string
  default = "badmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "license_type" {
  type    = string
  default = "Windows_Client"
}

variable "os_disk_storage_account_type" {
  type    = string
  default = "Premium_LRS"
}

variable "os_disk_size_gb" {
  type    = number
  default = 127
}

variable "image_reference" {
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
