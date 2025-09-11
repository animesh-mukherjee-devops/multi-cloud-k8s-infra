
---

### `deploy.sh`
```bash
#!/bin/bash
set -e

echo "Select cloud provider to deploy Kubernetes:"
select provider in digitalocean azure; do
  cd modules/$provider || exit 1

  # Validate env vars
  if [[ "$provider" == "digitalocean" ]]; then
    if [[ -z "$DIGITALOCEAN_TOKEN" ]]; then
      echo "Error: DIGITALOCEAN_TOKEN is not set"
      exit 1
    fi
  fi

  if [[ "$provider" == "azure" ]]; then
    if [[ -z "$ARM_CLIENT_ID" || -z "$ARM_CLIENT_SECRET" || -z "$ARM_SUBSCRIPTION_ID" || -z "$ARM_TENANT_ID" ]]; then
      echo "Error: Azure credentials not set"
      exit 1
    fi
  fi

  terraform init
  terraform apply -auto-approve
  break
done
