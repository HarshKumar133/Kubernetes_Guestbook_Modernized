#!/bin/sh
# Redis Health Check Script
# This script checks if Redis is healthy and responding to commands

set -e

# Redis connection parameters
REDIS_HOST=${REDIS_HOST:-localhost}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-}

# Function to check Redis connectivity
check_redis_connectivity() {
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" ping > /dev/null 2>&1
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1
    fi
}

# Function to check Redis memory usage
check_redis_memory() {
    if [ -n "$REDIS_PASSWORD" ]; then
        MEMORY_USAGE=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
    else
        MEMORY_USAGE=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
    fi
    
    echo "Redis memory usage: $MEMORY_USAGE"
}

# Function to check Redis replication status
check_redis_replication() {
    if [ -n "$REDIS_PASSWORD" ]; then
        REPLICATION_STATUS=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" info replication | grep role | cut -d: -f2 | tr -d '\r')
    else
        REPLICATION_STATUS=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" info replication | grep role | cut -d: -f2 | tr -d '\r')
    fi
    
    echo "Redis role: $REPLICATION_STATUS"
}

# Main health check
main() {
    echo "Starting Redis health check..."
    
    # Check connectivity
    if check_redis_connectivity; then
        echo "✅ Redis is responding to ping"
    else
        echo "❌ Redis is not responding to ping"
        exit 1
    fi
    
    # Check memory usage
    check_redis_memory
    
    # Check replication status
    check_redis_replication
    
    # Additional checks
    if [ -n "$REDIS_PASSWORD" ]; then
        # Check if Redis is accepting commands
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" set health_check "ok" > /dev/null 2>&1
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" del health_check > /dev/null 2>&1
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" set health_check "ok" > /dev/null 2>&1
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" del health_check > /dev/null 2>&1
    fi
    
    echo "✅ Redis health check passed"
    exit 0
}

# Run main function
main "$@"
