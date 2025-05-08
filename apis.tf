resource "google_project_service" "active_api" {
  for_each = toset(local.active_apis)

  project = data.google_client_config.provider.project
  service = each.key

  disable_on_destroy = false
}

locals {
  active_apis = [
    "container.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]
}