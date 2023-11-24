# Azure hosting workflows

- They run in a [concurrency group](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency) composed using the `app-name` parameter to prevent them from running at the same time (and/or multiple instances).
- They require [the repository to have an environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with a name that matches the `slot-name` or `destination-slot-name` (whichever applies) parameter.
- Optionally, [release annotations](https://learn.microsoft.com/en-us/azure/azure-monitor/app/annotations) can be added to an Azure Application Insights resource by defining passing in its ID in the `application-insights-resource-id` parameter.

## Deploy to Azure App Service workflow

This workflow builds and publishes a .NET web project and then deploys the app to [Azure App Service](https://azure.microsoft.com/en-us/services/app-service/). The workflow also supports [Ready to Run compilation](https://learn.microsoft.com/en-us/dotnet/core/deploying/ready-to-run). Example _deploy-to-azure-app-service.yml_:

```yaml
name: Deploy to Azure App Service

on:
  workflow_dispatch:

jobs:
  deploy-to-azure-app-service:
    name: Deploy to Azure App Service
    uses: Lombiq/GitHub-Actions/.github/workflows/deploy-to-azure-app-service.yml@dev
    with:
      timeout-minutes: 60
      app-name: AppName
      resource-group-name: ResourceGroupName
      # This is also the default slot name but here's how you can configure it.
      slot-name: Staging
      url: https://www.myapp.com
      runtime: win-x86
      self-contained: true
      ready-to-run: true
      application-insights-resource-id: "Azure resource ID of the corresponding AI resource"
    secrets:
      AZURE_APP_SERVICE_DEPLOYMENT_SERVICE_PRINCIPAL_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_SERVICE_PRINCIPAL_ID }}
      AZURE_APP_SERVICE_DEPLOYMENT_AZURE_TENANT_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_AZURE_TENANT_ID }}
      AZURE_APP_SERVICE_DEPLOYMENT_AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_AZURE_SUBSCRIPTION_ID }}
      AZURE_APP_SERVICE_PUBLISH_PROFILE: ${{ secrets.AZURE_APP_SERVICE_PUBLISH_PROFILE }}
```

If the app uses the [`Lombiq.Hosting.BuildVersionDisplay` module](https://github.com/Lombiq/Hosting-Build-Version-Display), then the workflow plays along with it: The module will display a link to the run.

This workflow has an alternate version (_deploy-orchard1-to-azure-app-service.yml_) designed for Orchard 1-based applications.

## Reset Azure Environment workflow

This workflow resets an Azure Environment, by replacing the Orchard Core Media Library and the Database with the ones from a given source slot. Example _reset-azure-environment.yml_:

```yaml
name: Reset Azure Environment

on:
  workflow_dispatch:

jobs:
  reset-azure-environment:
    name: Reset Azure Environment
    uses: Lombiq/GitHub-Actions/.github/workflows/reset-azure-environment.yml@dev
    with:
      timeout-minutes: 60
      app-name: AppName
      resource-group-name: ResourceGroupName
      # These are also the default slot names but here's how you can configure them.
      source-slot-name: Production
      destination-slot-name: Staging
      database-connection-string-name: Database__ConnectionString
      master-database-connection-string-name: Database__ConnectionString-master
      storage-connection-string-name: Storage_ConnectionString
      application-insights-resource-id: "Azure resource ID of the corresponding AI resource"
    secrets:
      AZURE_APP_SERVICE_RESET_SERVICE_PRINCIPAL_ID: ${{ secrets.AZURE_APP_SERVICE_RESET_SERVICE_PRINCIPAL_ID }}
      AZURE_APP_SERVICE_RESET_AZURE_TENANT_ID: ${{ secrets.AZURE_APP_SERVICE_RESET_AZURE_TENANT_ID }}
      AZURE_APP_SERVICE_RESET_AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_APP_SERVICE_RESET_AZURE_SUBSCRIPTION_ID }}
```

## Swap Azure Web App Slots workflow

This workflow swaps two Azure Web App Slots associated with an Azure Web App. Example _swap-azure-web-app-slots.yml_:

```yaml
name: Swap Azure Web App Slots

on:
  workflow_dispatch:

jobs:
  swap-azure-web-app-slots:
    name: Swap Azure Web App Slots
    uses: Lombiq/GitHub-Actions/.github/workflows/swap-azure-web-app-slots.yml@dev
    with:
      timeout-minutes: 10
      app-name: AppName
      resource-group-name: ResourceGroupName
      # These are also the default slot names but here's how you can configure them.
      source-slot-name: Staging
      destination-slot-name: Production
      application-insights-resource-id: "Azure resource ID of the corresponding AI resource"
    secrets:
      AZURE_APP_SERVICE_SWAP_SERVICE_PRINCIPAL_ID: ${{ secrets.AZURE_APP_SERVICE_SWAP_SERVICE_PRINCIPAL_ID }}
      AZURE_APP_SERVICE_SWAP_AZURE_TENANT_ID: ${{ secrets.AZURE_APP_SERVICE_SWAP_AZURE_TENANT_ID }}
      AZURE_APP_SERVICE_SWAP_AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_APP_SERVICE_SWAP_AZURE_SUBSCRIPTION_ID }}
```

To restrict who can edit or run the Swap workflow, we recommend putting into a separate repository independent of your application code. If you're [on the Enterprise plan, you can add required reviewers](https://github.com/orgs/community/discussions/26262) instead, so that not everyone is able to run a swap who has write access to the repository.

This workflow has an alternate version (_swap-orchard1-azure-web-app-slots.yml_) designed for Orchard 1-based applications.
