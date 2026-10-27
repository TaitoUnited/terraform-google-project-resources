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
  for_each = var.create_container_permissions ? local.containersById : {}

  account_id   = "${var.project}-${var.env}-${each.key}"
  display_name = "${var.project}-${var.env}-${each.key}"

  depends_on = [module.admin.apis]
}

data "google_service_account" "container" {
  for_each = local.containersById

  account_id = "${var.project}-${var.env}-${each.key}"

  depends_on = [google_service_account.container]
}

resource "google_secret_manager_secret_iam_member" "container" {
  for_each = var.create_container_permissions ? local.containerSecretsById : {}

  secret_id = each.value.secretName
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.container[each.value.containerId].email}"
}

resource "google_cloud_run_v2_service" "container" {
  for_each = local.containersById
  name     = "${var.project}-${var.env}-${each.key}"
  location = var.region

  # Allow traffic through the external Application Load Balancer,
  # not directly through the default run.app URL.
  ingress = length(coalesce(try(each.value.paths, null), [])) == 0 ? "INGRESS_TRAFFIC_INTERNAL_ONLY" : "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  # Simplify calls made to internal service by not requiring google-signed token
  invoker_iam_disabled = length(coalesce(try(each.value.paths, null), [])) == 0

  deletion_protection = false

  template {
    service_account = data.google_service_account.container[each.key].email

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

      # Populate secrets defined in secretEnv as environment variables
      dynamic "env" {
        for_each = coalesce(try(each.value.secretEnv, null), {})

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

      # Populate cloud run service urls of other services as environment variables
      /* TODO: resolve cycle
      dynamic "env" {
        for_each = {
          for key, container in local.containersById :
          key => container
          if key != each.key
        }        
        iterator = target

        content {
          name  = "${upper(replace(target.key, "-", "_"))}_URL"
          value = google_cloud_run_v2_service.container[target.key].uri
        }
      }
      */

      resources {
        limits = {
          cpu    = coalesce(try(each.value.cpuLimit, null), "1")
          memory = coalesce(try(each.value.memoryLimit, null), "512Mi")
        }
      }

      # Check whether the application has started successfully.
      dynamic "startup_probe" {
        for_each = try(each.value.livenessDisabled, false) ? [] : [1]
        content {
          http_get {
            path = coalesce(try(each.value.livenessPath, null), "/healthz")
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
        for_each = try(each.value.livenessDisabled, false) ? [] : [1]
        content {
          http_get {
            path = coalesce(try(each.value.livenessPath, null), "/healthz")
          }

          # TODO: make configurable
          initial_delay_seconds = 0
          period_seconds        = 10
          timeout_seconds       = 2
          failure_threshold     = 3
        }
      }

      # Database proxy
      dynamic "volume_mounts" {
        for_each = try(each.value.db.useProxy, false) ? [1] : [0]

        content {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }

    # Database proxy
    dynamic "volumes" {
      for_each = try(each.value.db.useProxy, false) ? [1] : [0]

      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [each.value.db.instance]
        }
      }
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = data.google_compute_network.vpc[0].id
        subnetwork = data.google_compute_subnetwork.container[0].id
      }
    }

    scaling {
      min_instance_count = coalesce(try(each.value.minReplicas, null), try(each.value.replicas, null), 1)
      max_instance_count = coalesce(try(each.value.maxReplicas, null), try(each.value.replicas, null), 1)
    }
  }

  depends_on = [
    module.admin.apis,
  ]
}

/* ---- Cron job ----- */

resource "google_cloud_run_v2_job" "cronjob" {
  for_each = local.containerCronJobsById
  name     = "${var.project}-${var.env}-${each.key}"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account = data.google_service_account.container[each.value.container.id].email

      containers {
        image = each.value.container.image

        command = ["sh", "-c", each.value.shellCommand]

        dynamic "env" {
          for_each = merge(each.value.container.env, each.value.env)

          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = merge(each.value.container.secretEnv, each.value.secretEnv)

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
            cpu    = coalesce(try(each.value.cpuLimit, null), try(each.value.container.cpuLimit, null), "1")
            memory = coalesce(try(each.value.memoryLimit, null), try(each.value.container.memoryLimit, null), "512Mi")
          }
        }
      }

      vpc_access {
        egress = "PRIVATE_RANGES_ONLY"

        network_interfaces {
          network    = data.google_compute_network.vpc[0].id
          subnetwork = data.google_compute_subnetwork.container[0].id
        }
      }
    }
  }

  depends_on = [
    module.admin.apis,
  ]
}

resource "google_service_account" "scheduler" {
  for_each = local.containerCronJobsById

  account_id   = "${var.project}-${var.env}-${each.key}"
  display_name = "${var.project}-${var.env}-${each.key}"

  depends_on = [module.admin.apis]
}

resource "google_cloud_run_v2_job_iam_member" "scheduler" {
  for_each = local.containerCronJobsById

  location = var.region
  name     = google_cloud_run_v2_job.cronjob[each.key].name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.scheduler[each.key].email}"
}

resource "google_cloud_scheduler_job" "cronjob" {
  for_each = local.containerCronJobsById
  name     = "${var.project}-${var.env}-${each.key}"
  region   = var.region

  schedule  = each.value.schedule
  time_zone = coalesce(each.value.timeZone, "Etc/UTC")

  http_target {
    http_method = "POST"

    uri = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.cronjob[each.key].name}:run"

    oauth_token {
      service_account_email = google_service_account.scheduler[each.key].email
    }
  }

  depends_on = [
    module.admin.apis,
    google_cloud_run_v2_job_iam_member.scheduler
  ]
}
