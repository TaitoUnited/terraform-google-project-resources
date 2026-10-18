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

resource "google_service_account" "container" {
  for_each     = local.containersById

  account_id   = "${var.project}-${each.key}-${var.env}"
  display_name = "${var.project}-${each.key}-${var.env}"

  depends_on   = [module.admin.apis]
}

resource "google_secret_manager_secret_iam_member" "container" {
  for_each     = local.containerSecretsById

  secret_id    = each.value.secretName
  role         = "roles/secretmanager.secretAccessor"
  member       = "serviceAccount:${google_service_account.container[each.value.containerId].email}"
}

resource "google_cloud_run_v2_service" "container" {
  for_each      = local.containersById
  name          = "${var.project}-${each.key}-${var.env}"
  location      = each.value.location

  # Allow traffic through the external Application Load Balancer,
  # not directly through the default run.app URL.
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  deletion_protection = false

  template {
    service_account = google_service_account.container[each.key].email

    containers {
      image = each.value.image

      ports {
        # TODO: make configurable
        container_port = 8080
      }

      dynamic "env" {
        for_each = each.value.env

        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = each.value.secretEnv

        content {
          name = env.key

          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      resources {
        limits = {
          cpu    = coalesce(each.value.cpuLimit, "1")
          memory = coalesce(each.value.memoryLimit, "512Mi")
        }
      }

      # Check whether the application has started successfully.
      dynamic "startup_probe" {
        for_each = each.value.livenessDisabled ? [] : [1]
        content {
          http_get {
            path = coalesce(each.value.livenessPath, "/healthz")
          }

          # TODO: make configurable
          initial_delay_seconds = 0
          period_seconds        = 10
          timeout_seconds       = 2
          failure_threshold     = 3
        }
      }

      # Restart the container if it becomes unhealthy.
      dynamic "liveness_probe" {
        for_each = each.value.livenessDisabled ? [] : [1]
        content {
          http_get {
            path = coalesce(each.value.livenessPath, "/healthz")
          }

          # TODO: make configurable
          initial_delay_seconds = 0
          period_seconds        = 10
          timeout_seconds       = 2
          failure_threshold     = 3
        }
      }
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = var.private_network_id
        subnetwork = var.private_container_subnetwork_id
      }
    }

    scaling {
      min_instance_count = coalesce(each.value.minReplicas, each.value.replicas)
      max_instance_count = coalesce(each.value.maxReplicas, each.value.replicas)
    }
  }

  depends_on = [
    module.admin.apis,
  ]
}