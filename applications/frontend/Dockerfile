# PHP Frontend Dockerfile for Guestbook Application
# This creates a production-ready PHP container with security and performance optimizations

FROM php:8.2-fpm-alpine

# Set maintainer
LABEL maintainer="DevOps Team <devops@company.com>"
LABEL description="PHP frontend for Kubernetes Guestbook Modernized"
LABEL version="1.0.0"

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    redis \
    curl \
    bash \
    tzdata \
    && rm -rf /var/cache/apk/*

# Install PHP extensions
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-install pdo pdo_mysql opcache \
    && docker-php-ext-enable opcache

# Configure PHP
COPY php.ini /usr/local/etc/php/php.ini
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Configure Nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/http.d/default.conf

# Configure Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create application directory
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Copy application code
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html

# Create necessary directories
RUN mkdir -p /var/log/nginx /var/log/php-fpm /var/run/nginx /var/run/php-fpm && \
    chown -R www-data:www-data /var/log/nginx /var/log/php-fpm /var/run/nginx /var/run/php-fpm

# Copy health check script
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Expose port
EXPOSE 80

# Set health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
