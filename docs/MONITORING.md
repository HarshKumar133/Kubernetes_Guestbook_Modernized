# Monitoring Guide

## Overview

The Kubernetes Guestbook Modernized application includes comprehensive monitoring with Prometheus, Grafana, and custom dashboards for application performance tracking.

## Monitoring Stack

### Prometheus
- **Purpose**: Metrics collection and storage
- **Configuration**: `monitoring/prometheus/prometheus.yml`
- **Scrape Interval**: 15 seconds
- **Retention**: 30 days

### Grafana
- **Purpose**: Visualization and dashboards
- **Dashboards**: Custom guestbook dashboards
- **Refresh Rate**: 30 seconds
- **Authentication**: LDAP/Google OAuth

### Alerting
- **AlertManager**: Handles alert routing
- **Channels**: Slack, email, PagerDuty
- **Rules**: Comprehensive alerting rules

## Metrics Collection

### Application Metrics
- **Request Rate**: HTTP requests per second
- **Response Time**: 50th, 95th, 99th percentiles
- **Error Rate**: 4xx and 5xx error rates
- **Active Connections**: Current connections

### Infrastructure Metrics
- **CPU Usage**: Node and container CPU
- **Memory Usage**: Node and container memory
- **Disk Usage**: Disk space utilization
- **Network**: Network I/O and errors

### Business Metrics
- **Message Count**: Total messages in guestbook
- **User Sessions**: Active user sessions
- **Page Views**: Page view statistics

## Dashboards

### Guestbook Overview
- **Purpose**: High-level application status
- **Panels**: Status, request rate, response time, errors
- **Refresh**: 30 seconds

### Infrastructure Overview
- **Purpose**: Cluster and node health
- **Panels**: Node status, resource usage, pod health
- **Refresh**: 30 seconds

### Redis Monitoring
- **Purpose**: Redis performance and health
- **Panels**: Memory usage, connections, commands
- **Refresh**: 30 seconds

## Alerting Rules

### Critical Alerts
- **Application Down**: Up == 0 for 1 minute
- **High Error Rate**: 5xx errors > 10% for 2 minutes
- **Pod Crash Looping**: Restart rate > 0 for 5 minutes
- **Redis Down**: Redis up == 0 for 1 minute

### Warning Alerts
- **High CPU Usage**: CPU > 80% for 5 minutes
- **High Memory Usage**: Memory > 80% for 5 minutes
- **High Latency**: 95th percentile > 1s for 5 minutes
- **High Request Rate**: Requests > 100/s for 5 minutes

### Info Alerts
- **Low Message Count**: Messages < 1 for 10 minutes
- **High Message Count**: Messages > 1000 for 5 minutes

## Accessing Monitoring

### Prometheus
```bash
# Port forward to access Prometheus
kubectl port-forward svc/prometheus-server -n monitoring 9090:80

# Access at http://localhost:9090
```

### Grafana
```bash
# Port forward to access Grafana
kubectl port-forward svc/grafana -n monitoring 3000:80

# Access at http://localhost:3000
# Default credentials: admin/admin
```

### AlertManager
```bash
# Port forward to access AlertManager
kubectl port-forward svc/alertmanager -n monitoring 9093:80

# Access at http://localhost:9093
```

## Custom Metrics

### Application Metrics
```php
// Example PHP metrics
$redis->incr('guestbook:requests:total');
$redis->hincrby('guestbook:metrics', 'messages:created', 1);
```

### Redis Metrics
```bash
# Redis info command for metrics
redis-cli info memory
redis-cli info stats
redis-cli info replication
```

## Logging

### Application Logs
- **Location**: `/var/log/nginx/access.log`
- **Format**: Combined log format
- **Rotation**: Daily rotation

### Error Logs
- **Location**: `/var/log/nginx/error.log`
- **Level**: Error and above
- **Rotation**: Daily rotation

### System Logs
- **Location**: `/var/log/syslog`
- **Format**: Syslog format
- **Rotation**: Weekly rotation

## Troubleshooting

### Common Issues

#### Metrics Not Appearing
```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
# Go to Status > Targets in Prometheus UI
```

#### Alerts Not Firing
```bash
# Check alert rules
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
# Go to Alerts in Prometheus UI
```

#### Dashboard Not Loading
```bash
# Check Grafana logs
kubectl logs deployment/grafana -n monitoring

# Check Prometheus connectivity
kubectl exec -it deployment/grafana -n monitoring -- curl prometheus-server:80
```

### Performance Tuning

#### Prometheus
- **Scrape Interval**: Adjust based on needs
- **Retention**: Balance storage vs. history
- **Memory**: Increase for large clusters

#### Grafana
- **Refresh Rate**: Adjust based on needs
- **Dashboard Queries**: Optimize for performance
- **Caching**: Enable query result caching

## Best Practices

### Monitoring
- **SLIs**: Define Service Level Indicators
- **SLOs**: Set Service Level Objectives
- **Error Budgets**: Track error budgets
- **Runbooks**: Document response procedures

### Alerting
- **Thresholds**: Set appropriate thresholds
- **Escalation**: Define escalation procedures
- **Runbooks**: Document alert responses
- **Testing**: Regularly test alerting

### Dashboards
- **Relevance**: Keep dashboards relevant
- **Performance**: Optimize query performance
- **Documentation**: Document dashboard purpose
- **Maintenance**: Regular maintenance and updates
