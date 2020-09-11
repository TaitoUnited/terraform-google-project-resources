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

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {

  # Members

  members = try(
    var.create_members && var.resources.members != null ? var.resources.members : [], []
  )

  memberRoles = flatten([
    for member in keys(local.members) : [
      for role in member.roles:
      {
        role = role
        member = member.id
      }
    ]
  ])

  # Service accounts

  serviceAccounts = (
    var.create_service_accounts && try(var.resources.serviceAccounts, null) != null
    ? try(var.resources.serviceAccounts, [])
    : []
  )

  # APIs

  apis = try(
    var.create_apis && var.resources.apis != null ? var.resources.apis : [], []
  )

  # Alerts

  origAlerts = try(
    var.resources.alerts != null
    ? var.resources.alerts
    : [],
    []
  )

  alertChannelNames = flatten([
    for alert in local.origAlerts:
    try(alert.channels, [])
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
    try(alert.type, "") == "log" ? [ alert ] : []
  ])

  # Ingress

  ingress = try(var.resources.ingress, { enabled: false })

  domains = try(var.resources.ingress.domains, [])

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

  services = (
    try(var.resources.services, null) != null
    ? try(var.resources.services, {})
    : {}
  )

  servicesById = {
    for id, service in local.services:
    id => merge(service, { id: id })
  }

  uptimeEnabled = try(var.resources.uptimeEnabled, true)
  uptimeTargetsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_uptime_checks && local.uptimeEnabled && try(service.uptimePath, null) != null
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

  functionsForPermissionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_function_permissions && service.type == "function"
  }

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
    if var.create_ingress && local.ingress.enabled && service.type == "function" && try(service.path, "") != ""
  }

  ingressStaticContentsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.type == "static"
  }

  ingressRootStaticContentsById = {
    for name, service in local.ingressStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.path != null && try(service.path, "") == "/"
  }

  ingressChildStaticContentsById = {
    for name, service in local.ingressStaticContentsById:
    name => service
    if var.create_ingress && local.ingress.enabled && service.path != null && try(service.path, "") != "/"
  }

  ingressEnabled = length(concat(
    values(local.ingressFunctionsById),
    values(local.ingressStaticContentsById),
  )) > 0

}

data "google_project" "project" {
}
