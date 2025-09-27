# Redis Dockerfile for Guestbook Application
# This creates a production-ready Redis container with security and monitoring

FROM redis:7.2-alpine

# Set maintainer
LABEL maintainer="DevOps Team <devops@company.com>"
LABEL description="Redis server for Kubernetes Guestbook Modernized"
LABEL version="1.0.0"

# Create redis user and group
RUN addgroup -g 999 redis && \
    adduser -D -s /bin/sh -u 999 -G redis redis

# Create necessary directories
RUN mkdir -p /data /logs && \
    chown -R redis:redis /data /logs

# Copy custom Redis configuration
COPY redis.conf /usr/local/etc/redis/redis.conf

# Copy health check script
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Switch to redis user
USER redis

# Expose Redis port
EXPOSE 6379

# Set health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Start Redis server
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
