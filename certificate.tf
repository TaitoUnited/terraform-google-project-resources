# TODO: do these with terraform:
# 
# - Create Google-managed certificate on Google Cloud web console: https://cloud.google.com/certificate-manager/docs/deploy-google-managed-lb-auth#console
# - Attach it to the `common-kube` certificate map with `gcloud` util, for example: `gcloud certificate-manager maps entries create acme-app-dev --map="common-kube" --certificates="acme-app-dev" --hostname="acme-app-dev.mydomain.com" --project acme-gcp-prod`

