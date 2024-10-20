# Composite GitHub Actions actions

These actions can be invoked from a step in any other repository's workflow. They're utilized by [our reusable workflows](Workflows.md).

In addition to the below short explanations, check out the inline documentation of the action you want to use, especially its parameters.

## .NET Core and Orchard Core builds

- `build-dotnet`: Builds all .NET solutions or projects in the given directory with optional static code analysis.
- `install-dotnet-tool`: Installs a tool globally into the .NET CLI by its name and version number.
- `setup-dotnet`: Sets up the .NET SDK.
- `verify-dotnet-consolidation`: Verifies that the NuGet packages of a .NET solution are consolidated, i.e. the same version of a given package is used in all projects.
- `test-dotnet`: Runs .NET unit and UI tests (with the [Lombiq UI Testing Toolbox for Orchard Core](https://github.com/Lombiq/UI-Testing-Toolbox)), generates a test report, and uploads UI testing failure dumps to artifacts.

## .NET Framework and Orchard 1 builds

- `msbuild`: Builds a .NET Framework project or solution in the given directory with optional static code analysis.
- `precompile-orchard1-app`: Publishes an Orchard 1 application using the Precompiled build target through Orchard.proj. Also provides optional parameters for checking out the repository at a specific ref and destination path.

## Build tools

- `install-sqlcmd`: Installs the [SQL Server command-line tools](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility) on Linux runners, which is necessary since the Ubuntu 24.04 runner image no longer includes it.
- `enable-corepack`: Enables [Node corepack](https://nodejs.org/docs/latest-v16.x/api/corepack.html) so any package manager can be used seamlessly.
- `setup-sql-server`: Sets up SQL Server with Lombiq-recommended defaults.

## Productivity

- `auto-merge-pull-request`: Merges the current pull request automatically if the "merge-and-resolve-jira-issue-if-checks-succeed" or "merge-if-checks-succeed" label is present.
- `auto-transition-jira-issue`: Resolves the Jira issue corresponding to the pull request if the "resolve-jira-issue-if-checks-succeed" or "merge-and-resolve-jira-issue-if-checks-succeed" label is present, or sets the issue to Done if the "done-jira-issue-if-checks-succeed" label is.
- `cancel-workflow`: Cancels the current workflow run, i.e. all jobs. Useful if you want to cancel the rest of the workflow when one job fails. Suitable workflows in this project expose this functionality via the `cancel-workflow-on-failure` parameter.
- `check-merge-conflict`: Labels and comments on pull requests with merge conflicts.
- `create-jira-issues-for-community-activities`: Creates Jira issues for community activities happening on GitHub, like issues, discussions, and pull requests being opened. Pull requests are only taken into account if they're not already related to a Jira issue (by starting their title with a Jira issue key).
- `markdown-lint`: Checks for linting errors in markdown files, allowing for an optional configuration file to be used. Based on the [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2-action) action.
- `publish-nuget`: Publishes the content of the current directory as a NuGet package.
- `update-github-issue-and-pull-request`: Adds the Jira issue key prefix and link to pull requests as well as a Fixes reference to a GitHub issue, if a suitable one is found.
- `verify-submodule-pull-request`: Assuming that the current repository is a submodule in another repository, this action verifies that a pull request with a matching issue code has been opened there as well.
- `spelling`: Checks for spelling mistakes in a repository. Check out [this action's own documentation](SpellCheckingConfiguration.md) on how to use it and contribute to the configuration and dictionaries.
- `yaml-lint`: Checks for linting errors in YAML-files, allowing for an optional configuration file to be used.

## Azure hosting

- `add-azure-application-insights-release-annotation`: Can be used to add [release annotations in Azure Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/annotations), to mark when a new version of an app was rolled out to a given environment.
- `setup-azurite`: Sets up the [Azurite Azure Blob Storage Emulator](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite) via NPM.
