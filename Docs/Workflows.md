# Reusable GitHub Actions workflows

These workflows can be invoked from a step from any other repository's workflow. The utilize [our composite actions](../Actions.md).

## General notes

- In addition to the short explanations and samples, check out the inline documentation of the workflow you want to use, especially its parameters. Those examples don't necessarily utilize all parameters.
- Workflows with a `cancel-workflow-on-failure` parameter will by default cancel all jobs in the workflow run when the given reusable workflow fails (to save computing resources). You can disable this by setting the parameter to `"false"`.
- To add the workflows to a project create a folder in the root of the repository that will call them, e.g. _.github/workflows/build-and-test.yml_ and/or _.github/workflows/publish-nuget.yml_. The examples below are for such files.
- If you use these workflows with a self-hosted runner, then you'll need to fork this repository under the organization while keeping [these rules](https://docs.github.com/en/actions/using-workflows/reusing-workflows#access-to-reusable-workflows) in mind. Then, you need to enable workflows for the fork under its Actions tab (you'll see a big button for this). If you don't do the latter step, you'll get a "workflow was not found" error. Then you can also disable the `spelling-this-repo` and `validate-this-gha-refs` workflows, not to run them unnecessarily if you sync the fork with the original repo.<!--#spell-check-ignore-line-->

## .NET Core and Orchard Core builds

- [Build and Test .NET solution](BuildDotNetCoreOrchardCore/BuildAndTestDotNetSolution.md)
- [Build and Test Orchard Core solution](BuildDotNetCoreOrchardCore/BuildAndTestOrchardCoreSolution.md)

## Productivity

- [Create Jira issues for community activities](Productivity/CreateJiraIssuesForCommunityActivities.md)
- [Post-pull request checks automation](Productivity/PostPullRequestChecksAutomation.md)
- [Publish NuGet package](Productivity/PublishNuGetPackage.md)
- [Spell-checking](Productivity/SpellChecking.md)
- [Validate pull request](Productivity/ValidatePullRequest.md)
- [Validate submodule](Productivity/ValidateSubmodule.md)

## Azure hosting

### Azure hosting general notes

- They run in a [concurrency group](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency) composed using the `app-name` parameter to prevent them from running at the same time (and/or multiple instances).
- They require [the repository to have an environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with a name that matches the `slot-name` or `destination-slot-name` (whichever applies) parameter.
- Optionally, [release annotations](https://learn.microsoft.com/en-us/azure/azure-monitor/app/annotations) can be added to an Azure Application Insights resource by defining passing in its ID in the `application-insights-resource-id` parameter.

### Azure hosting workflows

- [Deploy to Azure App Service](AzureHosting/DeployToAzureAppService.md)
- [Reset Azure Environment](AzureHosting/ResetAzureEnvironment.md)
- [Swap Azure Web App Slots](AzureHosting/SwapAzureWebAppSlots.md)
