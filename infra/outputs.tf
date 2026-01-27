output "vm_public_ip" {
  value       = azurerm_public_ip.vm_pip.ip_address
  description = "Public IP of the backend VM"
}

output "apim_gateway_url" {
  value       = azurerm_api_management.apim.gateway_url
  description = "APIM gateway base URL"
}

output "apim_subscription_key" {
  value       = azurerm_api_management_subscription.subscription.primary_key
  sensitive   = true
  description = "Primary subscription key for the product"
}