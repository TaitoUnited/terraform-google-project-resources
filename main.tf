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
}

locals {

  # Projects

  project_id           = var.project_id

  cicd_project_id = (
    var.cicd_project_id != "" ? var.cicd_project_id : var.project_id
  )

  log_alert_project_id = (
    var.log_alert_project_id != "" ? var.log_alert_project_id : var.project_id
  )

  uptime_project_id = (
    var.uptime_project_id != "" ? var.uptime_project_id : var.project_id
  )

  # API keys

  apiKeysById = {
    for apiKey in coalesce(var.resources.apiKeys, []):
    "${apiKey.name}-${apiKey.provider}" => apiKey
    if var.create_api_keys && coalesce(apiKey.provider, "gcp") == "gcp"
  }

  # Service accounts

  serviceAccounts = (
    var.create_service_accounts
    ? coalesce(var.resources.serviceAccounts, [])
    : []
  )

  # Alerts

  origAlerts = coalesce(var.resources.alerts, [])

  alertChannelNames = flatten([
    for alert in local.origAlerts:
    coalesce(alert.channels, [])
  ])

  alerts = flatten([
    for alert in local.origAlerts:
    merge(alert, {
      channelIndices = [
        for channel in alert.channels:
        index(local.alertChannelNames, channel)
      ]
    })
  ])

  logAlerts = flatten([
    for alert in local.alerts:
    coalesce(alert.type, "") == "log" ? [ alert ] : []
  ])

  # Ingress

  ingress = merge({ enabled: false }, var.resources.ingress)

  domains = coalesce(var.resources.ingress.domains, [])

  mainDomains = [
    for domain in local.domains:
    join(".",
      slice(
        split(".", domain.name),
        length(split(".", domain.name)) > 2 ? 1 : 0,
        length(split(".", domain.name))
      )
    )
  ]

  # Services

  services = coalesce(var.resources.services, {})

  servicesById = {
    for id, service in local.services:
    id => merge(service, { id: id })
  }

  uptimeEnabled = coalesce(var.resources.uptimeEnabled, true)
  uptimeTargetsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_uptime_checks && local.uptimeEnabled && service.uptimePath != null
  }

  containersById = {
    for name, service in local.servicesById:
    name => service
    if var.create_containers && service.type == "container"
  }

  functionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_functions && service.type == "function"
  }

  # functionsForPermissionsById = {
  #   for name, service in local.servicesById:
  #   name => service
  #   if var.create_function_permissions && service.type == "function"
  # }

  databasesById = {
    for name, service in local.servicesById:
    name => service
    if var.create_databases && (service.type == "pg" || service.type == "mysql")
  }

  redisDatabasesById = {
    for name, service in local.servicesById:
    name => service
    if var.create_in_memory_databases && (service.type == "redis")
  }

  topicsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_topics && service.type == "topic"
  }

  bucketsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_storage_buckets && service.type == "bucket"
  }

  ingressFunctionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.type == "function" && service.path != null
  }

  ingressStaticContentsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.type == "static"
  }

  ingressRootStaticContentsById = {
    for name, service in local.ingressStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.path != null && coalesce(service.path, "") == "/"
  }

  ingressChildStaticContentsById = {
    for name, service in local.ingressStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.path != null && coalesce(service.path, "") != "/"
  }

  ingressEnabled = length(concat(
    values(local.ingressFunctionsById),
    values(local.ingressStaticContentsById),
  )) > 0

}
