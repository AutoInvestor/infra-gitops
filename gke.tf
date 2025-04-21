locals {
  gke_nodes_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/pubsub.subscriber",
    "roles/pubsub.publisher",
  ]
}

resource "google_service_account" "gke_nodes_sa" {
  account_id   = "gke-nodes-service-account"
  display_name = "GKE Nodes Service Account"
}

resource "google_project_iam_member" "gke_nodes_sa_role" {
  for_each = toset(local.gke_nodes_sa_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

resource "kubernetes_service_account" "gke_nodes_ksa" {
  metadata {
    name      = "gke-nodes-kubernetes-service-account"
    namespace = "autoinvestor"
  }
}

resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.gke_zone

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  maintenance_policy {
    daily_maintenance_window {
      start_time = "01:00"
    }
  }
}

resource "google_service_account_iam_binding" "gke_nodes_sa_ksa_binding" {
  service_account_id = google_service_account.gke_nodes_sa.id

  role = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${google_container_cluster.primary.workload_identity_config[0].workload_pool}[${kubernetes_service_account.gke_nodes_ksa.metadata[0].namespace}/${kubernetes_service_account.gke_nodes_ksa.metadata[0].name}]"
  ]
}

resource "google_container_node_pool" "primary_default_pool" {
  name       = "default-pool"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-small"

    service_account = google_service_account.gke_nodes_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

data "google_client_config" "provider" {}

provider "kubernetes" {
  host  = "https://${google_container_cluster.primary.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}