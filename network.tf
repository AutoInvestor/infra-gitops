resource "google_compute_global_address" "global_address_ip" {
  depends_on = [google_project_service.active_api]

  name = "global-address-ip"
}
