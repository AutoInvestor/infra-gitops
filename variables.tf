variable "project_id" {
  description = "ID del proyecto"
  type        = string
}

variable "region" {
  description = "La región en la que crearás los recursos"
  type        = string
}

variable "gke_zone" {
  description = "La zona en la que crearás el GKE cluster"
  type        = string
}

variable "gke_cluster_name" {
  default = "Name of the GKE cluster"
  type    = string
}