/**
 * Copyright 2022 Taito United
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

resource "google_apikeys_key" "api_key" {
  for_each  = {for item in local.apiKeysById: item.id => item}

  name         = each.value.name
  display_name = each.value.name

  restrictions {
    dynamic "api_targets" {
      for_each = {for item in each.value.services: item.name => item}
      content {
        service = api_targets.value.name
        methods = coalesce(api_targets.value.methods, ["GET*"])
      }
    }

    browser_key_restrictions {
      allowed_referrers = coalesce(each.value.origins, [])
    }
  }
}