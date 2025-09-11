# multi-cloud-k8s-infra

Provision Kubernetes clusters in **DigitalOcean (DOKS)** or **Azure (AKS)** using Terraform.  
This repo is intentionally modular — each cloud module uses its **native backend** for Terraform state.

It now includes:
1. **Bootstrap modules** (DigitalOcean Spaces, Azure Blob).  
2. **GitHub Actions workflow** that:
   - Runs bootstrap automatically.
   - Provisions Kubernetes clusters.
   - Uploads kubeconfig as an artifact for Jenkins/apps.

---

# Table of contents
1. Prerequisites  
2. Repo structure  
3. Required backend bootstrap  
4. How to run locally  
5. How to pass variables  
6. GitHub Actions workflow (with artifact upload)  
7. Module variables  
8. Outputs  
9. Consuming kubeconfig  
10. Best practices  
11. Troubleshooting  
12. Next steps  

---

# 1. Prerequisites

### Local
- Terraform >= 1.6  
- `kubectl`  
- CLIs: `doctl` (DigitalOcean), `az` (Azure)  

### GitHub Actions Secrets

#### DigitalOcean
- `DIGITALOCEAN_TOKEN` (API token)  

#### Azure
- `ARM_CLIENT_ID`  
- `ARM_CLIENT_SECRET`  
- `ARM_SUBSCRIPTION_ID`  
- `ARM_TENANT_ID`  

---

# 2. Repo structure

```
multi-cloud-k8s-infra/
├─ README.md
├─ deploy.sh
├─ terraform/
│  ├─ bootstrap-digitalocean/   # Spaces bucket
│  ├─ bootstrap-azure/          # RG + Storage + Container
│  ├─ digitalocean/             # DOKS cluster
│  └─ azure/                    # AKS cluster
└─ .github/
   └─ workflows/
      └─ terraform.yml          # CI workflow
```

---

# 3. Backend bootstrap

Terraform backends must exist before use.  
This repo includes bootstrap modules to handle that:

- **DigitalOcean** → `terraform/bootstrap-digitalocean`
- **Azure** → `terraform/bootstrap-azure`

Run bootstrap once per environment.

---

# 4. How to run locally

## DigitalOcean
```bash
export DIGITALOCEAN_TOKEN="your_token"
cd terraform/bootstrap-digitalocean
terraform init && terraform apply -auto-approve
cd ../digitalocean
terraform init -backend-config="bucket=mybucket"   -backend-config="region=nyc3"   -backend-config="key=doks/terraform.tfstate"   -backend-config="endpoints.s3=https://nyc3.digitaloceanspaces.com"   -backend-config="skip_credentials_validation=true"   -backend-config="skip_metadata_api_check=true"   -backend-config="skip_region_validation=true"
terraform apply -auto-approve
```

## Azure
```bash
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
cd terraform/bootstrap-azure
terraform init && terraform apply -auto-approve
cd ../azure
terraform init -backend-config="resource_group_name=tfstate-rg"   -backend-config="storage_account_name=tfstateaccount123"   -backend-config="container_name=tfstate"   -backend-config="key=aks/terraform.tfstate"
terraform apply -auto-approve
```

---

# 5. Passing variables

- CLI: `terraform apply -var="cluster_name=test"`  
- `.tfvars` file: `terraform apply -var-file=terraform.tfvars`  
- Env vars: `export TF_VAR_cluster_name=test`  
- Providers:  
  - DigitalOcean → `DIGITALOCEAN_TOKEN`  
  - Azure → `ARM_CLIENT_ID`, etc.  

---

# 6. GitHub Actions workflow

Location: `.github/workflows/terraform.yml`  

## Trigger
- Run manually via **Actions → Run workflow**  
- Choose:  
  - `cloud`: `digitalocean` or `azure`  
  - `action`: `plan`, `apply`, or `destroy`  

## Flow
1. **Bootstrap job**  
   - Creates backend (Spaces or Azure Blob).  
   - Saves outputs to files.  

2. **Terraform job**  
   - Uses outputs in `terraform init -backend-config`.  
   - Runs `plan`, `apply`, `destroy`.  
   - After `apply`, uploads kubeconfig as an artifact.  

## Artifact
- After apply, kubeconfig is uploaded as:  
  - `kubeconfig-digitalocean`  
  - `kubeconfig-azure`  

---

# 7. Module variables

## DigitalOcean (`terraform/digitalocean/variables.tf`)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `digitalocean_token` | string | none | API token |
| `region` | string | "nyc3" | Region |
| `cluster_name` | string | "do-terraform-cluster" | Cluster name |
| `node_size` | string | "s-2vcpu-4gb" | Droplet size |
| `node_count` | number | 2 | Number of nodes |

## Azure (`terraform/azure/variables.tf`)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | string | "aks-rg" | Resource group |
| `cluster_name` | string | "aks-cluster" | Cluster name |
| `location` | string | "East US" | Region |
| `node_count` | number | 2 | Nodes |
| `node_size` | string | "Standard_DS2_v2" | VM size |

---

# 8. Outputs

- **DigitalOcean**: `terraform/digitalocean/kubeconfig`  
- **Azure**: `terraform/azure/kubeconfig`  
- GitHub Actions artifact: `kubeconfig-<cloud>`  

---

# 9. Consuming kubeconfig

From Jenkins repo workflow:

```yaml
- name: Download kubeconfig
  uses: actions/download-artifact@v4
  with:
    name: kubeconfig-digitalocean   # or kubeconfig-azure
    path: ./kubeconfig

- name: Use kubeconfig
  run: |
    export KUBECONFIG=./kubeconfig/kubeconfig
    kubectl get nodes
```
---

# 10. Best practices

- Separate **bootstrap** and **cluster** clearly.  
- Don’t hardcode backend → pass via workflow.  
- Store kubeconfig as **artifact only**, never in Git.  
- Protect `apply`/`destroy` with **GitHub Environments approvals**.  
- Rotate cloud secrets.  

---

# 11. Troubleshooting

- **NoSuchBucket** (DO): Run bootstrap first.  
- **Auth error** (Azure): Check `ARM_*` env vars.  
- **Provider mismatch**: Pin provider versions.  
- **kubeconfig missing**: Ensure `apply` ran, not just `plan`.  

---

# 12. Next steps

- Add AWS (EKS) & GCP (GKE).  
- Jenkins repo workflow: download kubeconfig, deploy Jenkins Helm.  
- ArgoCD GitOps for apps.  
- Use Terraform Cloud for state + locking.  

---
