output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.k8s.name
}
