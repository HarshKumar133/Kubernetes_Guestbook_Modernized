#!/bin/bash
# Security Scanning Script for Kubernetes Guestbook Modernized
# Comprehensive security scanning with multiple tools

set -e

echo "🔒 Starting security scan for Kubernetes Guestbook Modernized..."

# Create reports directory
mkdir -p reports

# Run Trivy vulnerability scan
echo "🔍 Running Trivy vulnerability scan..."
trivy fs . --config trivy-config.yaml --format json --output reports/trivy-vulnerabilities.json
trivy fs . --config trivy-config.yaml --format table --output reports/trivy-vulnerabilities.txt

# Run Trivy image scan
echo "🔍 Running Trivy image scan..."
trivy image --format json --output reports/trivy-images.json guestbook-modernized/frontend:latest
trivy image --format table --output reports/trivy-images.txt guestbook-modernized/frontend:latest

# Run Semgrep SAST
echo "🔍 Running Semgrep SAST..."
semgrep --config=auto --json --output=reports/semgrep-results.json .
semgrep --config=auto --output=reports/semgrep-results.txt .

# Run Checkov for IaC security
echo "🔍 Running Checkov IaC security scan..."
checkov -d infrastructure/ --framework terraform --output json --output-file-path reports/checkov-results.json
checkov -d infrastructure/ --framework terraform --output table --output-file-path reports/checkov-results.txt

# Run OPA Conftest
echo "🔍 Running OPA Conftest..."
conftest test helm/guestbook/templates/ --policy policies/ --output json > reports/conftest-results.json
conftest test helm/guestbook/templates/ --policy policies/ --output table > reports/conftest-results.txt

# Run Kyverno policy validation
echo "🔍 Running Kyverno policy validation..."
kyverno apply policies/kyverno/ --resource helm/guestbook/templates/ --output json > reports/kyverno-results.json
kyverno apply policies/kyverno/ --resource helm/guestbook/templates/ --output table > reports/kyverno-results.txt

# GDPR Compliance Check
echo "🔍 Running GDPR compliance check..."
python3 scripts/gdpr-compliance.py > reports/gdpr-compliance.txt

# Generate security report
echo "📊 Generating security report..."
python3 scripts/generate-security-report.py

echo "✅ Security scan completed! Check reports/ directory for results."
