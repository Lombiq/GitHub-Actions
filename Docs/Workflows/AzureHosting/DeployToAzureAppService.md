# Deploy to Azure App Service

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
      # Defaults to 'staging' if not set, used for adding git tags to the deployed commit.
      tag-prefix: staging
    secrets:
      AZURE_APP_SERVICE_DEPLOYMENT_SERVICE_PRINCIPAL_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_SERVICE_PRINCIPAL_ID }}
      AZURE_APP_SERVICE_DEPLOYMENT_AZURE_TENANT_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_AZURE_TENANT_ID }}
      AZURE_APP_SERVICE_DEPLOYMENT_AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_AZURE_SUBSCRIPTION_ID }}
      AZURE_APP_SERVICE_PUBLISH_PROFILE: ${{ secrets.AZURE_APP_SERVICE_PUBLISH_PROFILE }}
```

Note that to be able to download the publish profile, and for the workflow to work, you'll need [SCM Basic Auth Publishing Credentials](https://learn.microsoft.com/en-us/azure/app-service/configure-basic-auth-disable?tabs=portal) to be turned **on** for the App Service.

If the app uses the [`Lombiq.Hosting.BuildVersionDisplay` module](https://github.com/Lombiq/Hosting-Build-Version-Display), then the workflow plays along with it: The module will display a link to the run.

This workflow has an alternate version (_deploy-orchard1-to-azure-app-service.yml_) designed for Orchard 1-based applications.
