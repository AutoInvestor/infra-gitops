resource "google_container_cluster" "primary" {
  depends_on = [google_project_service.active_api]

  name     = var.gke_cluster_name
  location = var.gke_zone

  workload_identity_config {
    workload_pool = "${data.google_client_config.provider.project}.svc.id.goog"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  maintenance_policy {
    daily_maintenance_window {
      start_time = "01:00"
    }
  }
}

resource "google_container_node_pool" "primary_default_pool" {
  name       = "default-pool"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-medium"

    service_account = google_service_account.gke_nodes_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_service_account" "gke_nodes_sa" {
  depends_on = [google_project_service.active_api]

  account_id   = "gke-nodes-service-account"
  display_name = "GKE Nodes Service Account"
}

resource "google_project_iam_member" "gke_nodes_sa_role" {
  for_each = toset(local.gke_nodes_sa_roles)

  project = data.google_client_config.provider.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

locals {
  gke_nodes_sa_roles = [
    "roles/container.nodeServiceAccount",
    "roles/artifactregistry.reader",
  ]
}