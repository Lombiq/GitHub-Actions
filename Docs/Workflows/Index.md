# Reusable GitHub Actions workflows

These workflows can be invoked from a step from any other repository's workflow. The utilize [our composite actions](../Actions.md).

## General notes

- In addition to the short explanations and samples, check out the inline documentation of the workflow you want to use, especially its parameters. Those examples don't necessarily utilize all parameters.
- Workflows with a `cancel-workflow-on-failure` parameter will by default cancel all jobs in the workflow run when the given reusable workflow fails (to save computing resources). You can disable this by setting the parameter to `"false"`.
- To add the workflows to a project create a folder in the root of the repository that will call them, e.g. _.github/workflows/build-and-test.yml_ and/or _.github/workflows/publish-nuget.yml_. The examples below are for such files.
- If you use these workflows with a self-hosted runner, then you'll need to fork this repository under the organization while keeping [these rules](https://docs.github.com/en/actions/using-workflows/reusing-workflows#access-to-reusable-workflows) in mind. Then, you need to enable workflows for the fork under its Actions tab (you'll see a big button for this). If you don't do the latter step, you'll get a "workflow was not found" error. Then you can also disable the `spelling-this-repo` and `validate-this-gha-refs` workflows, not to run them unnecessarily if you sync the fork with the original repo.<!--#spell-check-ignore-line-->

## Workflow categories

- [.NET Core and Orchard Core builds](BuildDotNetCoreOrchardCore.md)
- [Productivity](Productivity.md)
- [Azure hosting](AzureHosting.md)