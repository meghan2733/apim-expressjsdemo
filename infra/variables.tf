variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default = "0f9f2aca-05a3-4370-b73c-34b635bcdd38"
}

variable "tenant_id" {
    type        = string
    description = "Azure tenant ID"
    default     = "16e6d655-18b0-4820-920d-9fc2481cfd5a"
  
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
  default     = "apim-lab-developer"
}

variable "vm_name" {
  type        = string
  default     = "vm-apim-lab"
}