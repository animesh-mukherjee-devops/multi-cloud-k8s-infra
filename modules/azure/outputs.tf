output "kubeconfig_path" {
  description = "Path to generated kubeconfig"
  value       = local_file.kubeconfig.filename
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}
