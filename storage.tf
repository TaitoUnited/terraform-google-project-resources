/**
 * Copyright 2020 Taito United
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
  count         = length(local.bucketsById)
  name          = values(local.bucketsById)[count.index].name
  location      = values(local.bucketsById)[count.index].location
  storage_class = values(local.bucketsById)[count.index].storageClass

  labels = {
    project   = var.project
    env       = var.env
    purpose   = "storage"
  }

  cors {
    origin = [
      for cors in values(local.bucketsById)[count.index].cors:
      cors.domain
    ]
    method = ["GET"]
  }

  versioning {
    enabled = values(local.bucketsById)[count.index].versioning
  }

  # transition
  dynamic "lifecycle_rule" {
    for_each = try(values(local.bucketsById)[count.index].transitionRetainDays, null) != null ? [1] : []
    content {
      condition {
        age = values(local.bucketsById)[count.index].transitionRetainDays
      }
      action {
        type = "SetStorageClass"
        storage_class = values(local.bucketsById)[count.index].transitionStorageClass
      }
    }
  }

  # versioning
  dynamic "lifecycle_rule" {
    for_each = try(values(local.bucketsById)[count.index].versioningRetainDays, null) != null ? [1] : []
    content {
      condition {
        age = values(local.bucketsById)[count.index].versioningRetainDays
        with_state = "ARCHIVED"
      }
      action {
        type = "Delete"
      }
    }
  }

  # autoDeletion
  dynamic "lifecycle_rule" {
    for_each = try(values(local.bucketsById)[count.index].autoDeletionRetainDays, null) != null ? [1] : []
    content {
      condition {
        age = values(local.bucketsById)[count.index].autoDeletionRetainDays
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
  ]
  count   = length(local.bucketsById)
  bucket  = values(local.bucketsById)[count.index].name
  role    = "roles/storage.admin"
  members = [
    for user in try(
      values(local.bucketsById)[count.index].admins != null
      ? values(local.bucketsById)[count.index].admins
      : [],
      []
    ):
    user.id
  ]
}

resource "google_storage_bucket_iam_binding" "bucket_object_admin" {
  depends_on = [
    google_storage_bucket.bucket,
  ]
  count   = length(local.bucketsById)
  bucket  = values(local.bucketsById)[count.index].name
  role    = "roles/storage.objectAdmin"
  members = [
    for user in try(
      values(local.bucketsById)[count.index].objectAdmins != null
      ? values(local.bucketsById)[count.index].objectAdmins
      : [],
      []
    ):
    user.id
  ]
}

resource "google_storage_bucket_iam_binding" "bucket_object_viewer" {
  depends_on = [
    google_storage_bucket.bucket,
  ]
  count   = length(local.bucketsById)
  bucket  = values(local.bucketsById)[count.index].name
  role    = "roles/storage.objectViewer"
  members = [
    for user in try(
      values(local.bucketsById)[count.index].objectViewers != null
      ? values(local.bucketsById)[count.index].objectViewers
      : [],
      []
    ):
    user.id
  ]
}
