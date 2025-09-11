# multi-cloud-k8s-infra

Provision Kubernetes clusters in **DigitalOcean (DOKS)** or **Azure (AKS)** using Terraform.  
This repo is modular — each cloud has its own bootstrap and cluster modules.  
Terraform state is stored in **DigitalOcean Spaces** (S3-compatible) or **Azure Blob**.  
Outputs are passed between jobs using **artifacts** (GitHub Actions best practice).

---

# Table of contents
1. Prerequisites  
2. Repo structure  
3. Required secrets  
4. How it works (artifact flow)  
5. Local usage  
6. Workflow usage  
7. Variables  
8. Outputs  
9. Consuming kubeconfig  
10. Best practices  
11. Troubleshooting  
12. Next steps  

---

# 1. Prerequisites

- Terraform >= 1.6  
- `kubectl`  
- Cloud CLIs (`doctl`, `az`) — optional but useful for testing  
- GitHub Actions enabled on repo  

---

# 2. Repo structure

```
multi-cloud-k8s-infra/
├─ README.md
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

# 3. Required secrets

Add these under **GitHub → Repo → Settings → Secrets and variables → Actions**.

### DigitalOcean
- `DIGITALOCEAN_TOKEN` → API token (used for Kubernetes cluster creation)  
- `DO_SPACES_KEY` → Spaces Access Key  
- `DO_SPACES_SECRET` → Spaces Secret Key  

### Azure
- `ARM_CLIENT_ID`  
- `ARM_CLIENT_SECRET`  
- `ARM_SUBSCRIPTION_ID`  
- `ARM_TENANT_ID`  

---

# 4. How it works (artifact flow)

1. **Bootstrap job**  
   - Creates backend storage (Spaces bucket or Azure Blob container).  
   - Saves outputs into files (e.g., `do-bucket.txt`, `do-region.txt`).  
   - Uploads them as artifacts (`do-bootstrap-outputs`, `azure-bootstrap-outputs`).  

2. **Cluster job**  
   - Downloads artifacts from bootstrap.  
   - Uses them in `terraform init -backend-config`.  
   - Provisions the Kubernetes cluster.  
   - Saves kubeconfig.  

3. **Artifact upload**  
   - After cluster creation, kubeconfig is uploaded as a GitHub artifact.  
   - Jenkins repo (or others) can download and use it.  

---

# 5. Local usage

## DigitalOcean
```bash
export TF_VAR_digitalocean_token="your_DO_api_token"
export TF_VAR_spaces_access_key="your_spaces_access_key"
export TF_VAR_spaces_secret_key="your_spaces_secret_key"
export TF_VAR_spaces_bucket_name="do-tfstate-local"
export TF_VAR_region="nyc3"

cd terraform/bootstrap-digitalocean
terraform init && terraform apply -auto-approve

cd ../digitalocean
terraform init   -backend-config="bucket=do-tfstate-local"   -backend-config="key=doks/terraform.tfstate"   -backend-config="region=us-east-1"   -backend-config="endpoints.s3=https://nyc3.digitaloceanspaces.com"   -backend-config="skip_credentials_validation=true"   -backend-config="skip_metadata_api_check=true"   -backend-config="skip_region_validation=true"

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
terraform init   -backend-config="resource_group_name=tfstate-rg"   -backend-config="storage_account_name=tfstateaccount123"   -backend-config="container_name=tfstate"   -backend-config="key=aks/terraform.tfstate"

terraform apply -auto-approve
```

---

# 6. Workflow usage (with artifacts)

The GitHub Actions workflow (`.github/workflows/terraform.yml`) has two jobs:

- **`bootstrap`**:  
  - Creates backend storage.  
  - Saves outputs to files.  
  - Uploads outputs as artifacts (`do-bootstrap-outputs`, `azure-bootstrap-outputs`).  

- **`terraform`**:  
  - Downloads artifacts.  
  - Runs `terraform init` with backend configs.  
  - Provisions the Kubernetes cluster.  
  - Uploads kubeconfig as artifact.  

### Example Flow (DigitalOcean)

1. Bootstrap job saves outputs:
   ```
   do-bucket.txt  → bucket name
   do-region.txt  → region
   ```

   Uploaded as artifact: `do-bootstrap-outputs`.

2. Cluster job downloads the artifact, then runs:

   ```bash
   terraform init -input=false      -backend-config="bucket=$(cat ./bootstrap-outputs/do-bucket.txt)"      -backend-config="key=doks/terraform.tfstate"      -backend-config="region=us-east-1"      -backend-config="endpoints.s3=https://$(cat ./bootstrap-outputs/do-region.txt).digitaloceanspaces.com"      -backend-config="skip_credentials_validation=true"      -backend-config="skip_metadata_api_check=true"      -backend-config="skip_region_validation=true"
   ```

3. After cluster creation, kubeconfig is uploaded as artifact:  
   - `kubeconfig-digitalocean`  
   - `kubeconfig-azure`  

---

# 7. Variables

## DigitalOcean
- `digitalocean_token` → API token  
- `spaces_access_key` / `spaces_secret_key` → Spaces credentials  
- `spaces_bucket_name` → bucket name  
- `region` → DO region (default: `nyc3`)  
- `cluster_name` → cluster name  
- `node_size` → droplet size  
- `node_count` → number of nodes  

## Azure
- `resource_group_name` → resource group  
- `storage_account_name` → storage account  
- `container_name` → blob container  
- `cluster_name` → cluster name  
- `location` → region  
- `node_count` → node count  
- `node_size` → VM size  

---

# 8. Outputs

- `bucket_name` (bootstrap)  
- `region` (bootstrap)  
- `kubeconfig_path` (cluster)  
- GitHub artifact: `kubeconfig-digitalocean` or `kubeconfig-azure`  

---

# 9. Consuming kubeconfig

From another repo/workflow (e.g., Jenkins deployment):

```yaml
- name: Download kubeconfig
  uses: actions/download-artifact@v4
  with:
    name: kubeconfig-digitalocean
    path: ./kubeconfig

- name: Use kubeconfig
  run: |
    export KUBECONFIG=./kubeconfig/kubeconfig
    kubectl get nodes
```

---

# 10. Best practices

- Use **artifacts** instead of relative paths to pass outputs.  
- Never hardcode secrets → always use GitHub secrets.  
- Always set `region=us-east-1` for S3 backend.  
- Restrict API token scope to minimum required.  
- Protect `apply`/`destroy` with environment approvals in GitHub.  

---

# 11. Troubleshooting

- **Spaces credentials not configured** → ensure `DO_SPACES_KEY` and `DO_SPACES_SECRET` are set.  
- **Invalid AWS Region** → backend config must always use `region=us-east-1`.  
- **Missing outputs** → bootstrap job must run successfully before cluster job.  
- **ACL deprecation warnings** → fixed using `aws_s3_bucket_acl`.  

---

# 12. Next steps

- Add AWS (EKS) and GCP (GKE).  
- Jenkins repo workflow to auto-deploy Jenkins Helm after kubeconfig artifact download.  
- ArgoCD for GitOps-style application delivery.  
- Terraform Cloud for remote state + locking.  

---
