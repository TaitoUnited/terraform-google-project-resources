# Requires Terraform >= 1.9 for plan-time mock values. Run with:
# terraform init -backend=false
# terraform test -filter=tests/scheduler_iam.tftest.hcl
# All runs only plan with mocked providers; no GCP credentials or state are used.
mock_provider "google" {
  override_during = plan

  mock_resource "google_service_account" {
    defaults = {
      name  = "projects/scheduler-test/serviceAccounts/owned-scheduler@scheduler-test.iam.gserviceaccount.com"
      email = "owned-scheduler@scheduler-test.iam.gserviceaccount.com"
    }
  }

  # Deliberately distinct from the owned account to catch data-source lookups.
  mock_data "google_service_account" {
    defaults = {
      name  = "projects/scheduler-test/serviceAccounts/existing@scheduler-test.iam.gserviceaccount.com"
      email = "existing@scheduler-test.iam.gserviceaccount.com"
    }
  }
}

mock_provider "google-beta" {}
mock_provider "random" {}

variables {
  project                   = "fluxio"
  env                       = "test"
  target_env                = "test"
  project_id                = "scheduler-test"
  region                    = "europe-north1"
  zone                      = "europe-north1-a"
  vpc_name                  = "test-vpc"
  vpc_container_subnet_name = "test-subnet"

  resources = {
    ingress = {}
    services = {
      worker = {
        type  = "container"
        image = "example.com/worker:test"
        cronJobs = {
          avaa-sync = {
            schedule     = "0 * * * *"
            shellCommand = "echo sync"
          }
          cleanup = {
            schedule           = "0 0 * * *"
            shellCommand       = "echo cleanup"
            taskTimeoutSeconds = 1200
          }
        }
      }
    }
  }
}

run "persistent_infrastructure" {
  command = plan

  variables {
    create_cicd_service_account  = true
    create_container_permissions = true
    create_containers            = false
  }

  assert {
    condition     = keys(google_service_account_iam_member.cicd_iam_scheduler_service_account_user) == ["avaa-sync", "cleanup"]
    error_message = "Persistent infrastructure must retain the existing IAM resource keys for both cron jobs."
  }

  assert {
    condition = alltrue([
      for key, grant in google_service_account_iam_member.cicd_iam_scheduler_service_account_user :
      grant.service_account_id == google_service_account.scheduler[key].name &&
      grant.role == "roles/iam.serviceAccountUser"
    ])
    error_message = "CI/CD must receive serviceAccountUser on each scheduler account owned by this root."
  }

  assert {
    condition = (
      length(data.google_service_account.scheduler) == 0 &&
      length(google_cloud_run_v2_service.container) == 0 &&
      length(google_cloud_run_v2_job.cronjob) == 0 &&
      length(google_cloud_run_v2_job_iam_member.scheduler) == 0 &&
      length(google_cloud_scheduler_job.scheduler) == 0
    )
    error_message = "Persistent infrastructure must plan without scheduler lookups or container deployment."
  }
}

run "application_deployment" {
  command = plan

  variables {
    create_cicd_service_account  = false
    create_container_permissions = false
    create_containers            = true
  }

  assert {
    condition = (
      length(google_service_account.scheduler) == 0 &&
      length(google_service_account_iam_member.cicd_iam_scheduler_service_account_user) == 0 &&
      keys(data.google_service_account.scheduler) == ["avaa-sync", "cleanup"] &&
      keys(google_cloud_run_v2_job_iam_member.scheduler) == ["avaa-sync", "cleanup"] &&
      keys(google_cloud_scheduler_job.scheduler) == ["avaa-sync", "cleanup"]
    )
    error_message = "Application deployment must use existing scheduler accounts without owning CI/CD grants."
  }

  assert {
    condition = alltrue([
      for key, grant in google_cloud_run_v2_job_iam_member.scheduler :
      grant.name == google_cloud_run_v2_job.cronjob[key].name &&
      grant.role == "roles/run.invoker" &&
      grant.member == "serviceAccount:${data.google_service_account.scheduler[key].email}" &&
      google_cloud_scheduler_job.scheduler[key].http_target[0].oauth_token[0].service_account_email == data.google_service_account.scheduler[key].email
    ])
    error_message = "Invoker grants and schedule OAuth tokens must reference the existing scheduler identities."
  }

  assert {
    condition = (
      google_cloud_run_v2_job.cronjob["avaa-sync"].template[0].template[0].timeout == "600s" &&
      google_cloud_run_v2_job.cronjob["cleanup"].template[0].template[0].timeout == "1200s"
    )
    error_message = "Cron jobs must preserve the 600-second default and explicit taskTimeoutSeconds."
  }
}

run "cicd_without_container_permissions" {
  command = plan

  variables {
    create_cicd_service_account  = true
    create_container_permissions = false
    create_containers            = false
  }

  assert {
    condition = (
      length(google_service_account.scheduler) == 0 &&
      length(google_service_account_iam_member.cicd_iam_scheduler_service_account_user) == 0
    )
    error_message = "CI/CD alone must not grant access to scheduler accounts this root does not own."
  }
}
