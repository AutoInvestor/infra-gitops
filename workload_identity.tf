provider "kubernetes" {
  host  = "https://${google_container_cluster.primary.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}

resource "google_service_account" "kubernetes_apps_sa" {
  depends_on = [google_project_service.active_api]

  account_id   = "kubernetes-apps-sa"
  display_name = "Kubernetes Apps Service Account"
}

resource "google_project_iam_member" "kubernetes_apps_sa_role" {
  for_each = toset(local.kubernetes_apps_sa_roles)

  project = data.google_client_config.provider.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.kubernetes_apps_sa.email}"
}

resource "kubernetes_namespace" "autoinvestor" {
  depends_on = [google_container_cluster.primary]

  metadata {
    name = "autoinvestor"
  }
}

resource "kubernetes_service_account" "kubernetes_apps_sa" {
  depends_on = [google_container_cluster.primary]

  metadata {
    name      = "kubernetes-apps-sa"
    namespace = kubernetes_namespace.autoinvestor.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.kubernetes_apps_sa.email
    }
  }
}

resource "google_service_account_iam_binding" "kubernetes_apps_sa_binding" {
  service_account_id = google_service_account.kubernetes_apps_sa.id

  role = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${google_container_cluster.primary.workload_identity_config[0].workload_pool}[${kubernetes_service_account.kubernetes_apps_sa.metadata[0].namespace}/${kubernetes_service_account.kubernetes_apps_sa.metadata[0].name}]"
  ]
}

locals {
  kubernetes_apps_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/pubsub.subscriber",
    "roles/pubsub.publisher",
  ]
}