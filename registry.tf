resource "google_artifact_registry_repository" "helm_repo" {
  depends_on = [google_project_service.active_api]

  location           = data.google_client_config.provider.region
  repository_id      = "helm-charts"
  description        = "Helm chart repository"
  format             = "HELM"
  mode               = "STANDARD_REPOSITORY"
}