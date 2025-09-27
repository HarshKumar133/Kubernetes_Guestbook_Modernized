# Kubernetes Guestbook Modernized - Main Terraform Configuration
# This file defines the core infrastructure components for our GKE cluster

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com"
  ])

  service = each.value
  disable_on_destroy = false
}

# Create VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.required_apis]
}

# Create Subnet
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  # Enable private Google access for GKE nodes
  private_ip_google_access = true

  # Secondary ranges for pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# Create Cloud Router for NAT Gateway
resource "google_compute_router" "main" {
  name    = "${var.project_name}-router"
  region  = var.region
  network = google_compute_network.main.id
}

# Create NAT Gateway for outbound internet access
resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-nat"
  router                            = google_compute_router.main.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Create GKE Cluster
resource "google_container_cluster" "main" {
  name     = "${var.project_name}-cluster"
  location = var.zone
  project  = var.project_id

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.main.name

  # Enable private cluster
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Master authorized networks (for private cluster access)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }

  # Enable network policy
  network_policy {
    enabled = true
  }

  # Enable workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Enable cost management
  cost_management_config {
    enabled = true
  }

  # Enable cluster autoscaling
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 10
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 100
    }
  }

  # Enable vertical pod autoscaling
  vertical_pod_autoscaling {
    enabled = true
  }

  # Enable horizontal pod autoscaling
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
  }

  # Enable monitoring and logging
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Release channel for automatic updates
  release_channel {
    channel = "REGULAR"
  }

  # Maintenance window
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T02:00:00Z"
      end_time   = "2023-01-01T06:00:00Z"
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_compute_subnetwork.main
  ]
}

# Create Node Pool
resource "google_container_node_pool" "main" {
  name       = "${var.project_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.main.name
  node_count = var.node_count

  node_config {
    # Machine type
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-ssd"

    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Service account
    service_account = google_service_account.gke_node.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enable secure boot
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Image type
    image_type = "COS_CONTAINERD"

    # Labels
    labels = {
      environment = var.environment
      project     = var.project_name
    }

    # Taints (if needed)
    dynamic "taint" {
      for_each = var.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  depends_on = [google_container_cluster.main]
}

# Create Service Account for GKE nodes
resource "google_service_account" "gke_node" {
  account_id   = "${var.project_name}-gke-node"
  display_name = "GKE Node Service Account"
  description  = "Service account for GKE nodes"
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "gke_node_permissions" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

# Create Artifact Registry for container images
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "${var.project_name}-registry"
  description   = "Container registry for ${var.project_name}"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}

# Create Cloud Storage bucket for Terraform state
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_name}-terraform-state-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Output important values
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

output "project_id" {
  description = "Google Cloud Project ID"
  value       = var.project_id
}

output "registry_url" {
  description = "URL of the Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}
