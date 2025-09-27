# Local Development Setup for Kubernetes Guestbook Modernized
# This script sets up the application for local development using Docker

Write-Host "🚀 Setting up Kubernetes Guestbook Modernized for local development..." -ForegroundColor Green

# Check if Docker is running
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Create local environment file
Write-Host "📝 Creating local environment configuration..." -ForegroundColor Yellow
$envContent = @"
# Local Development Environment
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=dev-redis-password
PHP_MEMORY_LIMIT=128M
PHP_MAX_EXECUTION_TIME=30
APP_ENV=development
APP_DEBUG=true
LOG_LEVEL=debug
"@
$envContent | Out-File -FilePath "applications\frontend\.env" -Encoding UTF8

# Build and run Redis
Write-Host "🔧 Building and starting Redis..." -ForegroundColor Yellow
Push-Location applications\redis
try {
    docker build -t guestbook-redis:latest .
    docker run -d --name guestbook-redis -p 6379:6379 -e REDIS_PASSWORD=dev-redis-password guestbook-redis:latest
    Write-Host "✅ Redis started successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to start Redis: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
finally {
    Pop-Location
}

# Build and run Frontend
Write-Host "🔧 Building and starting Frontend..." -ForegroundColor Yellow
Push-Location applications\frontend
try {
    docker build -t guestbook-frontend:latest .
    docker run -d --name guestbook-frontend -p 8080:80 --link guestbook-redis:redis -e REDIS_HOST=redis -e REDIS_PASSWORD=dev-redis-password guestbook-frontend:latest
    Write-Host "✅ Frontend started successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to start Frontend: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
finally {
    Pop-Location
}

# Wait for services to be ready
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep 10

# Test the application
Write-Host "🧪 Testing the application..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Health check passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Health check failed with status: $($response.StatusCode)" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
}

# Show application status
Write-Host "`n📊 Application Status:" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:8080" -ForegroundColor White
Write-Host "Health Check: http://localhost:8080/health" -ForegroundColor White
Write-Host "Status: http://localhost:8080/status" -ForegroundColor White

Write-Host "`n🐳 Docker Containers:" -ForegroundColor Cyan
docker ps --filter "name=guestbook"

Write-Host "`n📝 Useful Commands:" -ForegroundColor Cyan
Write-Host "View logs: docker logs guestbook-frontend" -ForegroundColor White
Write-Host "Stop app: docker stop guestbook-frontend guestbook-redis" -ForegroundColor White
Write-Host "Remove app: docker rm guestbook-frontend guestbook-redis" -ForegroundColor White
Write-Host "Restart app: .\scripts\local-dev.ps1" -ForegroundColor White

Write-Host "`n✅ Local development setup completed!" -ForegroundColor Green
Write-Host "Open http://localhost:8080 in your browser to see the application." -ForegroundColor Yellow