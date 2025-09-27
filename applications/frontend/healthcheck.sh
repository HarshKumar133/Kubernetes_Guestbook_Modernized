#!/bin/sh
# Frontend Health Check Script
# This script checks if the frontend application is healthy and responding

set -e

# Configuration
FRONTEND_HOST=${FRONTEND_HOST:-localhost}
FRONTEND_PORT=${FRONTEND_PORT:-80}
HEALTH_ENDPOINT="/health"
STATUS_ENDPOINT="/status"

# Function to check HTTP response
check_http_response() {
    local url="http://${FRONTEND_HOST}:${FRONTEND_PORT}${1}"
    local expected_status=${2:-200}
    
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
    
    if [ "$status_code" = "$expected_status" ]; then
        return 0
    else
        echo "HTTP check failed: expected $expected_status, got $status_code"
        return 1
    fi
}

# Function to check if the application is responding
check_application_response() {
    local url="http://${FRONTEND_HOST}:${FRONTEND_PORT}/"
    local response=$(curl -s -f "$url" || echo "ERROR")
    
    if echo "$response" | grep -q "Kubernetes Guestbook Modernized"; then
        return 0
    else
        echo "Application check failed: page content not as expected"
        return 1
    fi
}

# Function to check PHP-FPM status
check_php_fpm() {
    if pgrep -f "php-fpm" > /dev/null; then
        return 0
    else
        echo "PHP-FPM check failed: process not running"
        return 1
    fi
}

# Function to check Nginx status
check_nginx() {
    if pgrep -f "nginx" > /dev/null; then
        return 0
    else
        echo "Nginx check failed: process not running"
        return 1
    fi
}

# Main health check
main() {
    echo "Starting frontend health check..."
    
    # Check Nginx
    if check_nginx; then
        echo "✅ Nginx is running"
    else
        echo "❌ Nginx is not running"
        exit 1
    fi
    
    # Check PHP-FPM
    if check_php_fpm; then
        echo "✅ PHP-FPM is running"
    else
        echo "❌ PHP-FPM is not running"
        exit 1
    fi
    
    # Check health endpoint
    if check_http_response "$HEALTH_ENDPOINT" 200; then
        echo "✅ Health endpoint is responding"
    else
        echo "❌ Health endpoint is not responding"
        exit 1
    fi
    
    # Check status endpoint
    if check_http_response "$STATUS_ENDPOINT" 200; then
        echo "✅ Status endpoint is responding"
    else
        echo "❌ Status endpoint is not responding"
        exit 1
    fi
    
    # Check application response
    if check_application_response; then
        echo "✅ Application is responding correctly"
    else
        echo "❌ Application is not responding correctly"
        exit 1
    fi
    
    echo "✅ Frontend health check passed"
    exit 0
}

# Run main function
main "$@"
