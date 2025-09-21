#!/usr/bin/env bash
set -euo pipefail
PROVIDER=${1:-digitalocean}

if [[ "$PROVIDER" == "digitalocean" ]]; then
  cd terraform/bootstrap-digitalocean
  terraform init
  terraform apply -auto-approve
  cd ../digitalocean
  bucket=$(terraform -chdir=../bootstrap-digitalocean output -raw bucket_name)
  region=$(terraform -chdir=../bootstrap-digitalocean output -raw region || echo nyc3)
  terraform init -backend-config="bucket=${bucket}" \
     -backend-config="key=doks/terraform.tfstate" \
     -backend-config="region=us-east-1" \
     -backend-config="endpoints.s3=https://${region}.digitaloceanspaces.com" \
     -backend-config="skip_credentials_validation=true" \
     -backend-config="skip_metadata_api_check=true" \
     -backend-config="skip_region_validation=true"
  terraform apply -auto-approve
else
  echo "Azure path not implemented in deploy.sh here; run terraform manually per README"
fi
