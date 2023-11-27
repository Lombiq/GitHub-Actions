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
    secrets:
      AZURE_APP_SERVICE_DEPLOYMENT_SERVICE_PRINCIPAL_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_SERVICE_PRINCIPAL_ID }}
      AZURE_APP_SERVICE_DEPLOYMENT_AZURE_TENANT_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_AZURE_TENANT_ID }}
      AZURE_APP_SERVICE_DEPLOYMENT_AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_APP_SERVICE_DEPLOYMENT_AZURE_SUBSCRIPTION_ID }}
      AZURE_APP_SERVICE_PUBLISH_PROFILE: ${{ secrets.AZURE_APP_SERVICE_PUBLISH_PROFILE }}
```

If the app uses the [`Lombiq.Hosting.BuildVersionDisplay` module](https://github.com/Lombiq/Hosting-Build-Version-Display), then the workflow plays along with it: The module will display a link to the run.

This workflow has an alternate version (_deploy-orchard1-to-azure-app-service.yml_) designed for Orchard 1-based applications.
