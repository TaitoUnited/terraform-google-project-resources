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

# Legacy flags for backwards compatilibity. Use these flags to avoid recreating existing resources unnecessarily.

variable "use_legacy_service_accounts" {
  type        = bool
  default     = false
  description = "If true, we don't use the service accounts provided by the admin module."
}

variable "use_legacy_registry" {
  type        = bool
  default     = false
  description = "If true, Google artifact registry repositories will not be created and CI/CD not given artifact registry roles, because project is using registries that were migrated from the old Google container registry."
}

variable "use_legacy_naming" {
  type        = bool
  default     = false
  description = "If true, we use legacy naming for some of the legacy resources."
}

# Create flags for resources typically shared between environments (created only once in each GCP project)

variable "create_apis" {
  type        = bool
  default     = false
  description = "If true, apis are created."
}

variable "create_permissions" {
  type        = bool
  default     = false
  description = "If true, permissions are created."
}

variable "create_network" {
  type        = bool
  default     = false
  description = "If true, a private network is created."
}

variable "create_databases" {
  type        = bool
  default     = false
  description = "If true, databases are created."
}

variable "create_in_memory_databases" {
  type        = bool
  default     = false
  description = "If true, in-memory databases are created. (TODO)"
}

# Create flags for resources typically shared between environments (created only once)

variable "create_container_image_repositories" {
  type        = bool
  default     = false
  description = "If true, container image repositories are created."
}

# Create flags for environment specific resources typically applied manually

variable "create_build_trigger" {
  type        = bool
  default     = false
  description = "If true, build trigger will be created. If you enable this, you must also enable create_cicd_service_account."
}

variable "create_cicd_service_account" {
  type        = bool
  default     = false
  description = "If true, ci/cd service account will be created."
}

variable "create_service_accounts" {
  type        = bool
  default     = false
  description = "If true, service accounts are created."
}

variable "create_api_keys" {
  type        = bool
  default     = false
  description = "If true, api keys are created."
}

variable "create_ingress" {
  type        = bool
  default     = false
  description = "If true, ingress is created."
}

variable "create_ingress_certificate_map" {
  type        = bool
  default     = false
  description = "If true, ingress certificate map is created."
}

variable "create_container_permissions" {
  type        = bool
  default     = false
  description = "If true, container service accounts and permissions are created."
}

variable "create_function_permissions" {
  type        = bool
  default     = false
  description = "If true, function service accounts and permissions are created. (TODO)"
}

variable "create_storage_buckets" {
  type        = bool
  default     = false
  description = "If true, storage buckets are created."
}

variable "create_topics" {
  type        = bool
  default     = false
  description = "If true, topics are created. (TODO)"
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

variable "create_uptime_checks" {
  type        = bool
  default     = false
  description = "If true, uptime check and alert is created for each service with uptime path set."
}

# Create flags for environment specific resources typically applied during CI/CD deploy

variable "create_ingress_routes" {
  type        = bool
  default     = false
  description = "If true, ingress routes are created are created for all services with path."
}

variable "create_ingress_certificate" {
  type        = bool
  default     = false
  description = "If true, ingress certificate is created for each domain."
}

variable "create_containers" {
  type        = bool
  default     = false
  description = "If true, containers are created."
}

variable "create_functions" {
  type        = bool
  default     = false
  description = "If true, functions are created. (TODO)"
}

# Project

variable "project" {
  type        = string
  description = "Project name: e.g. \"my-project\". NOTE: This is not the name of the GCP project (one GCP project may contain multiple projects)."
}

variable "env" {
  type        = string
  description = "Environment: e.g. \"dev\""
}

variable "target_env" {
  type        = string
  default     = ""
  description = "Target environment: e.g. \"pr-254\""
}

# Cloud provider

variable "project_id" {
  type        = string
  description = "Google Cloud project id for resources. The project should already exist."
}

variable "cicd_project_id" {
  type        = string
  default     = ""
  description = "Google Cloud project id for CI/CD. If not set, var.infra_project_id will be used by default. The project should already exist."
}

variable "infra_project_id" {
  type        = string
  default     = ""
  description = "Google Cloud project id for shared infrastructure. If not set, var.project_id will be used by default. The project should already exist."
}

variable "container_registry_project_id" {
  type        = string
  default     = ""
  description = "Google Cloud project id for shared container registry. If not set, var.infra_project_id will be used by default. The project should already exist."
}

variable "log_alert_project_id" {
  type        = string
  default     = ""
  description = "Google Cloud project id for log alerts. If not set, var.project_id will be used by default. The project should already exist."
}

variable "uptime_project_id" {
  type        = string
  default     = ""
  description = "Google Cloud project id for uptime monitoring. If not set, var.project_id will be used by default. The project should already exist."
}

variable "region" {
  type        = string
  description = "Google Cloud region."
}

variable "zone" {
  type        = string
  description = "Google Cloud zone."
}

# Service specific regions

variable "scheduler_region" {
  type        = string
  default     = ""
  description = "Google Cloud region for scheduler. If not set, var.region is used by default."
}

# Network

variable "vpc_name" {
  type        = string
  default     = ""
  description = "Private network for containers and database connectivity"
}

variable "vpc_container_subnet_name" {
  type        = string
  default     = ""
  description = "Private subnetwork for containers"
}

# Ingress

variable "ingress_certificate_map_name" {
  type        = string
  default     = ""
  description = "If not empty, a certificate is created for each domain and added to this certificate map"
}

# Version control

variable "vc_provider" {
  type        = string
  default     = ""
  description = "Version control provider (e.g. github)"
}

variable "vc_organization" {
  type        = string
  default     = ""
  description = "Version control organization"
}

variable "vc_repository" {
  type        = string
  default     = ""
  description = "Version control repository name"
}

/*
variable "vc_repo" {
  type        = string
  description = "Repository: e.g. \"git_myorg_my-project\""
}
*/

variable "vc_branch" {
  type        = string
  default     = ""
  description = "Branch: e.g. \"dev\""
}

# CI/CD settings

variable "cicd_file_path" {
  type        = string
  default     = ""
  description = "File path for Google Cloud Build cloudbuild.yaml. If not set, 'cloudbuild.yaml' will be used as default."
}

variable "cicd_location" {
  type        = string
  default     = ""
  description = "CI/CD location. By default the same as var.region."
}

variable "cicd_included_files" {
  type        = list(string)
  default     = []
  description = "File paths that trigger CI/CD build."
}

variable "cicd_ignored_files" {
  type        = list(string)
  default     = []
  description = "File paths that do not trigger CI/CD build."
}

# Container registry settings

variable "container_registry_immutable_tags" {
  type        = bool
  default     = true
  description = "If true, artifact registry tags are immutable. This may cause problems if you use the latest tag for docker caching."
}

# Monitoring settings

variable "uptime_regions" {
  type        = list(string)
  default     = ["EUROPE", "USA"]
  description = "The list of regions from which the uptime check will be run."
}

variable "uptime_channels" {
  type        = list(string)
  default     = []
  description = "SNS topics used to send alert notifications (e.g. \"arn:aws:sns:us-east-1:0123456789:my-zone-uptimez\")"
}

# Build info

variable "build_image_tag" {
  type        = string
  default     = ""
  description = "For example git commit hash (ddee8c8da71393b4b2ef95de507358abe54d7e78). Required if create_containers or create_functions is true."
}

# Resources as a json/yaml

variable "resources" {
  type = object({
    backupEnabled = optional(bool)
    uptimeEnabled = optional(bool)

    alerts = optional(list(object({
      name     = string
      type     = string
      channels = list(string)
      rule     = string
    })))

    auth = optional(object({
      serviceAccounts = optional(map(object({
        name     = optional(string)
        provider = optional(string)
        roles    = optional(list(string))
      })))

      permissions = optional(map(object({
        id       = optional(string)
        provider = optional(string)
        roles    = list(string)
      })))

      apis = optional(map(object({
        id       = optional(string)
        provider = optional(string)
      })))

      apiKeys = optional(map(object({
        name     = optional(string)
        provider = optional(string)
        origins  = optional(list(string))
        services = list(object({
          id      = string
          methods = optional(list(string))
        }))
      })))
    }))

    ingress = optional(object({
      class            = optional(string)
      enabled          = optional(bool, false)
      createMainDomain = optional(bool, false)
      domains = optional(list(object({
        name = string
        altDomains = optional(list(object({
          name = string
        })), [])
      })), [])
    }))

    services = optional(map(object({
      type        = string
      image       = optional(string)
      machineType = optional(string)
      name        = optional(string)
      location    = optional(string)

      cpuLimit    = optional(string)
      memoryLimit = optional(string)

      paths = optional(list(object({
        path = string
      })))

      # For databases
      zone                       = optional(string)
      cmekLocation               = optional(string)
      version                    = optional(string)
      edition                    = optional(string)
      tier                       = optional(string)
      maintenanceDay             = optional(number)
      maintenanceHour            = optional(number)
      backupStartTime            = optional(string)
      pointInTimeRecoveryEnabled = optional(bool)
      highAvailabilityEnabled    = optional(bool)
      publicIpEnabled            = optional(bool)
      authorizedNetworks         = optional(list(string))
      flags                      = optional(map(string), {})
      adminUsername              = optional(string)

      storageClass = optional(string)
      corsRules = optional(list(object({
        allowedOrigins = list(string)
        allowedMethods = optional(list(string))
        exposeHeaders  = optional(list(string))
        maxAgeSeconds  = optional(number)
      })))
      queues = optional(list(object({
        name   = string
        events = list(string)
      })))
      versioningEnabled               = optional(bool)
      hierarchicalNamespaceEnabled    = optional(bool, false)
      uniformBucketLevelAccessEnabled = optional(bool, true)
      publicAccessPreventionEnabled   = optional(bool, true)
      versioningRetainDays            = optional(number)
      lockRetainDays                  = optional(number)
      transitionRetainDays            = optional(number)
      transitionStorageClass          = optional(string)
      autoDeletionRetainDays          = optional(number)
      replicationBucket               = optional(string)
      backupRetainDays                = optional(number)
      backupLocation                  = optional(string)
      backupLock                      = optional(bool)
      admins = optional(list(object({
        id = string
      })))
      objectAdmins = optional(list(object({
        id = string
      })))
      objectViewers = optional(list(object({
        id = string
      })))
      replicas      = optional(number)
      minReplicas   = optional(number)
      maxReplicas   = optional(number)
      path          = optional(string)
      uptimePath    = optional(string)
      uptimeTimeout = optional(number)
      timeout       = optional(number)
      runtime       = optional(string)
      memoryRequest = optional(number)
      secrets       = optional(map(string), {})
      secretEnv     = optional(map(string), {})
      env           = optional(map(string), {})
      publishers = optional(list(object({
        id = string
      })))
      subscribers = optional(list(object({
        id = string
      })))

      cronJobs = optional(map(object({
        schedule     = string
        timeZone     = optional(string)
        shellCommand = string
        env          = optional(map(string), {})
        secretEnv    = optional(map(string), {})
      })), {})

      db = optional(object({
        useProxy = optional(bool, false)
        instance = optional(string)
      }), { useProxy = false })
    })))
  })
  description = "Resources as JSON (see README.md). You can read values from a YAML file with yamldecode()."
}
