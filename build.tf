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

resource "google_cloudbuild_trigger" "cicd_trigger" {
  count    = var.create_build_trigger ? 1 : 0
  provider = google-beta

  project  = local.cicd_project_id
  name     = "${var.project}-${var.env}"

  github {
    owner    = var.vc_organization
    name     = var.vc_repository
    push {
      branch = "^${var.vc_branch}$"
    }
  }

  /* TODO: FOR MIRRORED REPO
  trigger_template {
    repo_name   = var.vc_repo
    branch_name = var.vc_branch
  }
  */

  filename = "cloudbuild.yaml"
}
