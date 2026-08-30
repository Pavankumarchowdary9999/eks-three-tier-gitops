# Helm chart for the three-tier app.

## Requirements
- Helm 3.x
- A Kubernetes cluster (e.g. AWS EKS)
- `frontend` and `backend` images pushed to AWS ECR

## Install

Because the frontend nginx config proxies `/api` to the backend Service, the
entire app should be installed as ONE release so the generated service names
match.

Replace the placeholders with your real ECR image URIs:

```bash
helm install three-tier-app helm/three-tier-app \
  --create-namespace \
  --set frontend.image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/frontend \
  --set backend.image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/backend
```

Using a values file:

```bash
cat > my-values.yaml <<'EOF'
frontend:
  image:
    repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/frontend
    tag: latest
backend:
  image:
    repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/backend
    tag: latest
EOF

helm install three-tier-app helm/three-tier-app -f my-values.yaml --create-namespace
```

## Verify

```bash
helm list
kubectl get pods -n three-tier-app
kubectl get svc -n three-tier-app
kubectl get svc <release>-frontend -n three-tier-app
```

The `<release>-frontend` Service is a LoadBalancer. Once its `EXTERNAL-IP` is
populated, open `http://<EXTERNAL-IP>` in a browser.

## Upgrade (rolling update practice)

Build a new backend image tagged `v2`, push it, then:

```bash
helm upgrade three-tier-app helm/three-tier-app \
  --set backend.image.tag=v2 \
  --reuse-values
```

Or via values file:

```bash
helm upgrade three-tier-app helm/three-tier-app -f my-values.yaml
helm rollout status deployment/<release>-backend -n three-tier-app
```

## Scale

```bash
helm upgrade three-tier-app helm/three-tier-app \
  --set backend.replicaCount=3 \
  --reuse-values
```

Or directly with kubectl (good for practice):

```bash
kubectl scale deployment <release>-backend --replicas=3 -n three-tier-app
```

## Uninstall

```bash
helm uninstall three-tier-app
kubectl delete namespace three-tier-app
```

> Note: uninstalling a release does NOT delete the Postgres PersistentVolumeClaim
> by default (data persists). To remove it: `kubectl delete pvc <release>-postgres-data -n three-tier-app`.

## Configuration Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Kubernetes namespace | `three-tier-app` |
| `frontend.image.repository` | Frontend image (ECR URI) | `""` (required) |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.replicaCount` | Frontend replicas | `1` |
| `frontend.service.type` | Frontend service type | `LoadBalancer` |
| `frontend.service.port` | Frontend service port | `80` |
| `frontend.backendHost` | Backend host nginx proxies to (defaults to generated) | `""` |
| `frontend.backendPort` | Backend port nginx proxies to | `8080` |
| `backend.image.repository` | Backend image (ECR URI) | `""` (required) |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.replicaCount` | Backend replicas | `1` |
| `backend.service.type` | Backend service type | `ClusterIP` |
| `backend.env.*` | Explicit backend env values (overrides ConfigMap/Secret) | `""` |
| `postgres.image.tag` | Postgres image tag | `16-alpine` |
| `postgres.config.DB_NAME` | Database name | `itemsdb` |
| `postgres.config.DB_USERNAME` | Database user | `postgres` |
| `postgres.secret.DB_PASSWORD` | Database password | `postgres` |
| `postgres.storage.enabled` | Provision PVC for data | `true` |
| `postgres.storage.size` | PVC size | `1Gi` |

## Notes

- Install all three tiers together (one `helm install`) so the nginx proxy's
  backend hostname (`<release>-backend`) matches the rendered backend Service.
- The backend image must exist in ECR and the worker nodes must have ECR pull
  permissions (managed node groups created by `eksctl` already include
  `AmazonEC2ContainerRegistryReadOnly`).
