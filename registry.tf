/**
 * Copyright 2024 Taito United
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

resource "google_artifact_registry_repository" "container-repository" {
  count         = var.create_container_image_repositories ? 1 : 0

  project       = var.infra_project_id
  repository_id = var.project
  location      = var.region
  format        = "DOCKER"

  docker_config {
    immutable_tags = var.registry_immutable_tags
  }
}

data "google_artifact_registry_repository" "container-repository" {
  count         = !var.create_cicd_service_account || var.create_container_image_repositories ? 0 : 1

  project       = var.infra_project_id
  repository_id = var.project
  location      = var.region
}
