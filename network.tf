resource "google_compute_global_address" "frontend-address" {
  name = "global-frontend-address-ip"
}

resource "google_compute_global_address" "api-gateway-address" {
  name = "global-api-gateway-address-ip"
}
