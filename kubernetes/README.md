# LKS Kubernetes Manifests

This directory contains Kubernetes manifests for the LKS application across multiple environments using Kustomize for configuration management.

## Architecture Overview

The setup consists of three environments:
- **Staging**: `lks-apps-stage` application for testing and validation
- **Production**: `lks-apps-prod` application for live traffic
- **Monitoring**: `lks-irs` application for monitoring insident response

## Directory Structure

```
kubernetes/
├── base
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── monitoring
│   ├── ingress.yaml
│   ├── irs-be
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── secret.yaml
│   │   └── service.yaml
│   ├── irs-fe
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   └── service.yaml
│   └── kustomization.yaml
├── overlays
│   ├── production
│   │   ├── deployment-patch.yaml
│   │   ├── hpa-patch.yaml
│   │   ├── ingress-patch.yaml
│   │   └── kustomization.yaml
│   └── staging
│       ├── deployment-patch.yaml
│       ├── hpa-patch.yaml
│       ├── ingress-patch.yaml
│       └── kustomization.yaml
└── README.md
```


### Useful Commands

```bash
# Check deployment status
kubectl get pods -n staging
kubectl get pods -n production
kubectl get pods -n monitoring
kubectl get deployments -n monitoring
kubectl get deployments -n staging
kubectl get deployments -n production

# View logs
kubectl logs -f deployment/lks-apps-stage -n staging
kubectl logs -f deployment/lks-apps-prod -n production
kubectl logs -f deployment/lks-irs -n monitoring

# Check ingress status and get ALB URLs
kubectl get ingress -A

# View generated manifests
kubectl kustomize overlays/staging/
kubectl kustomize overlays/production/
kubectl kustomize monitoring/

# Port forward for local access (alternative method)
kubectl port-forward service/lks-apps-stage-service 8080:8080 -n staging
kubectl port-forward service/lks-apps-prod-service 8081:8080 -n production
kubectl port-forward service/lks-irs-service 8082:8080 -n monitoring

# Get Cluster Context
aws eks update-kubeconfig --region <region> --name <cluster-name>
kubectl config get-contexts                  # Get all context
kubectl config current-context               # Get current context
kubectl config use-context <context-name>    # Switch context
kubectl config delete-context <context-name> # Delete context

# Apply or deploy kubernetes resource
kubectl apply -k monitoring
kubectl apply -k overlay/production
kubectl apply -k overlay/staging

# Rollout
kubectl rollout restart deployment your-deployment-name -n your-namespace
```

### ECR Secret for EKS
```bash
kubectl create secret docker-registry ecr-secret \
  --docker-server=<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region your_region) \
  --docker-email=none
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Multi-Environment Kubernetes Management](https://medium.com/@haroldfinch01/multiple-environments-staging-qa-production-etc-with-kubernetes-12ecc87b846a) 