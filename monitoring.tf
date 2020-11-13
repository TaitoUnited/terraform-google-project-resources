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

data "google_monitoring_notification_channel" "log_alert_channel" {
  for_each     = {for item in local.alertChannelNames: item => item}
  project      = local.log_alert_project_id
  display_name = each.value
}

# TODO: Add support for log metric absence

resource "google_monitoring_alert_policy" "log_alert_policy" {
  depends_on = [
    google_logging_metric.log_alert_metric,
  ]
  for_each   = {for item in (var.create_log_alert_policies ? local.logAlerts : []): item.name => item}
  project    = local.log_alert_project_id

  display_name          = each.value.name
  enabled               = true
  notification_channels = [
    for i in each.value.channelIndices:
    data.google_monitoring_notification_channel.log_alert_channel[i].name
  ]

  combiner     = "OR"
  conditions {
    display_name = each.value.name
    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/${each.value.name}\" AND resource.type=\"k8s_container\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}
