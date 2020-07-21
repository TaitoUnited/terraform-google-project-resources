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

  serviceAccounts = (
    var.create_service_accounts && try(var.variables.serviceAccounts, null) != null
    ? try(var.variables.serviceAccounts, [])
    : []
  )

  ingress = try(var.variables.ingress, { enabled: false })

  domains = try(var.variables.ingress.domains, [])

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

  services = (
    try(var.variables.services, null) != null
    ? try(var.variables.services, {})
    : {}
  )

  servicesById = {
    for id, service in local.services:
    id => merge(service, { id: id })
  }

  uptimeEnabled = try(var.variables.uptimeEnabled, true)
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

  gatewayFunctionsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.type == "function" && try(service.path, "") != ""
  }

  gatewayStaticContentsById = {
    for name, service in local.servicesById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.type == "static"
  }

  gatewayRootStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.path != null && try(service.path, "") == "/"
  }

  gatewayChildStaticContentsById = {
    for name, service in local.gatewayStaticContentsById:
    name => service
    if var.create_gateway && local.ingress.enabled && service.path != null && try(service.path, "") != "/"
  }

  gatewayEnabled = length(concat(
    values(local.gatewayFunctionsById),
    values(local.gatewayStaticContentsById),
  )) > 0

}

data "google_project" "project" {
}
