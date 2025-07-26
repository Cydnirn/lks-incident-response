# LKS Kubernetes Manifests

This directory contains Kubernetes manifests for the LKS application across multiple environments using Kustomize for configuration management.

## Architecture Overview

The setup consists of three environments:
- **Staging**: `lks-apps-stage` application for testing and validation
- **Production**: `lks-apps-prod` application for live traffic
- **Monitoring**: `lks-irs` application for monitoring and observability

## Directory Structure

```
kubernetes/
├── base/                           # Base manifests (templates)
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
├── overlays/                       # Environment-specific overlays
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   ├── deployment-patch.yaml
│   │   ├── hpa-patch.yaml
│   │   └── ingress-patch.yaml
│   └── production/
│       ├── kustomization.yaml
│       ├── deployment-patch.yaml
│       ├── hpa-patch.yaml
│       └── ingress-patch.yaml
├── monitoring/                     # Monitoring namespace manifests
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
├── deploy.sh                       # Deployment script
└── README.md                       # This file
```

## Environment Details

### Staging Environment
- **Namespace**: `staging`
- **Application**: `loadsim-app`
- **Replicas**: 1 (min) - 3 (max)
- **Resources**: 256Mi-512Mi memory, 512m CPU
- **Access**: External ALB DNS name (HTTP)
- **Image**: `betuah/loadsim:latest`
- **Purpose**: Testing and validation

### Production Environment
- **Namespace**: `production`
- **Application**: `loadsim-app`
- **Replicas**: 3 (min) - 20 (max)
- **Resources**: 1024Mi memory, 512m CPU
- **Access**: External ALB DNS name (HTTP)
- **Image**: `betuah/loadsim:latest`
- **Purpose**: Live production traffic

### Monitoring Environment
- **Namespace**: `monitoring`
- **Application**: `lks-irs`
- **Replicas**: 2 (min) - 10 (max)
- **Resources**: 128Mi-256Mi memory, 100m-200m CPU
- **Access**: External ALB DNS name (HTTP)
- **Image**: Private ECR (`472634532065.dkr.ecr.us-east-1.amazonaws.com/lks/loadsim:latest`)
- **Port**: 8080 (container), 80 (service)
- **Purpose**: Monitoring and observability

## Prerequisites

1. **Kubernetes Cluster**: EKS, GKE, or any Kubernetes cluster
2. **AWS Load Balancer Controller**: For ALB ingress functionality
3. **kubectl**: Configured to access your cluster
4. **kustomize**: For applying manifests (included with kubectl)
5. **AWS CLI**: Configured with appropriate permissions for ECR access
6. **ECR Access**: Permissions to pull from private ECR repository

## Deployment

### ECR Setup (Required for Monitoring)

Before deploying the monitoring application, you need to set up ECR authentication:

```bash
# Set up ECR authentication for monitoring namespace
./setup-ecr-auth.sh
```

This script will:
- Create the monitoring namespace
- Generate ECR authentication token
- Create Kubernetes secret for ECR access

### Quick Deploy
```bash
# Deploy to specific environment
./deploy.sh staging
./deploy.sh production

# For monitoring (requires ECR setup first)
./setup-ecr-auth.sh
./deploy.sh monitoring

# Deploy to all environments
./deploy.sh all
```

### Accessing Your Applications

After deployment, you can access your applications using:

1. **External ALB DNS Names** (recommended):
   ```bash
   # Get ALB URLs
   ./get-alb-urls.sh
   
   # Access via ALB DNS name (accessible from internet)
   curl http://<alb-dns-name>
   ```

2. **Port Forwarding** (for local development):
   ```bash
   # Staging
   kubectl port-forward service/lks-apps-stage-service 8080:80 -n staging
   # Access at: http://localhost:8080
   
   # Production
   kubectl port-forward service/lks-apps-prod-service 8081:80 -n production
   # Access at: http://localhost:8081
   
   # Monitoring
   kubectl port-forward service/lks-irs-service 8082:80 -n monitoring
   # Access at: http://localhost:8082
   ```

3. **Direct Service Access** (from within cluster):
   ```bash
   # From a pod in the same cluster
   curl http://lks-apps-stage-service.staging.svc.cluster.local
   curl http://lks-apps-prod-service.production.svc.cluster.local
   curl http://lks-irs-service.monitoring.svc.cluster.local
   ```

### Manual Deploy
```bash
# Staging
kubectl apply -k overlays/staging/

# Production
kubectl apply -k overlays/production/

# Monitoring
kubectl apply -k monitoring/
```

## Configuration Management

### Environment-Specific Configurations

Each environment has its own configuration:

- **ConfigMaps**: Environment variables, API URLs, log levels
- **Secrets**: Database passwords, API keys
- **Resource Limits**: CPU and memory allocations
- **Scaling**: HPA configurations
- **Ingress**: Domain names and SSL certificates

### Kustomize Features Used

1. **Name Prefixing**: Each environment gets a unique prefix
2. **Namespace Isolation**: Separate namespaces for each environment
3. **ConfigMap/Secret Generation**: Environment-specific values
4. **Strategic Merge Patches**: Customize base manifests
5. **Image Transformer**: Manage different image versions per environment

## Monitoring and Scaling

### Horizontal Pod Autoscaler (HPA)
- **Staging**: 1-3 replicas, 80% CPU threshold
- **Production**: 3-20 replicas, 60% CPU, 70% memory thresholds
- **Monitoring**: 2-10 replicas, 70% CPU, 80% memory thresholds

### Health Checks
- **Liveness Probe**: `/health` endpoint
- **Readiness Probe**: `/ready` endpoint
- **ALB Health Check**: Configured for load balancer health monitoring

## Load Balancer Configuration

### AWS Application Load Balancer (ALB)
- **Scheme**: Internet-facing (external access)
- **Target Type**: IP mode
- **Protocol**: HTTP only (no SSL/TLS)
- **Health Checks**: Configured per environment
- **Access**: External DNS names provided by AWS (accessible from internet)

## Security Considerations

1. **Namespace Isolation**: Each environment is in its own namespace
2. **RBAC**: Separate service accounts and roles per environment
3. **Secrets Management**: Kubernetes secrets for sensitive data
4. **Network Policies**: Can be added for additional network isolation

## Troubleshooting

### Common Issues

1. **Image Pull Errors**: Ensure image tags exist in registry
2. **ECR Authentication Errors**: Run `./setup-ecr-auth.sh` for monitoring deployment
3. **Resource Quotas**: Check namespace resource limits
4. **Ingress Issues**: Verify ALB controller is installed
5. **ALB Not Provisioned**: Wait 5-10 minutes for AWS to provision external ALB
6. **Access Issues**: Use external ALB DNS name or port-forward for access

### Useful Commands

```bash
# Check deployment status
kubectl get pods -n staging
kubectl get pods -n production
kubectl get pods -n monitoring

# View logs
kubectl logs -f deployment/lks-apps-stage -n staging
kubectl logs -f deployment/lks-apps-prod -n production
kubectl logs -f deployment/lks-irs -n monitoring

# Check ingress status and get ALB URLs
kubectl get ingress -A
./get-alb-urls.sh

# View generated manifests
kubectl kustomize overlays/staging/
kubectl kustomize overlays/production/
kubectl kustomize monitoring/

# Update image tags using Kustomize
./update-images.sh staging betuah/loadsim v1.0.0
./update-images.sh production betuah/loadsim v1.1.0
./update-images.sh monitoring betuah/loadsim v2.1.0

# Port forward for local access (alternative method)
kubectl port-forward service/lks-apps-stage-service 8080:8080 -n staging
kubectl port-forward service/lks-apps-prod-service 8081:8080 -n production
kubectl port-forward service/lks-irs-service 8082:8080 -n monitoring
```

## Customization

### Adding New Environments
1. Create new overlay directory in `overlays/`
2. Copy and modify existing kustomization.yaml
3. Update patches for environment-specific configurations
4. Add deployment script entry

### Modifying Base Configuration
1. Edit files in `base/` directory
2. Test with `kubectl kustomize overlays/<environment>/`
3. Apply changes to affected environments

### Managing Images with Kustomize
1. **Update image tags**: Use `./update-images.sh <environment> <image_name> <new_tag>`
2. **View image transformations**: Check the `images` section in each kustomization.yaml
3. **Base image**: All environments use `betuah/loadsim:latest` as base, transformed per environment
4. **Monitoring**: Uses ECR image `472634532065.dkr.ecr.us-east-1.amazonaws.com/lks/loadsim:latest`

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Multi-Environment Kubernetes Management](https://medium.com/@haroldfinch01/multiple-environments-staging-qa-production-etc-with-kubernetes-12ecc87b846a) 