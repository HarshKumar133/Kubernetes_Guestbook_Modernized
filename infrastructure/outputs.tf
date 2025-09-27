# Kubernetes Guestbook Modernized - Outputs
# This file defines the outputs from our Terraform configuration

# Cluster Information
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "cluster_zone" {
  description = "Zone of the GKE cluster"
  value       = google_container_cluster.main.location
}

# Network Information
output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.main.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = google_compute_network.main.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = google_compute_subnetwork.main.id
}

output "subnet_cidr" {
  description = "CIDR block of the subnet"
  value       = google_compute_subnetwork.main.ip_cidr_range
}

# Node Pool Information
output "node_pool_name" {
  description = "Name of the node pool"
  value       = google_container_node_pool.main.name
}

output "node_pool_instance_group_urls" {
  description = "Instance group URLs of the node pool"
  value       = google_container_node_pool.main.instance_group_urls
}

# Service Account Information
output "gke_node_service_account" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_node.email
}

# Artifact Registry Information
output "artifact_registry_url" {
  description = "URL of the Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "artifact_registry_name" {
  description = "Name of the Artifact Registry"
  value       = google_artifact_registry_repository.main.name
}

# Storage Information
output "terraform_state_bucket" {
  description = "Name of the Terraform state bucket"
  value       = google_storage_bucket.terraform_state.name
}

# Connection Information
output "kubectl_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --zone ${google_container_cluster.main.location} --project ${var.project_id}"
}

output "helm_command" {
  description = "Command to add the Helm repository"
  value       = "helm repo add stable https://charts.helm.sh/stable"
}

# Monitoring Information
output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "prometheus_enabled" {
  description = "Whether Prometheus is enabled"
  value       = var.enable_managed_prometheus
}

# Security Information
output "network_policy_enabled" {
  description = "Whether network policy is enabled"
  value       = var.enable_network_policy
}

output "workload_identity_enabled" {
  description = "Whether workload identity is enabled"
  value       = var.enable_workload_identity
}

output "binary_authorization_enabled" {
  description = "Whether binary authorization is enabled"
  value       = var.enable_binary_authorization
}

# Cost Information
output "cost_management_enabled" {
  description = "Whether cost management is enabled"
  value       = var.enable_cost_management
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_id" {
  description = "Google Cloud Project ID"
  value       = var.project_id
}

output "region" {
  description = "Google Cloud region"
  value       = var.region
}

output "zone" {
  description = "Google Cloud zone"
  value       = var.zone
}
