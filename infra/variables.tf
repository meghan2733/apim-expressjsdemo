variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-apim-lab"
}

variable "location" {
  type        = string
  default     = "centralus"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "Your SSH public key for VM login"
}

variable "apim_name" {
  type        = string
  default     = "apim-lab-consumption"
}

variable "vm_name" {
  type        = string
  default     = "vm-apim-lab"
}