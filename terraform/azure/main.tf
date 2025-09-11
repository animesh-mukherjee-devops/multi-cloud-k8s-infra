resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksdns"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_size
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "local_file" "kubeconfig" {
  content         = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}
output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
