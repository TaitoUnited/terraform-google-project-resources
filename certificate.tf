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

resource "google_certificate_manager_certificate_map" "app" {
  count = var.create_ingress_certificate_map ? 1 : 0
  name  = var.ingress_certificate_map_name
}

resource "google_certificate_manager_certificate" "certificate" {
  depends_on = [
    module.admin.apis,
    google_certificate_manager_certificate_map.app,
  ]

  for_each = { for item in(var.ingress_certificate_map_name != "" && var.create_ingress_certificate ? local.allDomainNames : []) : item => item }

  name     = replace(each.value, ".", "-")
  location = "global"

  managed {
    domains = [
      each.value
    ]
  }
}

resource "google_certificate_manager_certificate_map_entry" "certificate" {
  for_each = { for item in(var.ingress_certificate_map_name != "" && var.create_ingress_certificate ? local.allDomainNames : []) : item => item }

  name     = replace(each.value, ".", "-")
  hostname = each.value
  map      = var.ingress_certificate_map_name

  certificates = [
    google_certificate_manager_certificate.certificate[each.key].id
  ]
}
