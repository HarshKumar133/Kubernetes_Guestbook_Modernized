# Kubernetes Guestbook Modernized - Variables
# This file defines all the input variables for our Terraform configuration

# Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "guestbook-modernized"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# Region and Zone Configuration
variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "Region must be a valid GCP region format."
  }
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "Zone must be a valid GCP zone format."
  }
}

# Network Configuration
variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.0.0/24"
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "pods_cidr" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.1.0.0/16"
  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "Pods CIDR must be a valid IPv4 CIDR block."
  }
}

variable "services_cidr" {
  description = "CIDR block for services"
  type        = string
  default     = "10.2.0.0/20"
  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "Services CIDR must be a valid IPv4 CIDR block."
  }
}

variable "master_cidr" {
  description = "CIDR block for the master"
  type        = string
  default     = "172.16.0.0/28"
  validation {
    condition     = can(cidrhost(var.master_cidr, 0))
    error_message = "Master CIDR must be a valid IPv4 CIDR block."
  }
}

# Cluster Configuration
variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 1
  validation {
    condition     = var.min_node_count >= 1
    error_message = "Minimum node count must be at least 1."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
  validation {
    condition     = var.max_node_count >= var.min_node_count
    error_message = "Maximum node count must be greater than or equal to minimum node count."
  }
}

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-medium"
  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+$", var.machine_type))
    error_message = "Machine type must be a valid GCP machine type."
  }
}

variable "disk_size_gb" {
  description = "Size of the disk in GB"
  type        = number
  default     = 50
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 1000
    error_message = "Disk size must be between 10 and 1000 GB."
  }
}

# Node Taints (for specialized workloads)
variable "node_taints" {
  description = "List of taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring and logging"
  type        = bool
  default     = true
}

variable "enable_managed_prometheus" {
  description = "Enable Google Managed Prometheus"
  type        = bool
  default     = true
}

# Security Configuration
variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable binary authorization"
  type        = bool
  default     = true
}

# Cost Management
variable "enable_cost_management" {
  description = "Enable cost management features"
  type        = bool
  default     = true
}

# Maintenance Window
variable "maintenance_start_time" {
  description = "Start time for maintenance window (HH:MM format)"
  type        = string
  default     = "02:00"
  validation {
    condition     = can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_start_time))
    error_message = "Maintenance start time must be in HH:MM format."
  }
}

variable "maintenance_end_time" {
  description = "End time for maintenance window (HH:MM format)"
  type        = string
  default     = "06:00"
  validation {
    condition     = can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_end_time))
    error_message = "Maintenance end time must be in HH:MM format."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "Kubernetes Guestbook Modernized"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
