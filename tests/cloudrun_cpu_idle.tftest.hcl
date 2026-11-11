# Plan-only tests with mocked providers: no credentials or infrastructure required.
mock_provider "google" {
  mock_data "google_project" {
    defaults = { number = "123456789012" }
  }

  mock_data "google_service_account" {
    defaults = { email = "test@test-project.iam.gserviceaccount.com" }
  }

  mock_data "google_compute_network" {
    defaults = { id = "projects/test-project/global/networks/test-vpc" }
  }

  mock_data "google_compute_subnetwork" {
    defaults = { id = "projects/test-project/regions/europe-west1/subnetworks/test-subnet" }
  }
}

mock_provider "google-beta" {}
mock_provider "random" {}

override_module {
  target = module.admin
  outputs = {
    apis = []
  }
}

override_module {
  target  = module.databases
  outputs = {}
}

variables {
  project                   = "test"
  env                       = "dev"
  target_env                = "dev"
  project_id                = "test-project"
  region                    = "europe-west1"
  zone                      = "europe-west1-b"
  vpc_name                  = "test-vpc"
  vpc_container_subnet_name = "test-subnet"
  create_containers         = true

  resources = {
    ingress = {}
    services = {
      request_based = {
        type        = "container"
        image       = "example.com/test/server:latest"
        cpuIdle     = true
        cpuLimit    = "2"
        memoryLimit = "1Gi"
        minReplicas = 0
        maxReplicas = 1
        paths       = [{ path = "/api" }]
        cronJobs = {
          daily = {
            schedule           = "0 0 * * *"
            shellCommand       = "./cli.sh daily"
            taskTimeoutSeconds = 900
          }
        }
      }
      always_allocated = {
        type    = "container"
        image   = "example.com/test/worker:latest"
        cpuIdle = false
      }
      omitted = {
        type     = "container"
        image    = "example.com/test/legacy:latest"
        replicas = 2
        cronJobs = {
          legacy = {
            schedule     = "0 1 * * *"
            shellCommand = "./cli.sh legacy"
          }
        }
      }
      null_value = {
        type    = "container"
        image   = "example.com/test/null:latest"
        cpuIdle = null
      }
    }
  }
}

run "per_service_cpu_allocation" {
  command = plan

  assert {
    condition     = google_cloud_run_v2_service.container["request_based"].template[0].containers[0].resources[0].cpu_idle == true
    error_message = "Explicit cpuIdle = true must enable request-based CPU allocation."
  }

  assert {
    condition = alltrue([
      for name in ["always_allocated", "omitted", "null_value"] :
      google_cloud_run_v2_service.container[name].template[0].containers[0].resources[0].cpu_idle == false
    ])
    error_message = "False, omitted, and null cpuIdle must preserve always-allocated CPU independently of other services."
  }

  assert {
    condition = (
      google_cloud_run_v2_service.container["request_based"].template[0].scaling[0].min_instance_count == 0 &&
      google_cloud_run_v2_service.container["request_based"].template[0].scaling[0].max_instance_count == 1
    )
    error_message = "Request-based CPU allocation must preserve minReplicas = 0 and maxReplicas = 1."
  }

  assert {
    condition = alltrue([
      for name, count in { always_allocated = 1, omitted = 2, null_value = 1 } :
      google_cloud_run_v2_service.container[name].template[0].scaling[0].min_instance_count == count &&
      google_cloud_run_v2_service.container[name].template[0].scaling[0].max_instance_count == count
    ])
    error_message = "Other services must retain default scaling and the replicas fallback."
  }

  assert {
    condition = alltrue([
      for name, service in google_cloud_run_v2_service.container :
      service.template[0].containers[0].resources[0].limits == tomap({
        cpu    = name == "request_based" ? "2" : "1"
        memory = name == "request_based" ? "1Gi" : "512Mi"
      })
    ])
    error_message = "CPU allocation must preserve explicit and default service resource limits."
  }

  assert {
    condition = alltrue([
      for name, service in google_cloud_run_v2_service.container :
      service.ingress == (name == "request_based" ? "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" : "INGRESS_TRAFFIC_INTERNAL_ONLY") &&
      service.invoker_iam_disabled == (name != "request_based") &&
      service.template[0].vpc_access[0].egress == "PRIVATE_RANGES_ONLY" &&
      service.template[0].vpc_access[0].network_interfaces[0].network == "projects/test-project/global/networks/test-vpc" &&
      service.template[0].vpc_access[0].network_interfaces[0].subnetwork == "projects/test-project/regions/europe-west1/subnetworks/test-subnet"
    ])
    error_message = "CPU allocation must preserve ingress, invoker, and VPC settings."
  }

  assert {
    condition = alltrue([
      for name, job in google_cloud_run_v2_job.cronjob :
      job.template[0].template[0].containers[0].resources[0].limits == tomap({
        cpu    = name == "daily" ? "2" : "1"
        memory = name == "daily" ? "1Gi" : "512Mi"
      }) &&
      job.template[0].template[0].timeout == (name == "daily" ? "900s" : "600s") &&
      job.template[0].template[0].containers[0].command == tolist(["sh", "-c", "./cli.sh ${name}"]) &&
      job.template[0].template[0].vpc_access[0].egress == "PRIVATE_RANGES_ONLY"
    ])
    error_message = "Jobs on opted-in and existing services must retain their limits, timeout, command, and networking."
  }

  assert {
    condition = (
      length(google_cloud_run_v2_service.container) == 4 &&
      length(google_cloud_run_v2_job.cronjob) == 2 &&
      google_cloud_scheduler_job.scheduler["daily"].schedule == "0 0 * * *" &&
      google_cloud_scheduler_job.scheduler["legacy"].schedule == "0 1 * * *" &&
      alltrue([
        for name, scheduler in google_cloud_scheduler_job.scheduler :
        scheduler.time_zone == "Etc/UTC" &&
        scheduler.http_target[0].uri == "https://run.googleapis.com/v2/projects/test-project/locations/europe-west1/jobs/test-dev-${name}:run" &&
        google_cloud_run_v2_job_iam_member.scheduler[name].role == "roles/run.invoker"
      ])
    )
    error_message = "All services and scheduled jobs must still be planned with existing scheduling and invocation settings."
  }
}
