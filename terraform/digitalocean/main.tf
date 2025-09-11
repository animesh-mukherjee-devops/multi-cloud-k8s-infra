resource "digitalocean_kubernetes_cluster" "k8s" {
  name    = var.cluster_name
  region  = var.region
  version = "latest"

  node_pool {
    name       = "${var.cluster_name}-pool"
    size       = var.node_size
    node_count = var.node_count
    auto_scale = false
  }
}

resource "local_file" "kubeconfig" {
  content        = digitalocean_kubernetes_cluster.k8s.kube_config[0].raw_config
  filename       = "${path.module}/kubeconfig"
  file_permission = "0600"
}

output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.k8s.name
}
