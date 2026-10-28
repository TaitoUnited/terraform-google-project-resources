# Google Cloud project resources

Provides Google Cloud resources typically required by projects. The resources are defined in a cloud provider agnostic and developer friendly YAML format. An example:

```
backupEnabled: true
uptimeEnabled: true

alerts:
  - name: my-project-prod-errors
    type: log
    channels: [ "my-channel" ]
    rule: >
      resource.type="k8s_container"
      resource.labels.namespace_name="my-project-prod"
      severity>=ERROR

auth:
  apis:
    - id: compute.googleapis.com
    - id: run.googleapis.com
    - id: secretmanager.googleapis.com
    - id: servicenetworking.googleapis.com
    - id: certificatemanager.googleapis.com
    - id: sqladmin.googleapis.com
    - id: cloudbuild.googleapis.com

  apiKeys:
    - name: my-project-prod-client
      origins: [ "https://myproject.mydomain.com" ]
      services:
        - name: maps.googleapis.com
          methods: ["GET*"]

  serviceAccounts:
    - name: my-project-prod-server
    - name: my-project-prod-worker
      roles: [ "roles/cloudkms.publicKeyViewer" ]

  permissions:
    - id: "serviceAccount:service-GCP_PROJECT_NUMBER@serverless-robot-prod.iam.gserviceaccount.com"
      roles: ["roles/artifactregistry.reader"]

ingress:
  class: gateway
  enabled: true
  createMainDomain: false
  domains:
    - name: myproject.mydomain.com
      altDomains:
        - name: www.myproject.mydomain.com

services:
  admin:
    type: static # TODO: implement
    path: /admin
    uptimePath: /admin

  client:
    type: static # TODO: implement
    path: /
    uptimePath: /

  server:
    type: container
    path: /api
    uptimePath: /api/uptimez
    timeout: 3
    secrets:
      SERVICE_ACCOUNT_KEY: my-project-prod-server-serviceaccount.key
      DATABASE_PASSWORD: my-project-prod-db-app.password
      REDIS_PASSWORD: my-project-prod-redis.password
    db:
      useProxy: true
      instance: myinfra:europe-west1:my-project-postgres
    env:
      DATABASE_HOST: /cloudsql/myinfra:europe-west1:my-project-postgres
      DATABASE_PORT: 5432
      DATABASE_SSL_ENABLED: true
      DATABASE_NAME: my-project-prod
      DATABASE_USER: my-project-prod-app
      DATABASE_POOL_MIN: 5
      DATABASE_POOL_MAX: 10
      REDIS_HOST: my-project-prod-001.my-project-prod.nde1c2.use1.cache.amazonaws.com
      REDIS_PORT: 6379
      TOPIC_JOBS: my-project-prod-jobs
      STORAGE_BUCKET: my-project-prod
      SOME_SERVICE_URL: https://my-project-prod-generator-GCP_PROJECT_NUMBER.europe-west1.run.app
    cronJobs:
      daily:
        schedule: "0 0 * * *"
        timeZone: Europe/Helsinki
        shellCommand: ./cli.sh daily
        env:
          ERP_URL: https://myerp.com
          ERP_USERNAME: erp
        secretEnv:
          ERP_PASSWORD: my-project-prod-erp.password

  worker:
    type: container
    image: my-registry/my-worker:1234
    replicas: 2
    memoryRequest: 128
    db:
      useProxy: true
      instance: my-infra-dev:europe-west1:common-postgres
    secrets:
      SERVICE_ACCOUNT_KEY: my-project-prod-worker-serviceaccount.key
    env:
      TOPIC_JOBS: my-project-prod-jobs
      STORAGE_BUCKET: my-project-prod
      DATABASE_HOST: /cloudsql/my-infra-dev:europe-west1:common-postgres

  jobs:
    type: topic # TODO: implement
    name: my-project-prod-jobs
    publishers:
      - id: my-project-prod-server
    subscribers:
      - id: my-project-prod-worker

  redis:
    type: redis # TODO: implement
    name: my-project-prod
    replicas: 1
    machineType: TODO
    secret: my-project-prod-redis.secretKey

  bucket:
    type: bucket
    name: my-bucket-prod
    location: EU
    storageClass: STANDARD
    corsRules:
      - allowedOrigins:
        - https://myproject.mydomain.com
        - https://www.myproject.mydomain.com
        allowedMethods: ["GET", "HEAD", "PUT"]
    queues: # TODO: implement
      - name: my-bucket-prod
        events:
          - ...
          - ...
    # Access
    uniformBucketLevelAccessEnabled: true
    publicAccessPreventionEnabled: true
    # Special
    hierarchicalNamespaceEnabled: false
    # Object lifecycle
    versioningEnabled: true
    versioningRetainDays: 60
    lockRetainDays: # TODO: implement
    transitionRetainDays:
    transitionStorageClass:
    autoDeletionRetainDays:
    # Replication (TODO: implement)
    replicationBucket:
    # Backup (TODO: implement)
    backupRetainDays: 60
    backupLocation: EU
    backupLock: true
    # User rights
    admins:
      - id: user:john.doe@mydomain.com
    objectAdmins:
      - id: user:john.doe@mydomain.com
      - id: serviceAccount:my-project-prod-server
      - id: serviceAccount:my-project-prod-worker
    objectViewers:
      - id: user:john.doe@mydomain.com

  database:
    # postgres or mysql
    type: postgres
    name: my-project-postgres
    # Set cmekLocation only if you want cmek to be enabled for this database instance
    cmekLocation: europe-west1
    region: europe-west1
    zone: europe-west1-b
    version: POSTGRES_18
    edition: ENTERPRISE
    tier: db-custom-1-3840
    maintenanceDay: 2
    maintenanceHour: 2
    backupStartTime: 05:00
    pointInTimeRecoveryEnabled: true
    highAvailabilityEnabled: false
    publicIpEnabled: false
    authorizedNetworks:
      - 127.127.127.127/32
    flags:
      log_min_duration_statement: 1000
    adminUsername: admin
```

With `create_*` variables you can choose which resources are created/updated in which phase. For example, you can choose to update some of the resources manually when the environment is created or updated:

```
  # Resources shared between environments are created only once in each GCP project
  create_apis                         = true
  create_permissions                  = true
  create_network                      = true
  create_databases                    = true
  create_in_memory_databases          = true

  # All environments typically use the same container image repository
  create_container_image_repositories = true

  # Environment specific resources typically applied manually
  create_build_trigger                = true
  create_cicd_service_account         = true
  create_service_accounts             = true
  create_api_keys                     = true
  create_ingress_certificate_map      = true
  create_ingress                      = true
  create_container_permissions        = true
  create_functions_permissions        = true
  create_storage_buckets              = true
  create_topics                       = true
  create_log_alert_metrics            = true
  create_log_alert_policies           = true
  create_uptime_checks                = true
```

And choose to update ingress, containers, and functions on every deployment in your CI/CD pipeline:

```
  # Environment specific resources created during CI/CD deploy
  create_ingress_routes               = true
  create_ingress_certificate          = true
  create_containers                   = true
  create_functions                    = true
```

Similar YAML format is used also by the following modules:

- [AWS project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/aws)
- [Azure project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/azurerm)
- [Google Cloud project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/google)
- [Digital Ocean project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/digitalocean)
- [Full-stack template (Helm chart for Kubernetes)](https://github.com/TaitoUnited/taito-charts/tree/master/full-stack)

NOTE: This module creates resources for only one project environment. That is, such resources should already exist that are shared among multiple projects or project environments (e.g. users, roles, vpc networks, kubernetes, database clusters). You can use the following modules to create the shared infrastructure:

- [Admin](https://registry.terraform.io/modules/TaitoUnited/admin/google)
- [DNS](https://registry.terraform.io/modules/TaitoUnited/dns/google)
- [Network](https://registry.terraform.io/modules/TaitoUnited/network/google)
- [Compute](https://registry.terraform.io/modules/TaitoUnited/compute/google)
- [Kubernetes](https://registry.terraform.io/modules/TaitoUnited/kubernetes/google)
- [Databases](https://registry.terraform.io/modules/TaitoUnited/databases/google)
- [Storage](https://registry.terraform.io/modules/TaitoUnited/storage/google)
- [Monitoring](https://registry.terraform.io/modules/TaitoUnited/monitoring/google)
- [Integrations](https://registry.terraform.io/modules/TaitoUnited/integrations/google)
- [PostgreSQL privileges](https://registry.terraform.io/modules/TaitoUnited/privileges/postgresql)
- [MySQL privileges](https://registry.terraform.io/modules/TaitoUnited/privileges/mysql)

> TIP: This module is used by [project templates](https://taitounited.github.io/taito-cli/templates/#project-templates) of [Taito CLI](https://taitounited.github.io/taito-cli/). See the [full-stack-template](https://github.com/TaitoUnited/full-stack-template) as an example on how to use this module.

Contributions are welcome! This module should include implementations for the most commonly used Google services. For more specific cases, the YAML can be extended with additional Terraform modules.
