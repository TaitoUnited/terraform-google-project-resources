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

resource "google_certificate_manager_certificate" "certificate" {
  for_each   = {for item in (var.certificate_map != "" ? local.allDomainNames : []): item => item}

  name    = each.value
  location = "global"

  managed {
    domains = [
      each.value
    ]
  }
}

resource "google_certificate_manager_certificate_map_entry" "certificate" {
  for_each   = {for item in (var.certificate_map != "" ? local.allDomainNames : []): item => item}
  
  name       = each.value
  hostname   = each.value
  map        = var.certificate_map

  certificates = [
    google_certificate_manager_certificate.certificate[each.key].id
  ]
}
