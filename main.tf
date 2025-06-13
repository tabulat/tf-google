module "gke_cluster" {
  source         = "github.com/tabulat/tf-google"
  GOOGLE_REGION  = var.GOOGLE_REGION
  GOOGLE_PROJECT = var.GOOGLE_PROJECT
  GKE_NUM_NODES  = 2
}

# Configure the Google Cloud provider
provider "google" {
  project = var.GOOGLE_PROJECT
  region  = var.GOOGLE_REGION
}

# Create the GKE (Google Kubernetes Engine) cluster
resource "google_container_cluster" "this" {
  name     = var.GKE_CLUSTER_NAME
  location = var.GOOGLE_REGION

  initial_node_count       = 1
  remove_default_node_pool = true

  # Workload Identity configuration for GKE
  workload_identity_config {
    workload_pool = "${var.GOOGLE_PROJECT}.svc.id.goog"
  }

  # Node configuration for metadata
  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# Create a custom node pool for the GKE cluster
resource "google_container_node_pool" "this" {
  # Name of the node pool
  name       = var.GKE_POOL_NAME
  # GCP project to use (derived from the cluster)
  project    = google_container_cluster.this.project
  # Attach node pool to the created cluster
  cluster    = google_container_cluster.this.name
  # Location (region)
  location   = google_container_cluster.this.location
  # Number of nodes in the pool
  node_count = var.GKE_NUM_NODES

  # Node configuration
  node_config {
    # Machine type for the nodes
    machine_type = var.GKE_MACHINE_TYPE
  }
}

# Module to authenticate with GKE cluster using native Terraform module
module "gke_auth" {
  depends_on = [
    google_container_cluster.this
  ]
  # Source of the module (Terraform Registry)
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version      = ">= 24.0.0"
  # Project and cluster details for authentication
  project_id   = var.GOOGLE_PROJECT
  cluster_name = google_container_cluster.this.name
  location     = var.GOOGLE_REGION
}

# Data source to retrieve the current Google client configuration
data "google_client_config" "current" {}

# Data source to fetch details about the created GKE cluster
data "google_container_cluster" "main" {
  name     = google_container_cluster.this.name
  location = var.GOOGLE_REGION
}
