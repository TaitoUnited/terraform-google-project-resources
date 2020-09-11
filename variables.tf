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

# Create flags

# variable "create_domain" {
#   type        = bool
#   default     = false
#   description = "If true, a DNS setup is created for each main domain."
# }
#
# variable "create_domain_certificate" {
#   type        = bool
#   default     = false
#   description = "If true, a domain certificate is created for each domain."
# }

variable "create_members" {
  type        = bool
  default     = false
  description = "If true, members will be created."
}

variable "create_build_trigger" {
  type        = bool
  default     = false
  description = "If true, build trigger will be created."
}

variable "create_storage_buckets" {
  type        = bool
  default     = false
  description = "If true, storage buckets are created."
}

variable "create_databases" {
  type        = bool
  default     = false
  description = "If true, databases are created. (TODO)"
}

variable "create_in_memory_databases" {
  type        = bool
  default     = false
  description = "If true, in-memory databases are created. (TODO)"
}

variable "create_topics" {
  type        = bool
  default     = false
  description = "If true, topics are created."
}

variable "create_ingress" {
  type        = bool
  default     = false
  description = "If true, ingress is created. (TODO)"
}

variable "create_containers" {
  type        = bool
  default     = false
  description = "If true, containers are created. (TODO)"
}

variable "create_functions" {
  type        = bool
  default     = false
  description = "If true, functions are created. (TODO)"
}

variable "create_function_permissions" {
  type        = bool
  default     = false
  description = "If true, function permissions are created. (TODO)"
}

variable "create_service_accounts" {
  type        = bool
  default     = false
  description = "If true, service accounts are created."
}

variable "create_apis" {
  type        = bool
  default     = false
  description = "If true, apis will be created."
}

variable "create_api_keys" {
  type        = bool
  default     = false
  description = "If true, api keys are created. (TODO)"
}

variable "create_uptime_checks" {
  type        = bool
  default     = false
  description = "If true, uptime check and alert is created for each service with uptime path set."
}

variable "create_alert_metrics" {
  type        = bool
  default     = false
  description = "If true, log metrics are created for all log alerts."
}

variable "create_alerts_policies" {
  type        = bool
  default     = false
  description = "If true, alert policies are created for all alerts"
}

# variable "create_container_image_repositories" {
#   type        = bool
#   default     = false
#   description = "If true, container image repositories are created."
# }

# Google provider

variable "project_id" {
  type        = string
  description = "Google Cloud project id. The project should already exist."
}

variable "region" {
  type        = string
  description = "Google Cloud region."
}

variable "zone" {
  type        = string
  description = "Google Cloud zone."
}

# Labels

variable "project" {
  type        = string
  description = "Project name: e.g. \"my-project\". NOTE: This is not the name of the GCP project (one GCP project may contain multiple projects)."
}

# Environment info

variable "env" {
  type        = string
  description = "Environment: e.g. \"dev\""
}

# Version control info

variable "vc_repo" {
  type        = string
  description = "Repository: e.g. \"git_myorg_my-project\""
}

variable "vc_branch" {
  type        = string
  description = "Branch: e.g. \"dev\""
}

# Uptime settings

variable "uptime_channels" {
  type = list(string)
  default = []
  description = "SNS topics used to send alert notifications (e.g. \"arn:aws:sns:us-east-1:0123456789:my-zone-uptimez\")"
}

# Resources as a json/yaml

variable "resources" {
  type        = any
  description = "Resources as JSON (see README.md). You can read values from a YAML file with yamldecode()."
}
