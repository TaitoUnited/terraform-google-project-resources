

output "cicd_service_account_id" {
  value = length(google_service_account.cicd_service_account) > 0 ? google_service_account.cicd_service_account[0].id : null
}
