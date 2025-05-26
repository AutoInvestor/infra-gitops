resource "google_secret_manager_secret" "mongodb_uri" {
  depends_on = [google_project_service.active_api]

  secret_id = "mongodb-uri"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "okta_client_secret" {
  depends_on = [google_project_service.active_api]

  secret_id = "okta-client-secret"

  replication {
    auto {}
  }
}