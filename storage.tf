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

  cors {
    origin = (
      length(var.storage_cors) > count.index
        ? (
          length(var.storage_cors[count.index]) > 1
            ? split(",", var.storage_cors[count.index])
            : [ "https://${var.domain}" ] // default
        )
        : [ "https://${var.domain}" ] // default
    )
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
      with_state = (
        length(regexall(".*-expiration", var.storage_days[count.index])) > 0
          ? "ANY" : "ARCHIVED"
      )
      age        = split("-", var.storage_days[count.index])[0]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_binding" "bucket_admin" {
  depends_on = [
    google_storage_bucket.bucket,
  ]
  count   = length(var.storages)
  bucket  = var.storages[count.index]
  role    = "roles/storage.admin"
  members = concat(
    (
      /* TODO: Should be objectAdmin, but currently minio gateway requires admin */
      var.service_account_enabled
        ? [ "serviceAccount:${google_service_account.service_account[0].email}" ]
        : []
    ),
    length(var.storage_admins) > count.index
      ? (
          length(var.storage_admins[count.index]) > 1
            ? split(",", var.storage_admins[count.index])
            : []
        )
      : []
  )
}

resource "google_storage_bucket_iam_binding" "bucket_object_admin" {
  depends_on = [
    google_storage_bucket.bucket,
  ]
  count   = length(var.storages)
  bucket  = var.storages[count.index]
  role    = "roles/storage.objectAdmin"
  members = concat(
    length(var.storage_object_admins) > count.index
      ? (
          length(var.storage_object_admins[count.index]) > 1
            ? split(",", var.storage_object_admins[count.index])
            : []
        )
      : []
  )
}

resource "google_storage_bucket_iam_binding" "bucket_object_viewer" {
  depends_on = [
    google_storage_bucket.bucket,
  ]
  count   = length(var.storages)
  bucket  = var.storages[count.index]
  role    = "roles/storage.objectViewer"
  members = concat(
    length(var.storage_object_viewers) > count.index
      ? (
          length(var.storage_object_viewers[count.index]) > 1
            ? split(",", var.storage_object_viewers[count.index])
            : []
        )
      : []
  )
}
