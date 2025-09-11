
---

### `deploy.sh`
```bash
#!/bin/bash
set -e

echo "Select cloud provider to deploy Kubernetes:"
select provider in digitalocean azure; do
  cd modules/$provider || exit 1
  terraform init
  terraform apply -auto-approve
  break
done
