resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.gke_zone

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_default_pool" {
  name       = "default-pool"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-small"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
