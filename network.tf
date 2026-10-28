/**
 * Copyright 2026 Taito United
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_compute_network" "vpc" {
  count = var.create_network ? 1 : 0

  name                    = var.vpc_name
  auto_create_subnetworks = false

  depends_on = [module.admin.apis]
}

data "google_compute_network" "vpc" {
  count = var.vpc_name != "" ? 1 : 0

  name = var.vpc_name

  depends_on = [google_compute_network.vpc]
}

resource "google_compute_subnetwork" "container" {
  count = var.create_network ? 1 : 0

  name                     = var.vpc_container_subnet_name
  region                   = var.region
  network                  = google_compute_network.vpc[0].id
  ip_cidr_range            = "10.20.0.0/24"
  private_ip_google_access = true
}

data "google_compute_subnetwork" "container" {
  count = var.vpc_container_subnet_name != "" ? 1 : 0

  name = var.vpc_container_subnet_name

  depends_on = [google_compute_subnetwork.container]
}

# Private Service Access for database connection

resource "google_compute_global_address" "private_ip_range" {
  count = var.create_network ? 1 : 0

  name          = "google-managed-services-app-vpc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc[0].id

  depends_on = [
    module.admin.apis
  ]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.create_network ? 1 : 0

  network = google_compute_network.vpc[0].id
  service = "servicenetworking.googleapis.com"

  reserved_peering_ranges = [
    google_compute_global_address.private_ip_range[0].name
  ]

  depends_on = [
    module.admin.apis
  ]
}
