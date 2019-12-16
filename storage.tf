/**
 * Copyright 2019 Taito United
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

resource "google_storage_bucket" "bucket" {
  count         = length(var.storages)
  name          = var.storages[count.index]
  location      = var.storage_locations[count.index]
  storage_class = var.storage_classes[count.index]

  labels = {
    project   = var.project
    env       = var.env
    purpose   = "storage"
  }

  /* TODO: enable localhost only for dev and feat environments */
  cors {
    origin = ["http://localhost", "https://${var.domain}"]
    method = ["GET"]
  }

  versioning {
    enabled = "true"
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      with_state = "ARCHIVED"
      age        = var.storage_days[count.index]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "bucket_service_account_member" {
  depends_on = [
    google_service_account.service_account,
    google_storage_bucket.bucket,
  ]
  count  = var.gcp_service_account_enabled == "true" ? length(var.storages) : 0
  bucket = var.storages[count.index]
  /* TODO: Should be objectAdmin, but currently minio gateway requires admin */
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.service_account[0].email}"
}
