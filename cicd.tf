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

resource "google_cloudbuild_trigger" "cicd_trigger" {
  depends_on = [
    module.admin.apis,
  ]

  count = var.create_build_trigger ? 1 : 0

  project = local.cicd_project_id
  name    = "${var.project}-${var.env}"

  service_account = var.create_cicd_service_account ? google_service_account.cicd_service_account[0].id : null

  github {
    owner = var.vc_organization
    name  = var.vc_repository
    push {
      branch = "^${var.vc_branch}$"
    }
  }
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  /* TODO: FOR MIRRORED REPO
  trigger_template {
    repo_name   = var.vc_repo
    branch_name = var.vc_branch
  }
  */

  filename = coalesce(var.cicd_file_path, "cloudbuild.yaml")

  location       = coalesce(var.cicd_location, var.region)
  included_files = var.cicd_included_files
  ignored_files  = var.cicd_ignored_files
}

resource "google_service_account" "cicd_service_account" {
  count = var.create_cicd_service_account ? 1 : 0

  project    = local.cicd_project_id
  account_id = "${var.project}-${var.env}-cicd"
}

data "google_service_account" "cicd_service_account" {
  depends_on = [google_service_account.cicd_service_account]
  project    = local.cicd_project_id
  account_id = "${var.project}-${var.env}-cicd"
}

resource "google_service_account_iam_member" "cicd_iam_service_account_user" {
  for_each           = var.create_cicd_service_account ? local.containersById : {}
  service_account_id = data.google_service_account.container[each.key].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_service_account.cicd_service_account.email}"
}

/* TODO: do we need to enable the iam.serviceAccountUser role in some cases?
resource "google_project_iam_member" "cicd_service_account_user" {
  count    = var.create_cicd_service_account ? 1 : 0

  project  = local.cicd_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}
*/

resource "google_project_iam_member" "cicd_cloudbuild_builder" {
  count = var.create_cicd_service_account ? 1 : 0

  project = local.cicd_project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_logs_writer" {
  count = var.create_cicd_service_account ? 1 : 0

  project = local.cicd_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

# TODO: roles/compute.networkAdmin is too broad role for CI/CD
resource "google_project_iam_member" "cicd_network_admin" {
  count = var.create_cicd_service_account && var.create_ingress && local.ingress.enabled ? 1 : 0

  project = local.infra_project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

# TODO: unlimited roles/secretmanager.secretAccessor is too broad role for CI/CD
resource "google_project_iam_member" "cicd_secret_accessor" {
  count = var.create_cicd_service_account && local.cloudRunEnabled ? 1 : 0

  project = local.infra_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_certificatemanager_editor" {
  count = var.create_cicd_service_account && var.create_ingress && local.ingress.enabled ? 1 : 0

  project = local.infra_project_id
  role    = "roles/certificatemanager.editor"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_serviceaccount_viewer" {
  count = var.create_cicd_service_account ? 1 : 0

  project = local.infra_project_id
  role    = "roles/iam.serviceAccountViewer"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_run_admin" {
  count = var.create_cicd_service_account ? 1 : 0

  project = local.infra_project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_cloudscheduler_admin" {
  count = var.create_cicd_service_account ? 1 : 0

  project = local.infra_project_id
  role    = "roles/cloudscheduler.admin"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_cloudsql_client" {
  count = var.create_cicd_service_account ? 1 : 0

  project = local.infra_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_run_developer" {
  count = var.create_cicd_service_account && local.cloudRunEnabled ? 1 : 0

  project = local.infra_project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_container_cluster_viewer" {
  count = var.create_cicd_service_account ? 1 : 0

  project = local.infra_project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_artifact_registry_repository_iam_member" "cicd_artifact_registry_reader" {
  count = !var.use_legacy_registry && var.create_cicd_service_account && var.create_container_image_repositories ? 1 : 0

  project    = google_artifact_registry_repository.container-repository[0].project
  location   = google_artifact_registry_repository.container-repository[0].location
  repository = google_artifact_registry_repository.container-repository[0].name

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_artifact_registry_repository_iam_member" "cicd_artifact_registry_writer" {
  count = !var.use_legacy_registry && var.create_cicd_service_account && var.create_container_image_repositories ? 1 : 0

  project    = google_artifact_registry_repository.container-repository[0].project
  location   = google_artifact_registry_repository.container-repository[0].location
  repository = google_artifact_registry_repository.container-repository[0].name

  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_artifact_registry_repository_iam_member" "cicd_artifact_registry_reader_other_env" {
  # HACK: build_image_tag check to allow gcp-deploy
  count = var.build_image_tag != "" || var.use_legacy_registry || (var.create_cicd_service_account && var.create_container_image_repositories) ? 0 : 1

  project    = data.google_artifact_registry_repository.container-repository.project
  location   = data.google_artifact_registry_repository.container-repository.location
  repository = data.google_artifact_registry_repository.container-repository.name

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_artifact_registry_repository_iam_member" "cicd_artifact_registry_writer_other_env" {
  # HACK: build_image_tag check to allow gcp-deploy
  count = var.build_image_tag != "" || var.use_legacy_registry || (var.create_cicd_service_account && var.create_container_image_repositories) ? 0 : 1

  project    = data.google_artifact_registry_repository.container-repository.project
  location   = data.google_artifact_registry_repository.container-repository.location
  repository = data.google_artifact_registry_repository.container-repository.name

  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}
