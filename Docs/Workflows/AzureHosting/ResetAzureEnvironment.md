# Reset Azure Environment

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
