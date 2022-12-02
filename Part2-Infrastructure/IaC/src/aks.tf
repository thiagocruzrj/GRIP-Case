################################################
# AKS Cluster
################################################

data "azuread_group" "aks_azuread_group" {
  display_name = var.aks_management_group
}

resource "kubernetes_namespace" "aks_grip_namespace" {
  metadata {
    name = "grip"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_suffix}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                              = "aks-${local.resource_suffix}"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  dns_prefix                        = "k8s-${local.resource_suffix}"
  node_resource_group               = "${azurerm_resource_group.rg.name}-aks-nodes"
  role_based_access_control_enabled = true
  azure_policy_enabled              = true
  default_node_pool {
    name       = "appnodepool"
    node_count = var.aks_app_node_pool.node_count
    vm_size    = var.aks_app_node_pool.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed = true
    admin_group_object_ids = [
      data.azuread_group.aks_azuread_group.id
    ]
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_log_analytics_workspace.id
  }
}

# Static IP

resource "azurerm_public_ip" "pip_aks" {
  name                = "pip-aks-${local.resource_suffix}"
  resource_group_name = "${azurerm_resource_group.rg.name}-aks-nodes"
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on = [azurerm_kubernetes_cluster.aks]
  ip_tags = {}
  tags    = {}
  zones = ["1", "2", "3",]
}

# Log Analytics for AKS

resource "azurerm_log_analytics_workspace" "aks_log_analytics_workspace" {
  name                = "log-aks-${local.resource_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.log_analytics_workspace_sku

  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

resource "azurerm_log_analytics_solution" "aks_container_insights" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.aks_log_analytics_workspace.location
  resource_group_name   = azurerm_log_analytics_workspace.aks_log_analytics_workspace.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.aks_log_analytics_workspace.id
  workspace_name        = azurerm_log_analytics_workspace.aks_log_analytics_workspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Ingress Controller & Cert Manager

resource "helm_release" "aks_nginx_ingress" {
  name             = "nginx-ingress-controller"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = var.ingress_version
  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.pip_aks.ip_address
  }
}

resource "helm_release" "aks_cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.5.3"

  set {
    name  = "installCRDs"
    value = true
  }
}

resource "helm_release" "helm_infrastructure" {
  name             = "gripinf"
  chart            = "../Helm"
  namespace        = "grip"
  create_namespace = true

  set {
    name  = "hostname"
    value = "kubes-${var.environment}.grip.io"
  }
}

resource "kubernetes_secret" "acr_secrets" {
  metadata {
    name      = "acr-secrets"
    namespace = "grip"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" : {
        "grip.azurecr.io" : {
          username = "fc98adab-023c-4d5e-aff5-0ed50c229384"
          password = "fKg9YMg-qkP~xKqM9Wxv3cK9G.ciV.Uw~~"
          auth     = base64encode("fc98adab-023c-4d5e-aff5-0ed50c229384:fKg9YMg-qkP~xKqM9Wxv3cK9G.ciV.Uw~~")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}
