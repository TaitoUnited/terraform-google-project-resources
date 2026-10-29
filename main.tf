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

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # TODO: remove if causes trouble
  billing_project       = var.project_id
  user_project_override = true
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # TODO: remove if causes trouble
  billing_project       = var.project_id
  user_project_override = true
}

data "google_project" "project" {
  project_id = var.project_id
}

locals {

  # Projects

  project_id                    = var.project_id
  infra_project_id              = coalesce(var.infra_project_id, local.project_id)
  container_registry_project_id = coalesce(var.container_registry_project_id, var.infra_project_id, local.project_id)

  cicd_project_id = coalesce(var.cicd_project_id, var.infra_project_id, var.project_id)

  log_alert_project_id = (
    var.log_alert_project_id != null && var.log_alert_project_id != "" ? var.log_alert_project_id : var.project_id
  )

  uptime_project_id = (
    var.uptime_project_id != null && var.uptime_project_id != "" ? var.uptime_project_id : var.project_id
  )

  # Admin stuff

  permissionsById = {
    for id, item in coalesce(try(var.resources.auth.permissions, {}), {}) :
    "${coalesce(item.id, id)}-${coalesce(item.provider, "gcp")}" => merge(item, { id = coalesce(item.id, id) })
    if var.create_permissions && coalesce(item.provider, "gcp") == "gcp"
  }

  apisById = {
    for id, item in coalesce(try(var.resources.auth.apis, {}), {}) :
    "${coalesce(item.id, id)}-${coalesce(item.provider, "gcp")}" => merge(item, { id = coalesce(item.id, id) })
    if var.create_apis && coalesce(item.provider, "gcp") == "gcp"
  }

  # Service accounts

  serviceAccountsById = var.use_legacy_service_accounts ? {} : {
    for name, item in coalesce(try(var.resources.auth.serviceAccounts, {}), {}) :
    var.use_legacy_naming ? name : "${coalesce(item.name, name)}-${coalesce(item.provider, "gcp")}" => merge(item, { name = coalesce(item.name, name) })
    if var.create_service_accounts && coalesce(item.provider, "gcp") == "gcp"
  }

  legacyServiceAccountsById = var.use_legacy_service_accounts ? {
    for name, acc in coalesce(try(var.resources.auth.serviceAccounts, {}), {}) :
    var.use_legacy_naming ? name : "${coalesce(acc.name, name)}-${coalesce(acc.provider, "gcp")}" => merge(acc, { name = coalesce(acc.name, name) })
    if var.create_service_accounts && coalesce(acc.provider, "gcp") == "gcp"
  } : {}

  legacyServiceAccountRoles = flatten([
    for id, serviceAccount in local.legacyServiceAccountsById : [
      for role in serviceAccount.roles :
      {
        id             = id
        role           = role
        serviceAccount = serviceAccount
      }
    ]
  ])

  legacyServiceAccountRolesByKey = {
    for r in local.legacyServiceAccountRoles :
    "${r.id}-${r.role}" => r
  }

  # API keys

  apiKeysById = {
    for name, apiKey in coalesce(try(var.resources.auth.apiKeys, {}), {}) :
    "${coalesce(apiKey.name, name)}-${coalesce(apiKey.provider, "gcp")}" => merge(apiKey, { name = coalesce(apiKey.name, name) })
    if var.create_api_keys && coalesce(apiKey.provider, "gcp") == "gcp"
  }

  # Alerts

  origAlerts = coalesce(var.resources.alerts, [])

  alertChannelNames = flatten([
    for alert in local.origAlerts :
    coalesce(alert.channels, [])
  ])

  alerts = flatten([
    for alert in local.origAlerts :
    merge(alert, {
      channelIndices = [
        for channel in alert.channels :
        index(local.alertChannelNames, channel)
      ]
    })
  ])

  logAlerts = flatten([
    for alert in local.alerts :
    coalesce(alert.type, "") == "log" ? [alert] : []
  ])

  # Ingress

  ingress = merge({ enabled : false }, var.resources.ingress)

  domains = coalesce(var.resources.ingress.domains, [])

  allDomainNames = compact(flatten([
    for domain in local.domains : concat(
      [domain.name],
      [for alt in domain.altDomains : alt.name]
    )
  ]))

  mainDomains = [
    for domain in local.domains :
    join(".",
      slice(
        split(".", domain.name),
        length(split(".", domain.name)) > 2 ? 1 : 0,
        length(split(".", domain.name))
      )
    )
  ]

  # PR and canary env support: If target_env is different from env,
  # the target_env doesn't own the url map
  envOwnsIngressUrlMap = coalesce(var.target_env, var.env) == var.env

  # Services

  services = coalesce(var.resources.services, {})

  servicesById = {
    for id, service in local.services :
    id => merge(service, { id : id })
  }

  uptimeEnabled = coalesce(var.resources.uptimeEnabled, true)
  uptimeTargetsById = {
    for name, service in local.servicesById :
    name => service
    if var.create_uptime_checks && local.uptimeEnabled && service.uptimePath != null
  }

  containersById = {
    for name, service in local.servicesById :
    name => merge(service, { id = name })
    if service.type == "container"
  }

  containerSecretsById = {
    for secret in flatten([
      for containerId, container in local.containersById : [
        for envName, secretName in merge(container.secrets, container.secretEnv) :
        {
          id          = "${containerId}-${secretName}"
          containerId = containerId
          envName     = envName
          secretName  = secretName
        }
      ]
    ]) : secret.id => secret
  }

  containerCronJobsById = {
    for cronjob in flatten([
      for containerId, container in local.containersById : [
        for name, spec in coalesce(try(container.cronJobs, null), {}) :
        merge(spec, { id = name, name = name, container = container })
      ]
    ]) : cronjob.id => cronjob
  }

  functionsById = {
    for name, service in local.servicesById :
    name => service
    if service.type == "function"
  }

  # functionsForPermissionsById = {
  #   for name, service in local.servicesById:
  #   name => service
  #   if var.create_function_permissions && service.type == "function"
  # }

  # Services with ingress

  ingressContainersById = {
    for id, container in local.containersById :
    id => container
    if var.create_ingress_routes && local.ingress.enabled && length(coalesce(try(container.paths, null), [])) > 0
  }

  ingressContainerPathsById = {
    for item in flatten([
      for containerId, container in local.ingressContainersById : [
        for item in container.paths :
        {
          id          = "${containerId}-${item.path}"
          containerId = containerId
          path        = item.path
        }
      ]
    ]) : item.id => item
  }

  # Cloud run

  cloudRunEnabled = length(local.containersById) > 0 || length(local.containerCronJobsById) > 0

  # Databases

  postgresDatabasesById = {
    for name, service in local.servicesById :
    name => merge(service, { region : service.location })
    if var.create_databases && service.type == "postgres"
  }

  mysqlDatabasesById = {
    for name, service in local.servicesById :
    name => merge(service, { region : service.location })
    if var.create_databases && service.type == "mysql"
  }

  redisDatabasesById = {
    for name, service in local.servicesById :
    name => service
    if var.create_in_memory_databases && (service.type == "redis")
  }

  topicsById = {
    for name, service in local.servicesById :
    name => service
    if var.create_topics && service.type == "topic"
  }

  bucketsById = {
    for name, service in local.servicesById :
    name => service
    if var.create_storage_buckets && service.type == "bucket"
  }
}

module "admin" {
  source  = "TaitoUnited/admin/google"
  version = "3.3.0"

  project_id = local.project_id

  permissions      = values(local.permissionsById)
  service_accounts = values(local.serviceAccountsById)
  apis             = values(local.apisById)
}

module "databases" {
  depends_on = [
    module.admin.apis,
    google_service_networking_connection.private_vpc_connection,
  ]

  source  = "TaitoUnited/databases/google"
  version = "3.5.0"

  postgresql_clusters = values(local.postgresDatabasesById)
  mysql_clusters      = values(local.mysqlDatabasesById)

  private_network_id = try(data.google_compute_network.vpc[0].id, "private_network_id_not_set")
}
