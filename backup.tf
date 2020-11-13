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

/* TODO
data "google_storage_transfer_project_service_account" "backup_bucket_transfer" {
}

resource "google_storage_bucket" "backup_bucket" {
  for_each      = length(var.backup_days) > 0 ? local.bucketsById : {}
  name          = "${each.value.name}-backup"
  location      = each.value.backupLocation
  storage_class = var.backup_days[count.index] >= 90 ? "COLDLINE" : "NEARLINE"

  labels = {
    project = var.project
    env     = var.env
    purpose = "backup"
  }

  versioning {
    enabled = "false"
  }

  retention_policy {
    is_locked           = true
    retention_period    = 60 * 60 * 24 * var.backup_days[count.index]
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      with_state = "ARCHIVED" // TODO: is this correct?
      age        = 1
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "backup_bucket_transfer_member" {
  count      = min(length(local.bucketsById), length(var.backup_days))
  bucket     = "${var.storages[count.index]}-backup"
  role       = "roles/storage.objectAdmin"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.backup_bucket_transfer.email}"
  depends_on = [google_storage_bucket.backup_bucket]
}

resource "google_storage_bucket_iam_member" "backup_bucket_transfer_member_legacy" {
  count      = min(length(local.bucketsById), length(var.backup_days))
  bucket     = "${var.storages[count.index]}-backup"
  role       = "roles/storage.legacyBucketReader"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.backup_bucket_transfer.email}"
  depends_on = [google_storage_bucket.backup_bucket]
}

resource "google_storage_bucket_iam_member" "bucket_transfer_member" {
  count      = min(length(local.bucketsById), length(var.backup_days))
  bucket     = var.storages[count.index]
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.backup_bucket_transfer.email}"
  depends_on = [google_storage_bucket.bucket]
}

resource "google_storage_bucket_iam_member" "bucket_transfer_member_legacy" {
  count      = min(length(local.bucketsById), length(var.backup_days))
  bucket     = var.storages[count.index]
  role       = "roles/storage.legacyBucketReader"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.backup_bucket_transfer.email}"
  depends_on = [google_storage_bucket.bucket]
}

resource "google_storage_transfer_job" "backup_bucket_transfer" {
  count       = min(length(local.bucketsById), length(var.backup_days))
  description = "${var.storages[count.index]} backup"

  transfer_spec {
    gcs_data_source {
      bucket_name = var.storages[count.index]
    }
    gcs_data_sink {
      bucket_name = "${var.storages[count.index]}-backup"
    }
  }

  schedule {
    schedule_start_date {
      year  = 2019
      month = 1
      day   = 1
    }
    schedule_end_date {
      year  = 9999
      month = 12
      day   = 31
    }
    start_time_of_day {
      hours   = 0
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }

  depends_on = [
    google_storage_bucket.bucket,
    google_storage_bucket.backup_bucket,
    google_storage_bucket_iam_member.bucket_transfer_member,
    google_storage_bucket_iam_member.bucket_transfer_member_legacy,
    google_storage_bucket_iam_member.backup_bucket_transfer_member,
    google_storage_bucket_iam_member.backup_bucket_transfer_member_legacy,
  ]
}
*/
