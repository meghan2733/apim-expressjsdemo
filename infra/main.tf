terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
  }
}

provider "azurerm" {
  features        {}
  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-apim-lab"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet for backend VM
resource "azurerm_subnet" "snet_backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Public IP for VM
resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-${var.vm_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

# Network Security Group for VM
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "nsg-${var.vm_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NIC for VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-${var.vm_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.snet_backend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Get cloud-init file
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml")
}

# Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  computer_name = var.vm_name
  custom_data   = base64encode(data.template_file.cloud_init.rendered)
}

# APIM (Consumption tier)
resource "azurerm_api_management" "apim" {
  name                = var.apim_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Meghan Kulkarni"
  publisher_email     = "meghan.kulkarni@outlook.com"

  sku_name = "Consumption_0"
}

# Backend API in APIM
resource "azurerm_api_management_api" "backend_api" {
  name                = "backend-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Backend API"
  path                = "backend"
  protocols           = ["https"]

  # Backend URL: Nginx on VM public IP
  service_url = "http://${azurerm_public_ip.vm_pip.ip_address}/api"
}

# Operation calling GET /api/hello on Nginx
resource "azurerm_api_management_api_operation" "hello_operation" {
  operation_id        = "hello"
  api_name            = azurerm_api_management_api.backend_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Hello"
  method              = "GET"
  url_template        = "/hello"
  description         = "Calls backend /hello via Nginx"

  response {
    status_code      = 200
    description = "Successful response"
  }
}

# Product requiring subscription
resource "azurerm_api_management_product" "product" {
  product_id          = "starter"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  display_name          = "Starter Product"
  description           = "Starter product requiring subscription"
  subscription_required = true
  approval_required     = false
  published             = true
}

# Link API to Product
resource "azurerm_api_management_product_api" "product_api" {
  api_name            = azurerm_api_management_api.backend_api.name
  product_id          = azurerm_api_management_product.product.product_id
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
}

# User for subscription
resource "azurerm_api_management_user" "subscription_user" {
  user_id             = "meghan-kulkarni"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  first_name          = "Meghan"
  last_name           = "Kulkarni"
  email               = "meghan.kulkarni@outlook.com"
}

# Subscription
resource "azurerm_api_management_subscription" "subscription" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  display_name = "Meghan's Subscription"
  state        = "active"
  user_id      = azurerm_api_management_user.subscription_user.id
  product_id   = azurerm_api_management_product.product.product_id
}