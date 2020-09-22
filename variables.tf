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

# variable "create_function_permissions" {
#   type        = bool
#   default     = false
#   description = "If true, function permissions are created."
# }

variable "create_service_accounts" {
  type        = bool
  default     = false
  description = "If true, service accounts are created."
}

variable "create_service_account_roles" {
  type        = bool
  default     = false
  description = "If true, service account IAM permissions are created. (TODO)"
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

variable "create_log_alert_metrics" {
  type        = bool
  default     = false
  description = "If true, log metrics are created for all log alerts."
}

variable "create_log_alert_policies" {
  type        = bool
  default     = false
  description = "If true, alert policies are created for log alerts"
}

# variable "create_container_image_repositories" {
#   type        = bool
#   default     = false
#   description = "If true, container image repositories are created."
# }

# Project

variable "project" {
  type        = string
  description = "Project name: e.g. \"my-project\". NOTE: This is not the name of the GCP project (one GCP project may contain multiple projects)."
}

variable "env" {
  type        = string
  description = "Environment: e.g. \"dev\""
}

# Cloud provider

variable "project_id" {
  type        = string
  description = "Google Cloud project id for resources. The project should already exist."
}

variable "region" {
  type        = string
  description = "Google Cloud region."
}

variable "zone" {
  type        = string
  description = "Google Cloud zone."
}

# Version control

variable "vc_repo" {
  type        = string
  description = "Repository: e.g. \"git_myorg_my-project\""
}

variable "vc_branch" {
  type        = string
  description = "Branch: e.g. \"dev\""
}

# CI/CD settings

variable "cicd_project_id" {
  type        = string
  default     = ""
  description = "Google Cloud project id for CI/CD (Cloud Build). If not set, var.project_id will be used by default. The project should already exist."
}

# Logging settings

variable "log_alert_project_id" {
  type        = string
  default     = ""
  description = "Google Cloud project id for log alerts. If not set, var.project_id will be used by default. The project should already exist."
}

# Uptime settings

variable "uptime_project_id" {
  type        = string
  description = "Google Cloud project id for uptime monitoring. If not set, var.project_id will be used by default. The project should already exist."
}

variable "uptime_channels" {
  type = list(string)
  default = []
  description = "SNS topics used to send alert notifications (e.g. \"arn:aws:sns:us-east-1:0123456789:my-zone-uptimez\")"
}

# Resources as a json/yaml

variable "resources" {
  type = object({
    backupEnabled = bool
    uptimeEnabled = bool
    alerts = list(object({
      name = string
      type = string
      channels = list(string)
      rule = string
    }))
    serviceAccounts = list(object({
      id = string
      roles = list(string)
    }))
    apiKeys = list(object({
      name = string
      services = list(string)
      origins = list(string)
    }))
    ingress = object({
      class = string
      enabled = bool
      createMainDomain = bool
      domains = list(object({
        name = string
        altDomains = list(object({
          name = string
        }))
      }))
    })
    services = map(object({
      type = string
      machineType = string
      name = string
      location = string
      storageClass = string
      cors = list(object({
        origin = string
      }))
      versioningEnabled = bool
      versioningRetainDays = number
      lockRetainDays = number
      transitionRetainDays = number
      transitionStorageClass = string
      autoDeletionRetainDays = number
      replicationBucket = string
      backupRetainDays = number
      backupLocation = string
      backupLock = bool
      admins = list(object({
        id = string
      }))
      objectAdmins = list(object({
        id = string
      }))
      objectViewers = list(object({
        id = string
      }))
      replicas = number
      path = string
      uptimePath = string
      timeout = number
      runtime = string
      memoryRequest = number
      secrets = map(string)
      env = map(string)
      publishers = list(object({
        id = string
      }))
      subscribers = list(object({
        id = string
      }))
    }))
  })
  description = "Resources as JSON (see README.md). You can read values from a YAML file with yamldecode()."
}
