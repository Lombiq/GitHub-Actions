# Reusable GitHub Actions workflows

These workflows can be invoked from a step from any other repository's workflow. The utilize [our composite actions](Actions.md).

## General notes

- In addition to the below short explanations and samples, check out the inline documentation of the workflow you want to use, especially its parameters. These examples don't necessarily utilize all parameters.
- Workflows with a `cancel-workflow-on-failure` parameter will by default cancel all jobs in the workflow run when the given reusable workflow fails (to save computing resources). You can disable this by setting the parameter to `"false"`.
- To add the workflows to a project create a folder in the root of the repository that will call them, e.g. _.github/workflows/build-and-test.yml_ and/or _.github/workflows/publish-nuget.yml_. The examples below are for such files.
- If you use these workflows with a self-hosted runner, then you'll need to fork this repository under the organization while keeping [these rules](https://docs.github.com/en/actions/using-workflows/reusing-workflows#access-to-reusable-workflows) in mind. Then, you need to enable workflows for the fork under its Actions tab (you'll see a big button for this). If you don't do the latter step, you'll get a "workflow was not found" error.

## Build and Test Orchard Core solution workflow

Meant to be used with [Orchard Core](https://orchardcore.net/) solutions; this workflow checks out the code, installs dependencies, builds the solution, runs unit and UI tests (with [Lombiq UI Testing Toolbox for Orchard Core](https://github.com/Lombiq/UI-Testing-Toolbox)), and publishes artifacts as well as a test report.

For an example of this, see below and the workflow of [Lombiq's Open-Source Orchard Core Extensions](https://github.com/Lombiq/Open-Source-Orchard-Core-Extensions).

```yaml
name: Build and Test

# Runs for PRs opened for any branch, and pushes to the dev branch.
on:
  pull_request:
  push:
    branches:
      - dev

jobs:
  build-and-test:
    name: Build and Test
    uses: Lombiq/GitHub-Actions/.github/workflows/build-and-test-orchard-core.yml@dev
    with:
      timeout-minutes: 60
```

## Build and Test .NET solution workflow

Builds a .NET solution (or project) with static code analysis, and runs tests with a test report like `build-and-test-orchard-core`. You can use it along the lines of the following:

```yaml
name: Build and Test

# Runs for PRs opened for any branch, and pushes to the dev branch.
on:
  pull_request:
  push:
    branches:
      - dev

jobs:
  build-and-test:
    name: Build and Test
    uses: Lombiq/GitHub-Actions/.github/workflows/build-and-test-dotnet.yml@dev
    with:
      machine-types: "['ubuntu-22.04', 'windows-2022']"
      timeout-minutes: 10
```

## Spelling workflow

Checks for spelling mistakes in a repository using the [Check Spelling](https://github.com/marketplace/actions/check-spelling) GitHub Action, proxied by the [`spelling` action](../.github/actions/spelling/action.yml) in this repository, which has [its own documentation](SpellCheckingConfiguration.md) describing the configuration options and contribution guidelines. This documentation is also linked automatically at the end of every spell-checking report of a pull request.

### How to integrate spell-checking into a project

1. Start by adding a job to an existing workflow or create one specific to spell-checking with the minimum configuration.
2. Push the changes and open a pull request to have the initial spell-checking report commented to it.
3. Follow the [spell-checking configuration tips](SpellCheckingConfiguration.md) to work through the list of unrecognized entries.
4. You will probably end up with a few configuration files and some external dictionaries applied, so your workflow might end up looking something like the complete example below.

#### Minimum spell-checking step configuration example

```yaml
  spelling:
    name: Spelling
    uses: Lombiq/GitHub-Actions/.github/workflows/spelling.yml@dev
```

#### Complete spell-checking workflow example

```yaml
name: Spelling

on:
  pull_request:
  push:
    branches:
      - dev

jobs:
  spelling:
    name: Spelling
    uses: Lombiq/GitHub-Actions/.github/workflows/spelling.yml@dev
    with:
      # Add this parameter to define further dictionary source prefixes, such as a repository with general-purpose dictionaries. Dictionary files from these sources are processed before the default ones, and in the order their prefixes are listed here.
      additional-configuration-source-prefixes: >
        {
          "other-project": "https://raw.githubusercontent.com/Other/Project/dev/.github/actions/spelling/",
        }
      # Use this parameter to list the external dictionary files to use, but beware that check-spelling only accepts flat lists of words (so, for example patterns.txt can't be referenced like this). The order doesn't matter, but sorting it alphabetically makes it easier to maintain. The "cspell" and "lombiq-lgha" prefixes are available by default - see the spelling action for their exact path.
      additional-dictionaries: |
        cspell:csharp/csharp.txt
        other-project:my-dictionary.txt
```

## NuGet publish workflow

Builds the project with the .NET SDK and publishes it as a NuGet package to the configured NuGet feed. Example _publish.yml_:

```yaml
name: Publish to NuGet

on:
  push:
    tags:
      - v*

jobs:
  publish-nuget:
    name: Publish to NuGet
    uses: Lombiq/GitHub-Actions/.github/workflows/publish-nuget.yml@dev
    secrets:
      apikey: ${{ secrets.DEFAULT_NUGET_PUBLISH_API_KEY }}
```

The _publish.yml_ workflow is triggered on a tag pushed to any branch with the prefix `v` and should contain a [valid version number](https://docs.microsoft.com/en-us/nuget/concepts/package-versioning#version-basics), e.g. `v1.0.1`, which will be extracted and used to version the NuGet packages produced.

There is no configuration required for automated Orchard Core extension manifest versioning, all of the `Manifest.cs` files are looked up, and the existing `Version` properties are updated automatically inside the `Module` or `Theme` definition with the version pushed. Note that the `Version` property should be present and leave the version number on the default value (0.0.1). This is because we don't actually need to keep manifest version changes in the code.

It takes one non-optional secret parameter, `apikey`, the organization API key for pushing to NuGet, and two optional parameters, `source` and `verbosity`. E.g.:

```yaml
jobs:
  publish-nuget:
    name: Publish to NuGet
    uses: Lombiq/GitHub-Actions/.github/workflows/publish-nuget.yml@dev
    with:
      source: https://nuget.cloudsmith.io/lombiq/open-source-orchard-core-extensions/v3/index.json
      verbosity: detailed
    secrets:
      apikey: ${{ secrets.CLOUDSMITH_NUGET_PUBLISH_API_KEY }}
```

When `source` is not provided, it assumes a default value of pushing to the [Lombiq NuGet feed](https://www.nuget.org/profiles/Lombiq).

Valid values for `verbosity` are those defined by [MSBuild](https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2022#:~:text=you%20can%20specify%20the%20following%20verbosity%20levels). The default value is `minimal`.

 Things to keep in mind:

- If you have multiple projects in the repository or if the project you want to build is in a subfolder, then add a solution to the root of the repository that references all projects you want to build.
- References to projects (`<ProjectReference>` elements) not in the repository won't work, these need to be changed to package references (`<PackageReference>` elements). Make the conditional based on `$(NuGetBuild)`. See the [Helpful Extensions project file](https://github.com/Lombiq/Helpful-Extensions/blob/dev/Lombiq.HelpfulExtensions/Lombiq.HelpfulExtensions.csproj) for an example. References to projects in the repository will work and those projects, if configured with the proper metadata, will be published together, with dependencies retained among the packages too.

## Submodule validate workflow

Validates pull requests in submodule repositories for various criteria:

- Adds a Jira-style issue code (e.g. PROJ-123) to the pull request's title, and a link to the Jira issue in the body if it's not there yet.
- Checks if a pull request exists in the parent repository.

Example _validate-pull-request.yml_:

```yaml
name: Validate Pull Request

on:
  pull_request:

jobs:
  validate-pull-request:
    name: Validate Pull Request
    uses: Lombiq/GitHub-Actions/.github/workflows/validate-submodule-pull-request.yml@dev
    with:
      repository: Lombiq/Hastlayer-SDK
```

If this is for a submodule of [Lombiq's Open-Source Orchard Core Extensions](https://github.com/Lombiq/Open-Source-Orchard-Core-Extensions/), the `repo` input can be omitted, because the above is its default value. Otherwise, use your parent repository's address in the `{owner}/{repo_name}` format.

Refer to [Github Actions reusable workflows](https://docs.github.com/en/actions/learn-github-actions/reusing-workflows#overview) for more information.

## Deploy to Azure App Service workflow

This workflow builds and publishes a .NET web project and then deploys the app to [Azure App Service](https://azure.microsoft.com/en-us/services/app-service/). Requires [the repository to have an environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with a name that matches the `slot-name` parameter. The workflow also supports [Ready to Run compilation](https://learn.microsoft.com/en-us/dotnet/core/deploying/ready-to-run). [Release annotations](https://learn.microsoft.com/en-us/azure/azure-monitor/app/annotations) are added to the corresponding Azure Application Insights resource. Example _deploy-to-azure-app-service.yml_:

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

## Validate Pull Request workflow

Validates pull requests for various criteria:

- Labels and comments on pull requests with merge conflicts.
- Adds a Jira-style issue code (e.g. PROJ-123) to the pull request's title, and a link to the Jira issue in the body if it's not there yet.

```yaml
name: Validate Pull Request

on:
  push:
  pull_request:
    types: [opened, synchronize]

jobs:
  validate-pull-request:
    name: Validate Pull Request
    uses: Lombiq/GitHub-Actions/.github/workflows/validate-pull-request.yml@dev
```

If you get "Error: GraphqlError: Resource not accessible by integration" errors then also add the following permissions just below `uses`:

```yaml
    permissions:
      pull-requests: write
      repository-projects: read
```

## Jira issue creation for community activities workflow

Creates Jira issues for community activities happening on GitHub, like issues, discussions, and pull requests being opened. Pull requests are only taken into account if they're not already related to a Jira issue (by starting their title with a Jira issue key).

Set up secrets for the `JIRA_*` parameters as explained [here](https://github.com/marketplace/actions/jira-login#enviroment-variables). You may use secret names without the `DEFAULT_*` prefix, but that's our recommendation for organization-level secrets, so you have defaults but can override them on a per-repository basis.

The secrets with the `*_JIRA_ISSUE_DESCRIPTION` suffix should contain templates for the Jira issues to be created, using the internal markup format of Jira (not Markdown). Example for one for `ISSUE_JIRA_ISSUE_DESCRIPTION`:

```text
h1. Summary
See the linked GitHub issue, including all the comments.

h1. Checklist
* Assign yourself to the referenced GitHub issue.
* [Issue completion checklist|https://example.com/checklist]
```

All three templates are optional and if not provided, defaults will be used. Note that it's important to use the `pull_request_target` trigger instead of `pull_request` because the latter doesn't trigger for pull requests from forks, defeating the whole purpose of this workflow.

```yaml
name: Create Jira issues for community activities

on:
  discussion:
    types: [created]
  issues:
    types: [opened]
  pull_request_target:
    types: [opened]

jobs:
  create-jira-issues-for-community-activities:
    name: Create Jira issues for community activities
    uses: Lombiq/GitHub-Actions/.github/workflows/create-jira-issues-for-community-activities.yml@dev
    secrets:
      JIRA_BASE_URL: ${{ secrets.DEFAULT_JIRA_BASE_URL }}
      JIRA_USER_EMAIL: ${{ secrets.DEFAULT_JIRA_USER_EMAIL }}
      JIRA_API_TOKEN: ${{ secrets.DEFAULT_JIRA_API_TOKEN }}
      JIRA_PROJECT_KEY: ${{ secrets.DEFAULT_JIRA_PROJECT_KEY }}
      DISCUSSION_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_DISCUSSION_JIRA_ISSUE_DESCRIPTION }}
      ISSUE_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_ISSUE_JIRA_ISSUE_DESCRIPTION }}
      PULL_REQUEST_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_PULL_REQUEST_JIRA_ISSUE_DESCRIPTION }}
    with:
      issue-component: Lombiq.MyProject

```

## Reset Azure Environment workflow

This workflow resets an Azure Environment, by replacing the Orchard Core Media Library and the Database with the ones from a given source slot. Requires [the repository to have an environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with a name that matches the `destination-slot-name` parameter. Optionally, [release annotations](https://learn.microsoft.com/en-us/azure/azure-monitor/app/annotations) can be added to the corresponding Azure Application Insights resource. Example _reset-azure-environment.yml_:

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
    secrets:
      AZURE_APP_SERVICE_RESET_SERVICE_PRINCIPAL_ID: ${{ secrets.AZURE_APP_SERVICE_RESET_SERVICE_PRINCIPAL_ID }}
      AZURE_APP_SERVICE_RESET_AZURE_TENANT_ID: ${{ secrets.AZURE_APP_SERVICE_RESET_AZURE_TENANT_ID }}
      AZURE_APP_SERVICE_RESET_AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_APP_SERVICE_RESET_AZURE_SUBSCRIPTION_ID }}
```

## Swap Azure Web App Slots workflow

This workflow swaps two Azure Web App Slots associated with an Azure Web App. Requires [the repository to have an environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with a name that matches the `destination-slot-name` parameter. [Release annotations](https://learn.microsoft.com/en-us/azure/azure-monitor/app/annotations) are added to the corresponding Azure Application Insights resource. Example _swap-azure-web-app-slots.yml_:

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

## Post Pull Request Checks Automation

Various automation that should be run after all other checks succeeded for a pull request. Currently does the following:

- Merges the current pull request if the "merge-and-resolve-jira-issue-if-checks-succeed" or "merge-if-checks-succeed" label is present. With prerequisite jobs you can execute this only if all others jobs have succeeded. Unlike [GitHub's auto-merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request), this works without branch protection rules.
- Resolves the Jira issue corresponding to the pull request if the "resolve-jira-issue-if-checks-succeed" or "merge-and-resolve-jira-issue-if-checks-succeed" label is present, or sets the issue to Done if the "done-jira-issue-if-checks-succeed" label is.

See an example of how you can utilize this workflow, together with jobs that do other checks below. For configuring the `JIRA_*` secrets see the documentation of `create-jira-issues-for-community-activities` above, and for details on `MERGE_TOKEN` check out the workflow's inline documentation.

```yaml
name: Build and Test

on:
  pull_request:
  push:
    branches:
      - dev

jobs:
  build-and-test:
    name: Build and Test
    uses: Lombiq/GitHub-Actions/.github/workflows/build-and-test-orchard-core.yml@dev

  spelling:
    name: Spelling
    uses: Lombiq/GitHub-Actions/.github/workflows/spelling.yml@dev

  post-pull-request-checks-automation:
    name: Post Pull Request Checks Automation
    needs: [build-and-test, spelling]
    if: github.event.pull_request != ''
    uses: Lombiq/GitHub-Actions/.github/workflows/post-pull-request-checks-automation.yml@dev
    secrets:
      JIRA_BASE_URL: ${{ secrets.DEFAULT_JIRA_BASE_URL }}
      JIRA_USER_EMAIL: ${{ secrets.DEFAULT_JIRA_USER_EMAIL }}
      JIRA_API_TOKEN: ${{ secrets.DEFAULT_JIRA_API_TOKEN }}
      MERGE_TOKEN: ${{ secrets.DEFAULT_MERGE_TOKEN }}
```
