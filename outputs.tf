

output "cicd_service_account_email" {
  value = length(google_service_account.cicd_service_account) > 0 ? google_service_account.cicd_service_account[0].email : null
}
