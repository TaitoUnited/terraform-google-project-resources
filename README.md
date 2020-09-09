# Google Cloud project resources

Provides Google Cloud resources typically required by projects. The resources are defined in a cloud provider agnostic and developer friendly YAML format. An example:

```
stack:
  uptimeEnabled: true
  backupEnabled: true

  ingress:
    class: gateway
    enabled: true
    createMainDomain: false
    domains:
      - name: myproject.mydomain.com
        altName: www.myproject.mydomain.com

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
      type: function # TODO: implement
      path: /api
      uptimePath: /api/uptimez
      timeout: 3
      runtime: nodejs12.x
      memoryRequest: 128
      secrets:
        SERVICE_ACCOUNT_KEY: my-project-prod-server-serviceaccount.key
        DATABASE_PASSWORD: my-project-prod-db-app.password
        REDIS_PASSWORD: my-project-prod-redis.password
      env:
        TOPIC_JOBS: my-project-prod-jobs
        DATABASE_HOST: my-postgres.c45t0ln04uqh.us-east-1.rds.amazonaws.com
        DATABASE_PORT: 5432
        DATABASE_SSL_ENABLED: true
        DATABASE_NAME: my-project-prod
        DATABASE_USER: my-project-prod-app
        DATABASE_POOL_MIN: 5
        DATABASE_POOL_MAX: 10
        REDIS_HOST: my-project-prod-001.my-project-prod.nde1c2.use1.cache.amazonaws.com
        REDIS_PORT: 6379
        STORAGE_BUCKET: my-project-prod

    worker:
      type: container # TODO: implement
      replicas: 2
      memoryRequest: 128
      secrets:
        SERVICE_ACCOUNT_KEY: my-project-prod-worker-serviceaccount.key
      env:
        TOPIC_JOBS: my-project-prod-jobs
        STORAGE_BUCKET: my-project-prod

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
      name: my-project-prod
      location: EU
      storageClass: STANDARD
      cors:
        - origin: https://myproject.mydomain.com
        - origin: https://www.myproject.mydomain.com
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

  serviceAccounts:
    - id: my-project-prod-server
    - id: my-project-prod-worker
```

With `create_*` variables you can choose which resources are created/updated in which phase. For example, you can choose to update some of the resources manually when the environment is created or updated:

```
  create_storage_buckets        = true
  create_databases              = true
  create_in_memory_databases    = true
  create_topics                 = true
  create_service_accounts       = true
  create_uptime_checks          = true
```

And choose to update gateway, containers, and functions on every deployment in your CI/CD pipeline:

```
  create_gateway                = true
  create_containers             = true
  create_functions              = true
  create_function_permissions   = true
```

Similar YAML format is used also by the following modules:

* [AWS project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/aws)
* [Azure project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/azurerm)
* [Google Cloud project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/google)
* [Digital Ocean project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/digitalocean)
* [Full-stack template (Helm chart for Kubernetes)](https://github.com/TaitoUnited/taito-charts/tree/master/full-stack)

This module creates only resources for one project. That is, such resources should already exist that are shared among multiple projects (e.g. users, roles, vpc networks, database clusters). You can create the shared infrastructure with the following modules. The modules are Kubernetes-oriented, but you can also choose to leave Kubernetes out.

* [AWS Kubernetes infrastructure](https://registry.terraform.io/modules/TaitoUnited/kubernetes-infrastructure/aws)
* [Azure Kubernetes infrastructure](https://registry.terraform.io/modules/TaitoUnited/kubernetes-infrastructure/azurerm)
* [Google Cloud Kubernetes infrastructure](https://registry.terraform.io/modules/TaitoUnited/kubernetes-infrastructure/google)
* [Digital Ocean Kubernetes infrastructure](https://registry.terraform.io/modules/TaitoUnited/kubernetes-infrastructure/digitalocean)

> TIP: This module is used by [project templates](https://taitounited.github.io/taito-cli/templates/#project-templates) of [Taito CLI](https://taitounited.github.io/taito-cli/). See the [full-stack-template](https://github.com/TaitoUnited/full-stack-template) as an example on how to use this module.
