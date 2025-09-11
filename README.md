# multi-cloud-k8s-infra

Provision Kubernetes clusters in **DigitalOcean (DOKS)** or **Azure (AKS)** using Terraform.  
This repo now includes **bootstrap modules** for both clouds and a **GitHub Actions workflow** that:

1. Bootstraps backend storage (Spaces bucket or Azure Storage).  
2. Provisions the Kubernetes cluster.  
3. Uploads the generated `kubeconfig` as a GitHub Actions artifact (for Jenkins or other apps).  

---

## Quick summary
- Run `./deploy.sh` locally or trigger the **GitHub Actions workflow**.  
- Select `digitalocean` or `azure`.  
- Backend bucket/container is created automatically.  
- Cluster is provisioned and `kubeconfig` is available as a workflow artifact.  

---

# 1. Prerequisites

### Local
- Terraform >= 1.6  
- `kubectl`  
- Cloud CLIs: `doctl` (DigitalOcean), `az` (Azure)  

### GitHub Actions Secrets

#### DigitalOcean
- `DIGITALOCEAN_TOKEN` → API token  
- `DO_SPACES_KEY` and `DO_SPACES_SECRET` (if using raw S3 API instead of Terraform bootstrap)  

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
│  ├─ bootstrap-digitalocean/   # creates Spaces bucket
│  ├─ bootstrap-azure/          # creates RG + Storage + Container
│  ├─ digitalocean/             # provisions DOKS cluster
│  └─ azure/                    # provisions AKS cluster
└─ .github/
   └─ workflows/
      └─ terraform.yml          # workflow automation
```

---

# 3. GitHub Actions workflow

## Trigger
- Go to **Actions → Terraform Multi-Cloud → Run workflow**.  
- Choose:
  - `cloud`: `digitalocean` or `azure`
  - `action`: `plan`, `apply`, or `destroy`

## Flow
1. **Bootstrap job**  
   - DO: Creates Spaces bucket (S3 backend).  
   - Azure: Creates Resource Group, Storage Account, Container.  
   - Saves outputs to files.  

2. **Terraform job**  
   - Uses bootstrap outputs to configure backend dynamically via `-backend-config`.  
   - Runs `plan`, `apply`, or `destroy`.  
   - After `apply`, uploads the generated kubeconfig as an artifact.  

## Outputs
- GitHub Actions → Artifacts → `kubeconfig-digitalocean` or `kubeconfig-azure`.  

---

# 4. Local usage (optional alternative to workflow)

## DigitalOcean
```bash
export DIGITALOCEAN_TOKEN="your_do_token"
cd terraform/bootstrap-digitalocean
terraform init && terraform apply -auto-approve
cd ../digitalocean
terraform init -backend-config="bucket=your-bucket"   -backend-config="region=nyc3"   -backend-config="key=doks/terraform.tfstate"   -backend-config="endpoints.s3=https://nyc3.digitaloceanspaces.com"   -backend-config="skip_credentials_validation=true"   -backend-config="skip_metadata_api_check=true"   -backend-config="skip_region_validation=true"
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

# 5. Consuming kubeconfig (from artifact)

From Jenkins repo or another workflow:

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

# 6. Best practices
- **Keep bootstrap and cluster modules separate** for clarity.  
- **Never hardcode backend config** — use workflow to inject.  
- **Store kubeconfig only as GitHub artifact**, don’t commit it.  
- **Protect `apply` and `destroy`** in workflow with GitHub Environments → approvals.  
- **Rotate tokens/secrets** regularly.  

---

# 7. Next steps
- Add AWS (EKS) & GCP (GKE) bootstrap + cluster modules.  
- Add a Jenkins repo workflow that downloads kubeconfig and deploys Jenkins Helm release.  
- Use ArgoCD for GitOps management of workloads.  

---
