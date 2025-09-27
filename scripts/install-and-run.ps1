# Complete Installation and Deployment Script for Kubernetes Guestbook Modernized
# This script installs all required tools and runs the complete application

param(
    [string]$ProjectId = "",
    [string]$Environment = "dev"
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Blue = "Blue"

# Logging functions
function Log-Info {
    param([string]$Message)
    Write-Host "`n[INFO] $Message" -ForegroundColor $Green
}

function Log-Warn {
    param([string]$Message)
    Write-Host "`n[WARN] $Message" -ForegroundColor $Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "`n[ERROR] $Message" -ForegroundColor $Red
}

function Log-Step {
    param([string]$Message)
    Write-Host "`n🔧 $Message" -ForegroundColor $Cyan
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install Chocolatey
function Install-Chocolatey {
    Log-Step "Installing Chocolatey package manager..."
    
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Log-Info "Chocolatey installed successfully"
        }
        catch {
            Log-Error "Failed to install Chocolatey: $_"
            exit 1
        }
    } else {
        Log-Info "Chocolatey is already installed"
    }
}

# Install required tools
function Install-RequiredTools {
    Log-Step "Installing required tools..."
    
    $tools = @(
        @{Name="gcloudsdk"; DisplayName="Google Cloud SDK"},
        @{Name="terraform"; DisplayName="Terraform"},
        @{Name="kubernetes-cli"; DisplayName="kubectl"},
        @{Name="kubernetes-helm"; DisplayName="Helm"},
        @{Name="docker-desktop"; DisplayName="Docker Desktop"},
        @{Name="git"; DisplayName="Git"},
        @{Name="make"; DisplayName="Make"}
    )
    
    foreach ($tool in $tools) {
        Log-Info "Installing $($tool.DisplayName)..."
        try {
            choco install $tool.Name -y --no-progress
            Log-Info "$($tool.DisplayName) installed successfully"
        }
        catch {
            Log-Warn "Failed to install $($tool.DisplayName): $_"
        }
    }
}

# Wait for Docker to start
function Wait-ForDocker {
    Log-Step "Waiting for Docker to start..."
    
    $maxAttempts = 30
    $attempt = 0
    
    do {
        $attempt++
        Log-Info "Waiting for Docker... (Attempt $attempt/$maxAttempts)"
        Start-Sleep 10
        
        try {
            docker version | Out-Null
            Log-Info "Docker is running!"
            return $true
        }
        catch {
            if ($attempt -eq $maxAttempts) {
                Log-Error "Docker failed to start after $maxAttempts attempts"
                return $false
            }
        }
    } while ($attempt -lt $maxAttempts)
    
    return $false
}

# Build and run local development environment
function Start-LocalDevelopment {
    Log-Step "Starting local development environment..."
    
    # Create environment file
    Log-Info "Creating environment configuration..."
    $envDir = "applications\frontend"
    if (!(Test-Path $envDir)) {
        New-Item -ItemType Directory -Path $envDir -Force | Out-Null
    }
    $envFile = Join-Path $envDir ".env"
    $envContent = @"
# Local Development Environment
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=dev-redis-password
PHP_MEMORY_LIMIT=128M
PHP_MAX_EXECUTION_TIME=30
APP_ENV=development
APP_DEBUG=true
LOG_LEVEL=debug
"@
$envContent | Set-Content -Path $envFile -Encoding UTF8
Write-Host "Stopping any existing containers..."`
 -ForegroundColor Green`

    docker stop guestbook-frontend guestbook-redis 2>$null
    docker rm guestbook-frontend guestbook-redis 2>$null
    
    # Build and run Redis
    Log-Info "Building and starting Redis..."
    Push-Location applications\redis
    try {
        docker build -t guestbook-redis:latest .
        docker run -d --name guestbook-redis -p 6379:6379 -e REDIS_PASSWORD=dev-redis-password guestbook-redis:latest
        Log-Info "Redis started successfully"
    }
    catch {
        Log-Error "Failed to start Redis: $_"
        Pop-Location
        return $false
    }
    finally {
        Pop-Location
    }
    
    # Build and run Frontend
    Log-Info "Building and starting Frontend..."
    Push-Location applications\frontend
    try {
        docker build -t guestbook-frontend:latest .
        docker run -d --name guestbook-frontend -p 8080:80 --link guestbook-redis:redis -e REDIS_HOST=redis -e REDIS_PASSWORD=dev-redis-password guestbook-frontend:latest
        Log-Info "Frontend started successfully"
    }
    catch {
        Log-Error "Failed to start Frontend: $_"
        Pop-Location
        return $false
    }
    finally {
        Pop-Location
    }
    
    # Wait for services to be ready
    Log-Info "Waiting for services to be ready..."
    Start-Sleep 15
    
    # Test the application
    Log-Info "Testing the application..."
    $maxAttempts = 10
    $attempt = 0
    
    do {
        $attempt++
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Log-Info "✅ Application is running successfully!"
                return $true
            }
        }
        catch {
            if ($attempt -eq $maxAttempts) {
                Log-Error "Application failed to start after $maxAttempts attempts"
                return $false
            }
            Log-Info "Waiting for application to start... (Attempt $attempt/$maxAttempts)"
            Start-Sleep 5
        }
    } while ($attempt -lt $maxAttempts)
    
    return $false
}

# Show application status
function Show-ApplicationStatus {
    Log-Step "Application Status"
    
    Write-Host "`n🌐 Application URLs:" -ForegroundColor $Cyan
    Write-Host "   Frontend: http://localhost:8080" -ForegroundColor $White
    Write-Host "   Health Check: http://localhost:8080/health" -ForegroundColor $White
    Write-Host "   Status: http://localhost:8080/status" -ForegroundColor $White
    
    Write-Host "`n🐳 Docker Containers:" -ForegroundColor $Cyan
    docker ps --filter "name=guestbook"
    
    Write-Host "`n📝 Useful Commands:" -ForegroundColor $Cyan
    Write-Host "   View logs: docker logs guestbook-frontend" -ForegroundColor $White
    Write-Host "   Stop app: docker stop guestbook-frontend guestbook-redis" -ForegroundColor $White
    Write-Host "   Remove app: docker rm guestbook-frontend guestbook-redis" -ForegroundColor $White
    Write-Host "   Restart app: .\scripts\install-and-run.ps1" -ForegroundColor $White
    
    Write-Host "`n🎉 SUCCESS! Your Kubernetes Guestbook Modernized application is running!" -ForegroundColor $Green
    Write-Host "Open http://localhost:8080 in your browser to see the application." -ForegroundColor $Yellow
}

# Main execution
function Start-CompleteSetup {
    Write-Host "`n🚀 KUBERNETES GUESTBOOK MODERNIZED - COMPLETE SETUP" -ForegroundColor $Blue
    Write-Host "=================================================" -ForegroundColor $Blue
    
    # Check if running as Administrator
    if (!(Test-Administrator)) {
        Log-Error "This script requires Administrator privileges. Please run PowerShell as Administrator."
        exit 1
    }
    
    # Install Chocolatey
    Install-Chocolatey
    
    # Install required tools
    Install-RequiredTools
    
    # Wait for Docker to start
    if (!(Wait-ForDocker)) {
        Log-Error "Docker failed to start. Please start Docker Desktop manually and try again."
        exit 1
    }
    
    # Start local development
    if (Start-LocalDevelopment) {
        Show-ApplicationStatus
    } else {
        Log-Error "Failed to start the application. Check the logs above for details."
        exit 1
    }
}

# Run the complete setup
Start-CompleteSetup
