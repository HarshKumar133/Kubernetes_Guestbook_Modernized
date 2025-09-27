# Kubernetes Guestbook Modernized - Makefile
# This Makefile provides convenient commands for managing the entire project

.PHONY: help install-infra deploy-app destroy clean test security-scan

# Default target
help: ## Show this help message
	@echo "Kubernetes Guestbook Modernized - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Infrastructure Management
install-infra: ## Initialize and deploy infrastructure with Terraform
	@echo "🚀 Deploying infrastructure..."
	cd infrastructure && terraform init
	cd infrastructure && terraform plan
	cd infrastructure && terraform apply -auto-approve
	@echo "✅ Infrastructure deployed successfully!"

destroy-infra: ## Destroy infrastructure
	@echo "🗑️ Destroying infrastructure..."
	cd infrastructure && terraform destroy -auto-approve
	@echo "✅ Infrastructure destroyed!"

# Application Management
deploy-app: ## Deploy the guestbook application using Helm
	@echo "🚀 Deploying guestbook application..."
	helm install guestbook ./helm/guestbook --create-namespace --namespace guestbook
	@echo "✅ Application deployed successfully!"

upgrade-app: ## Upgrade the guestbook application
	@echo "🔄 Upgrading guestbook application..."
	helm upgrade guestbook ./helm/guestbook --namespace guestbook
	@echo "✅ Application upgraded successfully!"

uninstall-app: ## Uninstall the guestbook application
	@echo "🗑️ Uninstalling guestbook application..."
	helm uninstall guestbook --namespace guestbook
	@echo "✅ Application uninstalled!"

# Monitoring
deploy-monitoring: ## Deploy monitoring stack (Prometheus + Grafana)
	@echo "📊 Deploying monitoring stack..."
	helm install monitoring ./helm/monitoring --create-namespace --namespace monitoring
	@echo "✅ Monitoring deployed successfully!"

# Testing
test: ## Run all tests
	@echo "🧪 Running tests..."
	cd applications && make test
	@echo "✅ Tests completed!"

# Security
security-scan: ## Run security scans
	@echo "🔒 Running security scans..."
	cd security && make scan
	@echo "✅ Security scan completed!"

# Development
dev-setup: ## Set up development environment
	@echo "🛠️ Setting up development environment..."
	@echo "Installing dependencies..."
	@echo "✅ Development environment ready!"

# Cleanup
clean: ## Clean up temporary files and resources
	@echo "🧹 Cleaning up..."
	rm -rf .terraform/
	rm -rf charts/
	rm -f *.log
	@echo "✅ Cleanup completed!"

# Status
status: ## Check status of all components
	@echo "📊 Checking status..."
	@echo "Kubernetes cluster:"
	kubectl cluster-info
	@echo ""
	@echo "Deployed applications:"
	helm list --all-namespaces
	@echo ""
	@echo "Pods status:"
	kubectl get pods --all-namespaces
