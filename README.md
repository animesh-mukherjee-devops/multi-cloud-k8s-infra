# multi-cloud-k8s-infra

Provision Kubernetes clusters in **DigitalOcean (DOKS)** or **Azure (AKS)** using Terraform.  
This repo is intentionally modular — each cloud module uses its **native backend** for Terraform state.

---

## Quick summary (one-liner)
- Use `./deploy.sh` locally or run the GitHub Actions workflow to provision a cluster in **digitalocean** or **azure**.  
- After completion you'll get a `kubeconfig` file in `modules/<cloud>/kubeconfig` that you can use to deploy apps (e.g., Jenkins).

---

# Table of contents
1. Prerequisites  
2. Repo structure (what's here)  
3. Required initial backend resources (must create before `terraform init`)  
4. How to run locally (step-by-step)  
5. How to pass variables (all methods)  
6. GitHub Actions (how to run, secrets, how workflow works)  
7. Module variables (full list + descriptions + defaults)  
8. Outputs (where to find kubeconfig etc.)  
9. Consuming the `kubeconfig` (deploy Jenkins or ArgoCD)  
10. Best practices & security notes  
11. Troubleshooting (common errors & fixes)  
12. Next steps & optional enhancements

---

# 1. Prerequisites

Install the following on your workstation / CI runner:

- `terraform` >= 1.6 (same version in CI is recommended)  
- `kubectl`  
- Cloud CLIs (helpful):
  - DigitalOcean: `doctl` (optional, UI or API also fine)
  - Azure: `az` CLI  
- GitHub repo with Actions enabled (if you want CI)  
- GitHub Secrets set for any automation (see section **GitHub Actions**)

---

# 2. Repo structure

```
multi-cloud-k8s-infra/
├─ README.md
├─ deploy.sh
├─ modules/
│  ├─ digitalocean/
│  │   ├─ backend.tf
│  │   ├─ variables.tf
│  │   ├─ main.tf
│  │   └─ outputs.tf
│  └─ azure/
│      ├─ backend.tf
│      ├─ variables.tf
│      ├─ main.tf
│      └─ outputs.tf
└─ .github/
   └─ workflows/
      └─ terraform.yml
```

- `modules/digitalocean` — DOKS cluster + local kubeconfig writing; backend.tf points to a DigitalOcean Spaces bucket.
- `modules/azure` — AKS cluster + local kubeconfig writing; backend.tf expects an Azure storage account + container.
- `deploy.sh` — simple interactive script to run `terraform init` and `terraform apply` for a chosen provider.
- `.github/workflows/terraform.yml` — workflow to run Terraform via GitHub Actions (uses `workflow_dispatch` so you choose cloud & action).

---

# 3. Required initial backend resources (create these BEFORE running `terraform init`)

Terraform backends for each cloud **need the remote storage object to already exist** (or you must configure init to create it). Create the backend resources **once** per environment.

## DigitalOcean (Spaces backend)
You must create a **Spaces bucket** before `terraform init` because backend block references it.

Options:
- Create a Space via the DigitalOcean control panel → Spaces → Create a Space.  
  - Name it exactly as in `modules/digitalocean/backend.tf` (or edit `backend.tf` to match your bucket name).
- Or create a bucket via S3-compatible tools (aws cli with `--endpoint-url`) — advanced.

**Important notes**
- Spaces bucket name must be unique within your account/region and is globally unique among spaces in DigitalOcean.
- Keep the bucket name secret if you want limited access (don’t commit credentials).

## Azure (azurerm backend)
The backend `azurerm` requires:
1. A Resource Group (e.g., `tfstate-rg`)
2. A Storage Account (unique name across Azure; lowercase letters and numbers)
3. A Blob Container (e.g., `tfstate`)

Example `az` CLI commands to create backend resources (replace names as needed):

```bash
# 1) Create resource group
az group create --name tfstate-rg --location eastus

# 2) Create a storage account (name must be globally unique and lower-case)
az storage account create --name tfstateaccount$RANDOM --resource-group tfstate-rg --sku Standard_LRS --location eastus

# 3) Create container in storage account
az storage container create --name tfstate --account-name <your-storage-account-name>
```

After creating the storage account, update `modules/azure/backend.tf` or pass backend values to `terraform init` via `-backend-config` if you used different names.

---

# 4. How to run locally — step by step

## 4.1 DigitalOcean (local)
1. Export your DO token:
   ```bash
   export DIGITALOCEAN_TOKEN="your_do_token_here"
   ```
2. Ensure that the Spaces bucket specified in `modules/digitalocean/backend.tf` exists (see previous section).
3. Run the interactive script:
   ```bash
   ./deploy.sh
   # when prompted select: digitalocean
   ```
   This will `cd modules/digitalocean`, run `terraform init`, then `terraform apply -auto-approve`.

4. When apply finishes, the module writes `modules/digitalocean/kubeconfig`. Use it:
   ```bash
   export KUBECONFIG=$(pwd)/modules/digitalocean/kubeconfig
   kubectl get nodes
   ```

## 4.2 Azure (local)
1. Log in to Azure CLI:
   ```bash
   az login
   ```
   or use service principal creds in environment variables if running in non-interactive contexts:
   ```bash
   export ARM_CLIENT_ID="..."
   export ARM_CLIENT_SECRET="..."
   export ARM_SUBSCRIPTION_ID="..."
   export ARM_TENANT_ID="..."
   ```
2. Ensure your `azurerm` backend resources exist (resource group, storage account, container).
3. Run the interactive script:
   ```bash
   ./deploy.sh
   # select: azure
   ```
4. After apply, `modules/azure/kubeconfig` is created — export and test:
   ```bash
   export KUBECONFIG=$(pwd)/modules/azure/kubeconfig
   kubectl get nodes
   ```

---

# 5. How to pass variables (all methods)

Terraform supports multiple ways to pass variables to modules. Use whichever best fits your workflow.

## a) CLI `-var` (one-off)
```bash
cd modules/digitalocean
terraform init
terraform apply -var="cluster_name=my-do-cluster" -var="node_count=3" -auto-approve
```

## b) `.tfvars` file (recommended for repeatable local runs)
Create a file `modules/digitalocean/terraform.tfvars` (do **not** commit secrets):

```hcl
digitalocean_token = "YOUR_TOKEN_HERE"
cluster_name       = "do-prod-01"
node_count         = 3
node_size          = "s-2vcpu-4gb"
region             = "nyc3"
```

Then run:
```bash
terraform init
terraform apply -auto-approve
```

> **Warning:** Don’t commit `terraform.tfvars` with credentials. Use CI secrets or environment variables instead.

## c) Environment variables `TF_VAR_...`
You can export `TF_VAR_*` env vars and Terraform will pick them up:
```bash
export TF_VAR_cluster_name="do-ci-cluster"
export TF_VAR_node_count=2
export TF_VAR_node_size="s-2vcpu-4gb"
```

## d) Provider-specific env vars
- DigitalOcean: `DIGITALOCEAN_TOKEN` (read by provider `digitalocean`)  
- Azure: `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID` (used by azurerm provider and CLI)

## e) GitHub Actions inputs (for CI)
The provided workflow uses `workflow_dispatch` inputs:
- `cloud` → `digitalocean` or `azure`
- `action` → `plan`, `apply`, `destroy`

You can extend the workflow to pass var overrides — I document how in the GitHub Actions section.

---

# 6. GitHub Actions — how to run & secrets

## Workflow location
`.github/workflows/terraform.yml`

## How to run
- In GitHub, open **Actions → Workflows → Terraform Multi-Cloud** → **Run workflow**.
- Select:
  - `cloud`: `digitalocean` or `azure`
  - `action`: `plan`, `apply`, `destroy`
- Click **Run workflow**.

## Required repository secrets
Add these in your GitHub repo **Settings → Secrets → Actions**:

### For DigitalOcean
- `DIGITALOCEAN_TOKEN`

### For Azure
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

## Notes on approvals & safety
- The workflow includes `apply`. For safety in a shared repo, **only run `apply` manually** via workflow_dispatch (which requires repository write permissions).  
- For stricter controls, set GitHub **environments** with required reviewers and attach the `apply` job to the environment so it requires approval.

## Uploading kubeconfig as action artifact (optional)
You can extend the workflow to upload the generated `kubeconfig` as an artifact so other workflows (e.g., `jenkins-on-k8s`) can download it and deploy apps. If you want I can generate that extension for you.

---

# 7. Module variables — full list (names, description, defaults)

## `modules/digitalocean/variables.tf`

| Name | Type | Default | Description |
|---|---:|---|---|
| `digitalocean_token` | string | (none) | **REQUIRED** — DO API token (export `DIGITALOCEAN_TOKEN` instead of committing) |
| `region` | string | `"nyc3"` | DO region to create cluster in |
| `cluster_name` | string | `"do-terraform-cluster"` | Kubernetes cluster name |
| `node_size` | string | `"s-2vcpu-4gb"` | Droplet size for worker nodes |
| `node_count` | number | `2` | Number of nodes in default pool |

---

## `modules/azure/variables.tf`

| Name | Type | Default | Description |
|---|---:|---|---|
| `resource_group_name` | string | `"aks-rg"` | Resource group for AKS cluster |
| `cluster_name` | string | `"aks-cluster"` | AKS cluster name |
| `location` | string | `"East US"` | Azure region (you may want to use canonical name like `eastus` for CLI) |
| `node_count` | number | `2` | Number of worker nodes |
| `node_size` | string | `"Standard_DS2_v2"` | VM SKU for nodes |

---

# 8. Outputs — what the modules create (where to find kubeconfig)

After `terraform apply` finishes:

- **DigitalOcean**: `modules/digitalocean/kubeconfig` — exported path: `modules/digitalocean/kubeconfig`  
- **Azure**: `modules/azure/kubeconfig` — exported path: `modules/azure/kubeconfig`

To use the cluster locally:
```bash
export KUBECONFIG=$(pwd)/modules/digitalocean/kubeconfig
kubectl get nodes
```
Or copy it into `~/.kube/config` if you prefer:
```bash
cp modules/digitalocean/kubeconfig ~/.kube/config
```

---

# 9. Consuming the kubeconfig — Jenkins repo & ArgoCD

## Option A — Terraform Helm provider (run from `jenkins-on-k8s` repo)
```bash
export KUBECONFIG=multi-cloud-k8s-infra/modules/digitalocean/kubeconfig
cd jenkins-on-k8s/helm
terraform init
terraform apply -var="kubeconfig_path=$KUBECONFIG" -auto-approve
```

## Option B — GitOps with ArgoCD (recommended for apps)
1. Install ArgoCD into the cluster:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. Apply the Jenkins ArgoCD app:
   ```bash
   kubectl apply -f jenkins-on-k8s/argocd/jenkins-app.yaml -n argocd
   ```

---

# 10. Best practices & security notes

- Do not commit secrets (`.tfvars`, `kubeconfig`).  
- DigitalOcean Spaces backend has no locking — prefer Terraform Cloud or S3+DynamoDB for team use.  
- Use GitHub **environments** with approvals for `apply`.  
- Store Jenkins passwords in Kubernetes Secrets or Vault, not in Helm values.  

---

# 11. Troubleshooting

- **NoSuchBucket (DO Spaces)** → Create bucket first or update backend.tf.  
- **Azure auth failed** → Check `ARM_*` vars or `az login`.  
- **Provider version mismatch** → Pin provider versions in modules.  
- **kubeconfig missing** → Ensure `terraform apply` succeeded.

---

# 12. Next steps & optional enhancements

- Add AWS (EKS) & GCP (GKE) modules.  
- Switch DigitalOcean backend to Terraform Cloud for state + locking.  
- Use OIDC for GitHub → Azure/AWS auth.  
- Upload kubeconfig as artifact in CI.  
- Add GitHub Actions PR flow: `plan` on PR, `apply` on main branch.  
- Add monitoring/logging apps in a separate GitOps repo.

---
