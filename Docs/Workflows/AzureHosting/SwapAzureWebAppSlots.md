# Swap Azure Web App Slots

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
      # Defaults to destination-slot-name if not set, used for adding git tags to the deployed commit.
      tag-prefix: production
      # Defaults to source-slot-name if not set, used looking up the currently deployed commit by tag.
      swap-prefix: staging
      # The repository that hosts the code that will be swapped. This is necessary for adding tags and releases.
      app-code-repo: Lombiq/Lombiq-GitHub-Actions 
    secrets:
      AZURE_APP_SERVICE_SWAP_SERVICE_PRINCIPAL_ID: ${{ secrets.AZURE_APP_SERVICE_SWAP_SERVICE_PRINCIPAL_ID }}
      AZURE_APP_SERVICE_SWAP_AZURE_TENANT_ID: ${{ secrets.AZURE_APP_SERVICE_SWAP_AZURE_TENANT_ID }}
      AZURE_APP_SERVICE_SWAP_AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_APP_SERVICE_SWAP_AZURE_SUBSCRIPTION_ID }}
      # Needs to have access to create tags and releases in the target repository.
      CODE_REPOSITORY_WRITE_TOKEN: ${{ secrets.CODE_REPOSITORY_WRITE_TOKEN }}
```

To restrict who can edit or run the Swap workflow, we recommend putting into a separate repository independent of your application code. If you're [on the Enterprise plan, you can add required reviewers](https://github.com/orgs/community/discussions/26262) instead, so that not everyone is able to run a swap who has write access to the repository.

This workflow has an alternate version (_swap-orchard1-azure-web-app-slots.yml_) designed for Orchard 1-based applications.
