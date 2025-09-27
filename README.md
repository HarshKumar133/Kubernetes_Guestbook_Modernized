# Kubernetes Guestbook Modernized

A comprehensive, enterprise-grade implementation of the Kubernetes Guestbook application with advanced infrastructure, monitoring, and deployment capabilities.

## 🏗️ Architecture Overview

This project extends the official Kubernetes guestbook application with:

- **Infrastructure as Code**: Complete GKE setup using Terraform
- **Multi-Environment Support**: Dev, staging, and production configurations
- **CI/CD Pipeline**: Automated testing, security scanning, and progressive deployment
- **Monitoring & Observability**: Prometheus metrics and custom Grafana dashboards
- **Security & Compliance**: GDPR compliance and security best practices
- **Zero-Downtime Deployments**: Rolling updates with health checks

## 📁 Project Structure

```
├── infrastructure/          # Terraform infrastructure code
├── applications/           # Guestbook application code
├── helm/                  # Helm charts for deployment
├── monitoring/            # Prometheus and Grafana configurations
├── ci-cd/                 # GitHub Actions workflows
├── security/              # Security scanning and compliance
├── docs/                  # Documentation
└── scripts/               # Utility scripts
```

## 🚀 Quick Start

### Local Development (Windows)

1. **Prerequisites:**
   - Windows 10/11
   - PowerShell (Run as Administrator)
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/)
   - [Chocolatey](https://chocolatey.org/) (auto-installed if missing)

2. **Run the complete setup script:**
   ```powershell
   .\scripts\install-and-run.ps1
   ```
   This script will:
   - Install all required tools (gcloud, Terraform, Helm, kubectl, Docker, Git, Make)
   - Build and run the application locally using Docker
   - Show application URLs and status

   **Alternative:** For a lighter setup, use:
   ```powershell
   .\scripts\local-dev.ps1
   # or
   .\scripts\run-local.ps1
   ```

3. **Access the app:**
   - Frontend: [http://localhost:8080](http://localhost:8080)
   - Health: [http://localhost:8080/health](http://localhost:8080/health)

### Local Development (Linux/macOS/WSL)

1. **Prerequisites:**
   - Docker
   - Make
   - Bash

2. **Set up and run:**
   ```bash
   make dev-setup   # (if implemented)
   # or use the Makefile targets below
   ```

### Cloud Deployment (GKE)

1. **Prerequisites:**
   - Google Cloud SDK
   - Terraform >= 1.0
   - Helm >= 3.0
   - kubectl

2. **Deploy Infrastructure:**
   ```bash
   cd infrastructure
   terraform init
   terraform plan
   terraform apply
   ```

3. **Configure kubectl:**
   ```bash
   gcloud container clusters get-credentials guestbook-modernized-cluster \
     --zone us-central1-a \
     --project <your-project-id>
   ```

4. **Deploy Application:**
   ```bash
   helm install guestbook ./helm/guestbook
   # or for specific environments:
   helm install guestbook-dev helm/guestbook --namespace guestbook-dev --create-namespace --values helm/guestbook/values-dev.yaml
   ```

5. **More details:** See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)

## 🛠️ Makefile Commands

The Makefile provides convenient commands for common tasks:

- `make install-infra`      # Deploy infrastructure with Terraform
- `make destroy-infra`      # Destroy infrastructure
- `make deploy-app`         # Deploy the application with Helm
- `make upgrade-app`        # Upgrade the application
- `make uninstall-app`      # Uninstall the application
- `make deploy-monitoring`  # Deploy monitoring stack
- `make test`               # Run all tests
- `make security-scan`      # Run security scans
- `make clean`              # Clean up temporary files
- `make status`             # Show status of all components

## 🧪 Testing & Security

- **Run tests:**
  ```bash
  make test
  ```
- **Run security scans:**
  ```bash
  make security-scan
  # or
  ./security/scan.sh
  ```
- **CI/CD:** Automated testing, linting, and security scanning are run in GitHub Actions (see `.github/workflows/ci.yml` and `.github/workflows/cd.yml`).

## 📊 Monitoring

Access monitoring dashboards:
- Grafana: `http://grafana.your-domain.com`
- Prometheus: `http://prometheus.your-domain.com`

## 🔒 Security

- Automated security scanning in CI/CD
- GDPR compliance validation
- Network policies and RBAC
- Image vulnerability scanning

## 📚 Documentation

See the `docs/` directory for detailed documentation on:
- Architecture decisions
- Deployment procedures
- Monitoring setup
- Security policies

## 🐞 Troubleshooting

- **Docker not running:** Ensure Docker Desktop is started before running scripts.
- **Permissions:** On Windows, always run PowerShell as Administrator for setup scripts.
- **Ports in use:** Stop any existing containers using `docker stop guestbook-frontend guestbook-redis`.
- **Script errors:** Check logs/output for details. Most scripts will print clear error messages.
- **Cloud deployment issues:** See `docs/DEPLOYMENT.md` for troubleshooting GKE and Terraform.
