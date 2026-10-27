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

# Route paths to container backend services
resource "google_compute_url_map" "app" {
  count = length(local.ingressContainerPathsById) > 0 ? 1 : 0

  name = "${var.project}-${var.env}"

  host_rule {
    hosts        = local.allDomainNames
    path_matcher = "app-paths"
  }

  default_url_redirect {
    https_redirect = true
    path_redirect  = "/"
    strip_query    = true
  }

  path_matcher {
    name = "app-paths"

    dynamic "path_rule" {
      for_each = local.ingressContainerPathsById

      content {
        service = google_compute_backend_service.container[path_rule.value.containerId].id

        paths = [
          "${path_rule.value.path}",
          "${path_rule.value.path}/*",
        ]

        route_action {
          url_rewrite {
            path_prefix_rewrite = "/"
          }
        }

        # TODO: add test {}
      }
    }
  }
}

# Container backend services
resource "google_compute_backend_service" "container" {
  for_each = local.ingressContainersById

  name                  = "${var.project}-${var.env}-${each.key}"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.container[each.key].id
  }
}

# Serverless NEGs connect the load balancer to Cloud Run
resource "google_compute_region_network_endpoint_group" "container" {
  for_each = local.ingressContainersById

  name                  = "${var.project}-${var.env}-${each.key}"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.container[each.key].name
  }
}

# Allow public access to container endpoints that have path set
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  for_each = local.ingressContainersById

  location = var.region
  name     = google_cloud_run_v2_service.container[each.key].name

  role   = "roles/run.invoker"
  member = "allUsers"
}

resource "google_compute_global_address" "app" {
  count = var.create_ingress && local.ingress.enabled ? 1 : 0

  name = "${var.project}-${var.env}"
}

resource "google_compute_target_https_proxy" "app" {
  count = var.create_ingress && local.ingress.enabled ? 1 : 0

  name            = "${var.project}-${var.env}"
  url_map         = google_compute_url_map.app[0].id
  certificate_map = var.ingress_certificate_map_name # TODO: "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.map.id}"

  depends_on = [
    google_certificate_manager_certificate_map.app,
  ]
}

resource "google_compute_global_forwarding_rule" "app" {
  count = var.create_ingress && local.ingress.enabled ? 1 : 0

  name                  = "${var.project}-${var.env}"
  ip_address            = google_compute_global_address.app[0].address
  target                = google_compute_target_https_proxy.app[0].id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}