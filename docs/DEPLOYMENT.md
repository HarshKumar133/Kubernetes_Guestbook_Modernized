# Deployment Guide

## Prerequisites

### Required Tools
- Google Cloud SDK (gcloud)
- Terraform >= 1.0
- Helm >= 3.0
- kubectl
- Docker

### Required Permissions
- Google Cloud Project with billing enabled
- Service Account with necessary permissions
- GitHub repository with secrets configured

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/your-org/kubernetes-guestbook-modernized.git
cd kubernetes-guestbook-modernized
```

### 2. Configure Environment
```bash
# Copy and edit Terraform variables
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
cd infrastructure
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 4. Configure kubectl
```bash
# Get cluster credentials
gcloud container clusters get-credentials guestbook-modernized-cluster \
  --zone us-central1-a \
  --project your-project-id
```

### 5. Deploy Application
```bash
# Deploy to development
helm install guestbook-dev helm/guestbook \
  --namespace guestbook-dev \
  --create-namespace \
  --values helm/guestbook/values-dev.yaml

# Deploy to staging
helm install guestbook-staging helm/guestbook \
  --namespace guestbook-staging \
  --create-namespace \
  --values helm/guestbook/values-staging.yaml

# Deploy to production
helm install guestbook-prod helm/guestbook \
  --namespace guestbook-prod \
  --create-namespace \
  --values helm/guestbook/values-production.yaml
```

## Environment-Specific Deployment

### Development Environment
- **Purpose**: Development and testing
- **Resources**: Minimal (1 replica, 64Mi memory)
- **Persistence**: Disabled
- **Monitoring**: Basic
- **Security**: Relaxed

### Staging Environment
- **Purpose**: Pre-production testing
- **Resources**: Medium (2 replicas, 128Mi memory)
- **Persistence**: Enabled (4Gi)
- **Monitoring**: Full stack
- **Security**: Production-like

### Production Environment
- **Purpose**: Production workload
- **Resources**: High (3+ replicas, 256Mi+ memory)
- **Persistence**: Enabled with replication (20Gi)
- **Monitoring**: Comprehensive
- **Security**: Full compliance

## Rolling Updates

### Update Strategy
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

### Health Checks
- **Liveness Probe**: HTTP GET /health
- **Readiness Probe**: HTTP GET /health
- **Startup Probe**: HTTP GET /health

### Update Process
1. Create new pod with updated image
2. Wait for new pod to be ready
3. Terminate old pod
4. Repeat until all pods updated

## Monitoring Deployment

### Check Deployment Status
```bash
# Check pods
kubectl get pods -n guestbook-prod

# Check services
kubectl get svc -n guestbook-prod

# Check ingress
kubectl get ingress -n guestbook-prod
```

### View Logs
```bash
# Application logs
kubectl logs -f deployment/guestbook-prod -n guestbook-prod

# Redis logs
kubectl logs -f deployment/redis-master -n guestbook-prod
```

### Monitor Metrics
- **Prometheus**: http://prometheus.monitoring.svc.cluster.local
- **Grafana**: http://grafana.monitoring.svc.cluster.local

## Troubleshooting

### Common Issues

#### Pod Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n guestbook-prod

# Check logs
kubectl logs <pod-name> -n guestbook-prod
```

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n guestbook-prod

# Check ingress configuration
kubectl describe ingress guestbook-prod -n guestbook-prod
```

#### Redis Connection Issues
```bash
# Check Redis status
kubectl exec -it deployment/redis-master -n guestbook-prod -- redis-cli ping

# Check Redis logs
kubectl logs deployment/redis-master -n guestbook-prod
```

### Rollback Procedure
```bash
# Rollback to previous version
helm rollback guestbook-prod -n guestbook-prod

# Check rollback status
helm history guestbook-prod -n guestbook-prod
```

## Security Considerations

### Network Policies
- Pod-to-pod communication restricted
- Ingress/egress rules defined
- Namespace isolation

### Secret Management
- Kubernetes secrets for sensitive data
- Encryption at rest
- Access control via RBAC

### Image Security
- Vulnerability scanning
- Signed images
- Regular updates

## Performance Optimization

### Resource Limits
- CPU and memory limits set
- Horizontal Pod Autoscaler configured
- Node affinity rules

### Caching
- Redis for session storage
- Nginx caching for static content
- OPcache for PHP

### Monitoring
- Prometheus metrics collection
- Grafana dashboards
- Alerting rules configured
