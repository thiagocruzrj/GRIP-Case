variable "aks_management_group" {
  default = "Grip - Developers"
}

variable "location" {
  default     = "eastus"
  description = "Azure location to use"
}

variable "aks_app_node_pool" {
  default = {
    node_count = 3
    vm_size    = "Standard_D2as_v4"
  }
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable "log_analytics_workspace_sku" {
  description = "The pricing SKU of the Log Analytics workspace."
  default     = "PerGB2018"
}

variable "ingress_version" {
  default = "4.0.19"
}