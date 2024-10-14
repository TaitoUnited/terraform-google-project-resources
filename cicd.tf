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
  count    = var.create_build_trigger ? 1 : 0

  project  = local.cicd_project_id
  name     = "${var.project}-${var.env}"

  service_account = var.create_cicd_service_account ? google_service_account.cicd_service_account[0].id : null

  github {
    owner    = var.vc_organization
    name     = var.vc_repository
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

  filename = "cloudbuild.yaml"
}

resource "google_service_account" "cicd_service_account" {
  count    = var.create_cicd_service_account ? 1 : 0

  project  = local.cicd_project_id
  account_id = "${var.project}-${var.env}-cicd"
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
  count    = var.create_cicd_service_account ? 1 : 0

  project  = local.cicd_project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_logs_writer" {
  count    = var.create_cicd_service_account ? 1 : 0

  project  = local.cicd_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_cloudsql_client" {
  count    = var.create_cicd_service_account ? 1 : 0

  project  = var.infra_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_project_iam_member" "cicd_container_cluster_viewer" {
  count    = var.create_cicd_service_account ? 1 : 0

  project  = var.infra_project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_artifact_registry_repository_iam_member" "cicd_artifact_registry_reader" {
  count    = var.create_cicd_service_account && var.create_container_image_repositories ? 1 : 0

  project = google_artifact_registry_repository.container-repository[0].project
  location = google_artifact_registry_repository.container-repository[0].location
  repository = google_artifact_registry_repository.container-repository[0].name

  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}

resource "google_artifact_registry_repository_iam_member" "cicd_artifact_registry_writer" {
  count    = var.create_cicd_service_account && var.create_container_image_repositories ? 1 : 0

  project = google_artifact_registry_repository.container-repository[0].project
  location = google_artifact_registry_repository.container-repository[0].location
  repository = google_artifact_registry_repository.container-repository[0].name

  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cicd_service_account[0].email}"
}
