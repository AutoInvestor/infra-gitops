terraform {
  backend "gcs" {
    bucket = "terraform-state-autoinvestor"
    prefix = "terraform/state"
  }
}
