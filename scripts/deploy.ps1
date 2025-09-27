# Deployment Script for Kubernetes Guestbook Modernized on Windows
# Complete deployment automation with error handling

param(
    [string]$Environment = "dev",
    [string]$ProjectId = "",
    [string]$ClusterName = "guestbook-modernized-cluster",
    [string]$ClusterZone = "us-central1-a"
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"

# Logging functions
function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Green
}

function Log-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# Check prerequisites
function Test-Prerequisites {
    Log-Info "Checking prerequisites..."
    
    $tools = @("gcloud", "kubectl", "helm", "terraform", "docker")
    
    foreach ($tool in $tools) {
        if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
            Log-Error "$tool is not installed. Please run .\scripts\setup-windows.ps1 first."
            exit 1
        }
    }
    
    Log-Info "All prerequisites are installed."
}

# Check if user is logged in to gcloud
function Test-GCloudAuth {
    Log-Info "Checking Google Cloud authentication..."
    
    try {
        $result = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
        if (!$result) {
            Log-Error "Not logged in to Google Cloud. Please run: gcloud auth login"
            exit 1
        }
        Log-Info "Google Cloud authentication verified."
    }
    catch {
        Log-Error "Failed to check Google Cloud authentication. Please run: gcloud auth login"
        exit 1
    }
}

# Deploy infrastructure
function Deploy-Infrastructure {
    Log-Info "Deploying infrastructure with Terraform..."
    
    Push-Location infrastructure
    
    try {
        # Initialize Terraform
        terraform init
        
        # Check if terraform.tfvars exists
        if (!(Test-Path "terraform.tfvars")) {
            Log-Warn "terraform.tfvars not found. Creating from example..."
            Copy-Item "terraform.tfvars.example" "terraform.tfvars"
            Log-Warn "Please edit terraform.tfvars with your project details before continuing."
            Log-Warn "Required: project_id, region, zone"
            Read-Host "Press Enter after editing terraform.tfvars"
        }
        
        # Plan deployment
        terraform plan -out=tfplan
        
        # Ask for confirmation
        $confirm = Read-Host "Do you want to apply the Terraform plan? (y/N)"
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            terraform apply tfplan
            Log-Info "Infrastructure deployed successfully."
        } else {
            Log-Warn "Infrastructure deployment cancelled."
            Pop-Location
            exit 0
        }
    }
    catch {
        Log-Error "Failed to deploy infrastructure: $_"
        Pop-Location
        exit 1
    }
    finally {
        Pop-Location
    }
}

# Configure kubectl
function Set-KubectlConfig {
    Log-Info "Configuring kubectl..."
    
    try {
        gcloud container clusters get-credentials $ClusterName --zone $ClusterZone --project $ProjectId
        Log-Info "kubectl configured successfully."
    }
    catch {
        Log-Error "Failed to configure kubectl: $_"
        exit 1
    }
}

# Deploy application
function Deploy-Application {
    Log-Info "Deploying application to $Environment environment..."
    
    try {
        # Create namespace
        kubectl create namespace guestbook-$Environment --dry-run=client -o yaml | kubectl apply -f -
        
        # Deploy with Helm
        helm upgrade --install guestbook-$Environment helm/guestbook --namespace guestbook-$Environment --values helm/guestbook/values-$Environment.yaml --wait --timeout=300s
        
        Log-Info "Application deployed successfully."
    }
    catch {
        Log-Error "Failed to deploy application: $_"
        exit 1
    }
}

# Verify deployment
function Test-Deployment {
    Log-Info "Verifying deployment..."
    
    try {
        # Check pods
        Write-Host "`nPods:" -ForegroundColor $Cyan
        kubectl get pods -n guestbook-$Environment
        
        # Check services
        Write-Host "`nServices:" -ForegroundColor $Cyan
        kubectl get svc -n guestbook-$Environment
        
        # Check ingress
        Write-Host "`nIngress:" -ForegroundColor $Cyan
        kubectl get ingress -n guestbook-$Environment
        
        # Wait for pods to be ready
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guestbook -n guestbook-$Environment --timeout=300s
        
        Log-Info "Deployment verification completed."
    }
    catch {
        Log-Error "Failed to verify deployment: $_"
        exit 1
    }
}

# Run health checks
function Test-HealthChecks {
    Log-Info "Running health checks..."
    
    try {
        # Get service URL
        $serviceIp = kubectl get svc guestbook-$Environment -n guestbook-$Environment -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        
        if (!$serviceIp) {
            Log-Warn "Service IP not available. Using port-forward for health checks."
            Start-Process kubectl -ArgumentList "port-forward", "svc/guestbook-$Environment", "-n", "guestbook-$Environment", "8080:80" -WindowStyle Hidden
            Start-Sleep 5
            $serviceIp = "localhost:8080"
        }
        
        # Test health endpoint
        try {
            $response = Invoke-WebRequest -Uri "http://$serviceIp/health" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Log-Info "Health endpoint is responding."
            } else {
                Log-Error "Health endpoint returned status code: $($response.StatusCode)"
                exit 1
            }
        }
        catch {
            Log-Error "Health endpoint is not responding: $_"
            exit 1
        }
        
        # Test main page
        try {
            $response = Invoke-WebRequest -Uri "http://$serviceIp/" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Log-Info "Main page is responding."
            } else {
                Log-Error "Main page returned status code: $($response.StatusCode)"
                exit 1
            }
        }
        catch {
            Log-Error "Main page is not responding: $_"
            exit 1
        }
        
        Log-Info "Health checks completed successfully."
        Log-Info "Application is available at: http://$serviceIp"
    }
    catch {
        Log-Error "Failed to run health checks: $_"
        exit 1
    }
}

# Main deployment function
function Start-Deployment {
    Log-Info "Starting deployment of Kubernetes Guestbook Modernized..."
    
    # Check prerequisites
    Test-Prerequisites
    
    # Check Google Cloud authentication
    Test-GCloudAuth
    
    # Get project ID if not provided
    if (!$ProjectId) {
        $ProjectId = Read-Host "Enter your Google Cloud Project ID"
    }
    
    # Set project
    gcloud config set project $ProjectId
    
    # Deploy infrastructure
    Deploy-Infrastructure
    
    # Configure kubectl
    Set-KubectlConfig
    
    # Deploy application
    Deploy-Application
    
    # Verify deployment
    Test-Deployment
    
    # Run health checks
    Test-HealthChecks
    
    Log-Info "Deployment completed successfully!"
}

# Run main function
Start-Deployment
