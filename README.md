# multi-cloud-k8s-infra

Provision Kubernetes clusters in **DigitalOcean (DOKS)** or **Azure (AKS)** using Terraform.  
Each provider uses its **native backend** for Terraform state.

## Prerequisites
- Terraform >= 1.6
- `kubectl`
- Cloud CLIs: `doctl` (DigitalOcean), `az` (Azure)
- Environment variables set for each provider:

### DigitalOcean
```bash
export DIGITALOCEAN_TOKEN="your_do_token"
