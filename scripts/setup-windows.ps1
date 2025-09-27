# Setup Script for Kubernetes Guestbook Modernized on Windows
# This script installs all required tools for the project

Write-Host "🚀 Setting up Kubernetes Guestbook Modernized on Windows..." -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires Administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not already installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install required tools
Write-Host "📦 Installing required tools..." -ForegroundColor Yellow

# Install Google Cloud SDK
Write-Host "Installing Google Cloud SDK..." -ForegroundColor Cyan
choco install gcloudsdk -y

# Install Terraform
Write-Host "Installing Terraform..." -ForegroundColor Cyan
choco install terraform -y

# Install kubectl
Write-Host "Installing kubectl..." -ForegroundColor Cyan
choco install kubernetes-cli -y

# Install Helm
Write-Host "Installing Helm..." -ForegroundColor Cyan
choco install kubernetes-helm -y

# Install Docker Desktop
Write-Host "Installing Docker Desktop..." -ForegroundColor Cyan
choco install docker-desktop -y

# Install Git (if not already installed)
Write-Host "Installing Git..." -ForegroundColor Cyan
choco install git -y

# Install Make for Windows
Write-Host "Installing Make..." -ForegroundColor Cyan
choco install make -y

# Refresh environment variables
Write-Host "🔄 Refreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "✅ Setup completed! Please restart your terminal and run the following commands:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Initialize gcloud: gcloud init" -ForegroundColor Cyan
Write-Host "2. Login to Google Cloud: gcloud auth login" -ForegroundColor Cyan
Write-Host "3. Set your project: gcloud config set project YOUR_PROJECT_ID" -ForegroundColor Cyan
Write-Host "4. Run the deployment: .\scripts\deploy.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: You may need to restart your computer for all environment variables to take effect." -ForegroundColor Yellow
