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

resource "google_logging_metric" "log_alert_metric" {
  count      = var.create_log_alert_metrics ? length(local.logAlerts) : 0
  project    = local.log_alert_project_id

  name   = local.logAlerts[count.index].name
  filter = local.logAlerts[count.index].rule
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
