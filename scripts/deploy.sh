#!/bin/bash
# Deployment Script for Kubernetes Guestbook Modernized
# Complete deployment automation with error handling

set -e

# Configuration
PROJECT_ID=${PROJECT_ID:-"your-project-id"}
CLUSTER_NAME=${CLUSTER_NAME:-"guestbook-modernized-cluster"}
CLUSTER_ZONE=${CLUSTER_ZONE:-"us-central1-a"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud is not installed. Please install Google Cloud SDK."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed. Please install Helm."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "terraform is not installed. Please install Terraform."
        exit 1
    fi
    
    log_info "All prerequisites are installed."
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd infrastructure
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    cd ..
    
    log_info "Infrastructure deployed successfully."
}

# Configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl..."
    
    gcloud container clusters get-credentials $CLUSTER_NAME \
        --zone $CLUSTER_ZONE \
        --project $PROJECT_ID
    
    log_info "kubectl configured successfully."
}

# Deploy application
deploy_application() {
    log_info "Deploying application to $ENVIRONMENT environment..."
    
    # Create namespace
    kubectl create namespace guestbook-$ENVIRONMENT --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy with Helm
    helm upgrade --install guestbook-$ENVIRONMENT helm/guestbook \
        --namespace guestbook-$ENVIRONMENT \
        --values helm/guestbook/values-$ENVIRONMENT.yaml \
        --wait --timeout=300s
    
    log_info "Application deployed successfully."
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pods
    kubectl get pods -n guestbook-$ENVIRONMENT
    
    # Check services
    kubectl get svc -n guestbook-$ENVIRONMENT
    
    # Check ingress
    kubectl get ingress -n guestbook-$ENVIRONMENT
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guestbook -n guestbook-$ENVIRONMENT --timeout=300s
    
    log_info "Deployment verification completed."
}

# Run health checks
run_health_checks() {
    log_info "Running health checks..."
    
    # Get service URL
    SERVICE_IP=$(kubectl get svc guestbook-$ENVIRONMENT -n guestbook-$ENVIRONMENT -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$SERVICE_IP" ]; then
        log_warn "Service IP not available. Using port-forward for health checks."
        kubectl port-forward svc/guestbook-$ENVIRONMENT -n guestbook-$ENVIRONMENT 8080:80 &
        PORT_FORWARD_PID=$!
        sleep 5
        SERVICE_IP="localhost:8080"
    fi
    
    # Test health endpoint
    if curl -f http://$SERVICE_IP/health; then
        log_info "Health endpoint is responding."
    else
        log_error "Health endpoint is not responding."
        exit 1
    fi
    
    # Test main page
    if curl -f http://$SERVICE_IP/; then
        log_info "Main page is responding."
    else
        log_error "Main page is not responding."
        exit 1
    fi
    
    # Cleanup port-forward if used
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID
    fi
    
    log_info "Health checks completed successfully."
}

# Main deployment function
main() {
    log_info "Starting deployment of Kubernetes Guestbook Modernized..."
    
    # Check prerequisites
    check_prerequisites
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Configure kubectl
    configure_kubectl
    
    # Deploy application
    deploy_application
    
    # Verify deployment
    verify_deployment
    
    # Run health checks
    run_health_checks
    
    log_info "Deployment completed successfully!"
    log_info "Application is available at: http://$SERVICE_IP"
}

# Run main function
main "$@"
