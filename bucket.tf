resource "google_storage_bucket" "tfstate" {
  depends_on = [google_project_service.active_api]

  name          = "terraform-state-autoinvestor"
  location      = data.google_client_config.provider.region
  storage_class = "STANDARD"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}