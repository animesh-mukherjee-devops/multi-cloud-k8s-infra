output "kubeconfig_path" {
  description = "Path to generated kubeconfig"
  value       = local_file.kubeconfig.filename
}

output "cluster_name" {
  description = "Cluster name"
  value       = digitalocean_kubernetes_cluster.k8s.name
}
