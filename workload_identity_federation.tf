resource "google_iam_workload_identity_pool" "github_actions_pool" {
  depends_on = [google_project_service.active_api]

  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"
  disabled                           = false

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.event_name" = "assertion.event_name"
  }

  attribute_condition = "attribute.repository != ''"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

// GitHub SA Deployer

resource "google_service_account" "github_sa_deployer" {
  depends_on = [google_project_service.active_api]

  account_id   = "github-actions-sa-deployer"
  display_name = "Service Account for GitHub Actions Deployer"
}

resource "google_service_account_iam_binding" "deployer_allow_wif_impersonation" {
  service_account_id = google_service_account.github_sa_deployer.id
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id}/attribute.repository/${local.deployer_repo}"
  ]
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
  display_name = "Service Account for GitHub Actions Builder"
}

resource "google_service_account_iam_binding" "builder_allow_wif_impersonation" {
  service_account_id = google_service_account.github_sa_builder.id
  role               = "roles/iam.workloadIdentityUser"
  members = [
    for repo in local.builder_repos :
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id}/attribute.repository/${repo}"
  ]
}

resource "google_service_account_iam_binding" "builder_allow_token_creator" {
  service_account_id = google_service_account.github_sa_builder.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members = [
    for repo in local.builder_repos :
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id}/attribute.repository/${repo}"
  ]
}

resource "google_project_iam_member" "github_sa_builder_permission" {
  for_each = toset(local.builder_roles)

  project = data.google_client_config.provider.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_sa_builder.email}"
}

// GitHub SA Deployer Elevated Privileges

resource "google_service_account" "github_sa_deployer_ep" {
  depends_on = [google_project_service.active_api]

  account_id   = "github-actions-sa-deployer-ep"
  display_name = "Service Account for GitHub Actions Deployer"
}

resource "google_service_account_iam_binding" "deployer_ep_allow_wif_impersonation" {
  service_account_id = google_service_account.github_sa_deployer_ep.id
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id}/attribute.repository/${local.deployer_repo}"
  ]

  condition {
    title      = "Is triggered by terraform manager"
    expression = "actor in [\"alvaromanoso\"] && event_name == \"workflow_dispatch\""
  }
}

resource "google_project_iam_member" "github_sa_deployer_ep_permission" {
  project = data.google_client_config.provider.project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.github_sa_deployer_ep.email}"
}

locals {
  deployer_repo = "AutoInvestor/infra-gitops"
  deployer_roles = [
    "roles/editor",
    "roles/secretmanager.secretAccessor"
  ]

  builder_repos = [
    "AutoInvestor/infra-gitops",
    "AutoInvestor/api-gateway",
    "AutoInvestor/market-feeling",
    "AutoInvestor/core",
    "AutoInvestor/users",
    "AutoInvestor/frontend",
    "AutoInvestor/news-scraper",
    "AutoInvestor/portfolio",
    "AutoInvestor/decision-making",
    "AutoInvestor/alerts",
  ]
  builder_roles = [
    "roles/artifactregistry.writer",
  ]
}
