output "bucket_name" {
  value = digitalocean_spaces_bucket.tfstate.name
}
output "region" {
  value = var.region
}
