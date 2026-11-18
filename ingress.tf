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

# Load balancer address

resource "google_compute_global_address" "app" {
  count = var.create_ingress && local.ingress.enabled ? 1 : 0

  name = "${var.project}-${var.env}"

  depends_on = [
    module.admin.apis,
  ]
}

data "google_compute_global_address" "app" {
  count = local.ingress.enabled ? 1 : 0

  name = "${var.project}-${var.env}"

  depends_on = [
    google_compute_global_address.app,
  ]
}

# Route paths to container backend services
resource "google_compute_url_map" "app" {
  count = var.create_ingress_routes && local.ingress.enabled && length(local.ingressContainerPathsById) > 0 && local.envOwnsIngressUrlMap ? 1 : 0

  name = "${var.project}-${var.env}"

  host_rule {
    hosts        = local.allDomainNames
    path_matcher = var.env
  }

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }

  path_matcher {
    name            = var.env
    default_service = google_compute_backend_service.container[keys(local.ingressContainersById)[0]].id

    dynamic "path_rule" {
      for_each = local.ingressContainerPathsById

      content {
        service = google_compute_backend_service.container[path_rule.value.containerId].id

        paths = [
          "${path_rule.value.path}",
          "${path_rule.value.path}/*",
        ]

        dynamic "route_action" {
          for_each = path_rule.value.rewriteTargetDisabled ? [] : [1]
          iterator = dummy

          content {
            url_rewrite {
              path_prefix_rewrite = "/"
            }
          }
        }

        # TODO: add test {}
      }
    }
  }

  lifecycle {
    # Ignore route changes made by PR environments
    ignore_changes = all
  }
}

resource "terraform_data" "google_compute_url_map_update" {
  count = var.create_ingress_routes && local.ingress.enabled && length(local.ingressContainerPathsById) > 0 && !local.envOwnsIngressUrlMap ? 1 : 0

  input = {
    project_id = var.project_id
    project    = var.project
    env        = var.env
    target_env = var.target_env
    hosts      = join(",", local.allDomainNames)

    default_service = google_compute_backend_service.container[keys(local.ingressContainersById)[0]].id

    backend_service_path_rules = join(",", flatten([
      for itemId, item in local.ingressContainerPathsById : [
        "${item.path}=${google_compute_backend_service.container[item.containerId].id}",
        "${item.path}/*=${google_compute_backend_service.container[item.containerId].id}",
      ]
    ]))
  }

  # Concurrent PR environments share the dev URL map. GCP rejects changes
  # while another operation on the URL map is in progress, and gcloud's
  # read-modify-write fails on a stale fingerprint, so retry those with jitter.
  provisioner "local-exec" {
    # TODO: add support for path_prefix_rewrite = "/"
    command = <<-EOT
      url_map=${self.input.project}-${self.input.env}
      matcher=${self.input.target_env}
      deadline=$(( $(date +%s) + 900 ))
      seed=$(printf '%s' "$matcher" | cksum | cut -d ' ' -f 1)
      while :; do
        if names=$(gcloud compute url-maps describe "$url_map" \
          --project=${self.input.project_id} \
          --global \
          --format='value(pathMatchers[].name)') &&
          printf '%s\n' "$names" | tr ';' '\n' | grep -qxF "$matcher"; then
          echo "Path matcher $matcher already exists on URL map $url_map"
          exit 0
        fi
        if output=$(gcloud compute url-maps add-path-matcher "$url_map" \
          --project=${self.input.project_id} \
          --path-matcher-name="$matcher" \
          --global \
          --new-hosts=${self.input.hosts} \
          --default-service=${self.input.default_service} \
          --backend-service-path-rules=${self.input.backend_service_path_rules} 2>&1); then
          printf '%s\n' "$output"
          exit 0
        fi
        printf '%s\n' "$output" >&2
        if ! printf '%s\n' "$output" | grep -qi -e 'is not ready' -e 'fingerprint'; then
          exit 1
        fi
        if [ "$(date +%s)" -ge "$deadline" ]; then
          echo "Timed out waiting for URL map $url_map to accept changes" >&2
          exit 1
        fi
        delay=$(awk -v seed="$(( seed + $(date +%s) ))" 'BEGIN { srand(seed); print 5 + int(rand() * 11) }')
        echo "URL map $url_map is busy, retrying in $delay seconds" >&2
        sleep "$delay"
      done
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      url_map=${self.input.project}-${self.input.env}
      matcher=${self.input.target_env}
      deadline=$(( $(date +%s) + 900 ))
      seed=$(printf '%s' "$matcher" | cksum | cut -d ' ' -f 1)
      while :; do
        if names=$(gcloud compute url-maps describe "$url_map" \
          --project=${self.input.project_id} \
          --global \
          --format='value(pathMatchers[].name)') &&
          ! printf '%s\n' "$names" | tr ';' '\n' | grep -qxF "$matcher"; then
          echo "Path matcher $matcher already absent from URL map $url_map"
          exit 0
        fi
        if output=$(gcloud compute url-maps remove-path-matcher "$url_map" \
          --project=${self.input.project_id} \
          --path-matcher-name="$matcher" \
          --global 2>&1); then
          printf '%s\n' "$output"
          exit 0
        fi
        printf '%s\n' "$output" >&2
        if ! printf '%s\n' "$output" | grep -qi -e 'is not ready' -e 'fingerprint'; then
          exit 1
        fi
        if [ "$(date +%s)" -ge "$deadline" ]; then
          echo "Timed out waiting for URL map $url_map to accept changes" >&2
          exit 1
        fi
        delay=$(awk -v seed="$(( seed + $(date +%s) ))" 'BEGIN { srand(seed); print 5 + int(rand() * 11) }')
        echo "URL map $url_map is busy, retrying in $delay seconds" >&2
        sleep "$delay"
      done
    EOT
  }
}

# Container backend services
resource "google_compute_backend_service" "container" {
  for_each = local.ingressContainersById

  name                  = "${var.project}-${var.target_env}-${each.key}"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.container[each.key].id
  }
}

# Serverless NEGs connect the load balancer to Cloud Run
resource "google_compute_region_network_endpoint_group" "container" {
  for_each = local.ingressContainersById

  name                  = "${var.project}-${var.target_env}-${each.key}"
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

resource "google_compute_global_forwarding_rule" "app" {
  count = var.create_ingress_routes && local.ingress.enabled && length(local.ingressContainerPathsById) > 0 && local.envOwnsIngressUrlMap ? 1 : 0

  name                  = "${var.project}-${var.env}"
  ip_address            = data.google_compute_global_address.app[0].address
  target                = google_compute_target_https_proxy.app[0].id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_target_https_proxy" "app" {
  count = var.create_ingress_routes && local.ingress.enabled && length(local.ingressContainerPathsById) > 0 && local.envOwnsIngressUrlMap ? 1 : 0

  name            = "${var.project}-${var.env}"
  url_map         = google_compute_url_map.app[0].id
  certificate_map = "//certificatemanager.googleapis.com/projects/${var.project_id}/locations/global/certificateMaps/${var.ingress_certificate_map_name}"

  depends_on = [
    google_certificate_manager_certificate_map.app,
  ]
}
