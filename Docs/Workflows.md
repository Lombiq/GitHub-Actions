# Reusable GitHub Actions workflows

These workflows can be invoked from a step from any other repository's workflow. The utilize [our composite actions](Actions.md).

## General notes

- In addition to the short explanations and samples, check out the inline documentation of the workflow you want to use, especially its parameters. Those examples don't necessarily utilize all parameters.
- To add the workflows to a project create a folder in the root of the repository that will call them, e.g. _.github/workflows/build-and-test.yml_ and/or _.github/workflows/publish-nuget.yml_. The examples below are for such files.
- If you use these workflows with a self-hosted runner, then you'll need to fork this repository under the organization while keeping [these rules](https://docs.github.com/en/actions/using-workflows/reusing-workflows#access-to-reusable-workflows) in mind. Then, you need to enable workflows for the fork under its Actions tab (you'll see a big button for this). If you don't do the latter step, you'll get a "workflow was not found" error. Then you can also disable the `spelling-this-repo` and `validate-this-gha-refs` workflows, not to run them unnecessarily if you sync the fork with the original repo.<!--#spell-check-ignore-line-->

## Saving on computing resources

These features are designed to reduce resource usage (like paid GitHub Actions minutes) by cancelling workflows/jobs under specific circumstances and are enabled by default. They can be disabled by setting the value of the corresponding parameter to anything other than `'true'`.

- Workflows with the `cancel-workflow-on-failure` parameter will by default cancel all jobs in the workflow run when the given reusable workflow fails.
- When running under a pull request, some of the long-running jobs (for example solution builds and spell-checking) will by default be cancelled when a subsequent commit triggers them again. This is based on the [concurrency](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency) feature and governed by the `cancel-in-progress-for-this-pr` parameter.
  - If you have multiple parent workflows running in parallel that both have a job calling the same reusable workflow, make sure that their display names are different from each other, because the `github.workflow` context variable is also used in the construction of the concurrency key to be able to distinguish such jobs.
  - Some of these workflows (mainly solution builds) also have an optional `parent-job-name` parameter. Use this to distinguish different jobs in the same parent workflow that call the same reusable workflow, otherwise they will conflict with each other.

## .NET Core and Orchard Core builds

- [Build and Test .NET solution](Workflows/BuildDotNetCoreOrchardCore/BuildAndTestDotNetSolution.md)
- [Build and Test Orchard Core solution](Workflows/BuildDotNetCoreOrchardCore/BuildAndTestOrchardCoreSolution.md)

## Productivity

- [Create Jira issues for community activities](Workflows/Productivity/CreateJiraIssuesForCommunityActivities.md)
- [Post-pull request checks automation](Workflows/Productivity/PostPullRequestChecksAutomation.md)
- [Publish NuGet package](Workflows/Productivity/PublishNuGetPackage.md)
- [Spell-checking](Workflows/Productivity/SpellChecking.md)
- [Validate pull request](Workflows/Productivity/ValidatePullRequest.md)
- [Validate submodule](Workflows/Productivity/ValidateSubmodule.md)
- [Lint YAML files](Workflows/Productivity/YamlLinting.md)

## Azure hosting

### Azure hosting general notes

- They run in a [concurrency group](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency) composed using the `app-name` parameter to prevent them from running at the same time (and/or multiple instances).
- They require [the repository to have an environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with a name that matches the `slot-name` or `destination-slot-name` (whichever applies) parameter.
- Optionally, [release annotations](https://learn.microsoft.com/en-us/azure/azure-monitor/app/annotations) can be added to an Azure Application Insights resource by defining passing in its ID in the `application-insights-resource-id` parameter.

### Azure hosting workflows

- [Deploy to Azure App Service](Workflows/AzureHosting/DeployToAzureAppService.md)
- [Reset Azure Environment](Workflows/AzureHosting/ResetAzureEnvironment.md)
- [Swap Azure Web App Slots](Workflows/AzureHosting/SwapAzureWebAppSlots.md)
