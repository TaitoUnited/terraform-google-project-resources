/**
 * Copyright 2021 Taito United
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
  for_each      = local.bucketsById
  name          = each.value.name
  location      = each.value.location
  storage_class = each.value.storageClass

  labels = {
    project   = var.project
    env       = var.env
    purpose   = "storage"
  }

  dynamic "cors" {
    for_each = (
      each.value.corsRules != null && each.value.corsRules != ""
        ? each.value.corsRules
        : []
    )
    content {
      origin = cors.value.allowedOrigins
      method = coalesce(cors.value.allowedMethods, ["GET","HEAD"])
      response_header = coalesce(cors.value.exposeHeaders, ["*"])
      max_age_seconds = coalesce(cors.value.maxAgeSeconds, 5)
    }
  }

  versioning {
    enabled = each.value.versioningEnabled
  }

  # transition
  dynamic "lifecycle_rule" {
    for_each = (
      each.value.transitionRetainDays != null &&
        each.value.transitionRetainDays != ""
      ? [1]
      : []
    )

    content {
      condition {
        age = each.value.transitionRetainDays
      }
      action {
        type = "SetStorageClass"
        storage_class = each.value.transitionStorageClass
      }
    }
  }

  # versioning
  dynamic "lifecycle_rule" {
    for_each = (
      each.value.versioningRetainDays != null &&
        each.value.versioningRetainDays != ""
      ? [1]
      : []
    )

    content {
      condition {
        age = each.value.versioningRetainDays
        with_state = "ARCHIVED"
      }
      action {
        type = "Delete"
      }
    }
  }

  # autoDeletion
  dynamic "lifecycle_rule" {
    for_each = (
      each.value.autoDeletionRetainDays != null &&
        each.value.autoDeletionRetainDays != ""
      ? [1]
      : []
    )
    content {
      condition {
        age = each.value.autoDeletionRetainDays
        with_state = "ANY"
      }
      action {
        type = "Delete"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_binding" "bucket_admin" {
  depends_on = [
    google_storage_bucket.bucket,
    google_service_account.service_account,
  ]
  for_each = local.bucketsById
  bucket  = each.value.name
  role    = "roles/storage.admin"
  members = [
    for user in coalesce(
      each.value.admins != null
      ? each.value.admins
      : [],
      []
    ):
    user.id
  ]
}

resource "google_storage_bucket_iam_binding" "bucket_object_admin" {
  depends_on = [
    google_storage_bucket.bucket,
    google_service_account.service_account,
  ]
  for_each = local.bucketsById
  bucket  = each.value.name
  role    = "roles/storage.objectAdmin"
  members = [
    for user in coalesce(
      each.value.objectAdmins != null
      ? each.value.objectAdmins
      : [],
      []
    ):
    user.id
  ]
}

resource "google_storage_bucket_iam_binding" "bucket_object_viewer" {
  depends_on = [
    google_storage_bucket.bucket,
    google_service_account.service_account,
  ]
  for_each = local.bucketsById
  bucket  = each.value.name
  role    = "roles/storage.objectViewer"
  members = [
    for user in coalesce(
      each.value.objectViewers != null
      ? each.value.objectViewers
      : [],
      []
    ):
    user.id
  ]
}
