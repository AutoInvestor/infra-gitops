resource "google_iam_workload_identity_pool" "github_pool" {
  depends_on = [google_project_service.active_api]

  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

// GitHub SA Deployer

resource "google_service_account" "github_sa_deployer" {
  depends_on = [google_project_service.active_api]

  account_id   = "github-actions-sa-deployer"
  display_name = "Service Account for GitHub Actions Project Manager"
}

resource "google_service_account_iam_binding" "deployer_allow_wif_impersonation" {
  service_account_id = google_service_account.github_sa_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}"
  ]

  condition {
    title       = "Limit to trusted repos"
    description = "Only allow specific GitHub repos"
    expression  = "attribute.repository == '${local.deployer_repo}'"
  }
}

resource "google_project_iam_member" "github_sa_deployer_permission" {
  for_each = toset(local.deployer_roles)

  project = data.google_client_config.provider.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_sa_deployer.email}"
}

// GitHub SA Builder

resource "google_service_account" "github_sa_builder" {
  depends_on = [google_project_service.active_api]

  account_id   = "github-actions-sa-builder"
  display_name = "Service Account for GitHub Actions Artifact Publisher"
}

resource "google_service_account_iam_binding" "builder_allow_wif_impersonation" {
  service_account_id = google_service_account.github_sa_builder.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}"
  ]

  condition {
    title       = "Limit to trusted repos"
    description = "Only allow specific GitHub repos"
    expression = join(" || ", [
      for repo in local.builder_repos :
      "attribute.repository == '${repo}'"
    ])
  }
}

resource "google_project_iam_member" "github_sa_builder_permission" {
  for_each = toset(local.builder_roles)

  project = data.google_client_config.provider.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_sa_builder.email}"
}

locals {
  deployer_repo = "autoinvestor/infra-gitops"
  deployer_roles = [
    "roles/editor",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ]

  builder_repos = [
    "autoinvestor/infra-gitops",
    "autoinvestor/api-gateway",
    "autoinvestor/market-feeling",
    "autoinvestor/core",
    "autoinvestor/users",
    "autoinvestor/frontend",
    "autoinvestor/news-scraper",
    "autoinvestor/portfolio",
    "autoinvestor/decision-making",
    "autoinvestor/alerts",
  ]
  builder_roles = [
    "roles/artifactregistry.writer"
  ]
}
