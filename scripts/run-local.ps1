# Run Kubernetes Guestbook Modernized Locally
# This script builds and runs the application using Docker

Write-Host "🚀 Starting Kubernetes Guestbook Modernized - Local Development" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

# Wait for Docker to be ready
Write-Host "`n⏳ Waiting for Docker to start..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0

do {
    $attempt++
    Write-Host "Checking Docker... (Attempt $attempt/$maxAttempts)" -ForegroundColor Cyan
    Start-Sleep 5
    
    try {
        docker version | Out-Null
        Write-Host "✅ Docker is ready!" -ForegroundColor Green
        break
    }
    catch {
        if ($attempt -eq $maxAttempts) {
            Write-Host "❌ Docker failed to start. Please start Docker Desktop manually and try again." -ForegroundColor Red
            exit 1
        }
    }
} while ($attempt -lt $maxAttempts)

# Create environment file
Write-Host "`n📝 Creating environment configuration..." -ForegroundColor Yellow
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
$envContent | Out-File -FilePath "applications\frontend\.env" -Encoding UTF8 -Force

# Stop any existing containers
Write-Host "`n🧹 Cleaning up existing containers..." -ForegroundColor Yellow
docker stop guestbook-frontend guestbook-redis 2>$null
docker rm guestbook-frontend guestbook-redis 2>$null

# Build and run Redis
Write-Host "`n🔧 Building and starting Redis..." -ForegroundColor Yellow
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
Write-Host "`n🔧 Building and starting Frontend..." -ForegroundColor Yellow
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
Write-Host "`n⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep 15

# Test the application
Write-Host "`n🧪 Testing the application..." -ForegroundColor Yellow
$maxAttempts = 10
$attempt = 0

do {
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Application is running successfully!" -ForegroundColor Green
            break
        }
    }
    catch {
        if ($attempt -eq $maxAttempts) {
            Write-Host "❌ Application failed to start after $maxAttempts attempts" -ForegroundColor Red
            Write-Host "Check logs with: docker logs guestbook-frontend" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "Waiting for application to start... (Attempt $attempt/$maxAttempts)" -ForegroundColor Cyan
        Start-Sleep 5
    }
} while ($attempt -lt $maxAttempts)

# Show application status
Write-Host "`n📊 APPLICATION STATUS" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

Write-Host "`n🌐 Application URLs:" -ForegroundColor White
Write-Host "   Frontend: http://localhost:8080" -ForegroundColor Green
Write-Host "   Health Check: http://localhost:8080/health" -ForegroundColor Green
Write-Host "   Status: http://localhost:8080/status" -ForegroundColor Green

Write-Host "`n🐳 Docker Containers:" -ForegroundColor White
docker ps --filter "name=guestbook"

Write-Host "`n📝 Useful Commands:" -ForegroundColor White
Write-Host "   View logs: docker logs guestbook-frontend" -ForegroundColor Yellow
Write-Host "   Stop app: docker stop guestbook-frontend guestbook-redis" -ForegroundColor Yellow
Write-Host "   Remove app: docker rm guestbook-frontend guestbook-redis" -ForegroundColor Yellow
Write-Host "   Restart app: .\scripts\run-local.ps1" -ForegroundColor Yellow

Write-Host "`n🎉 SUCCESS! Your Kubernetes Guestbook Modernized application is running!" -ForegroundColor Green
Write-Host "Open http://localhost:8080 in your browser to see the application." -ForegroundColor Yellow
Write-Host "`nPress any key to open the application in your browser..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Start-Process "http://localhost:8080"
