# Validate NuGet Publish

Validates the NuGet publishing process without actually pushing the package to NuGet or creating a GitHub release. Useful to check if the project is still publishable, and didn't get an unexpected breaking change. Example validate-nuget-publish.yml_:

```yaml
name: Validate NuGet Publish

on:
  pull_request:
    push:
      branches:
        - dev

jobs:
  validate-nuget-publish:
    name: Validate NuGet Publish
    uses: Lombiq/GitHub-Actions/.github/workflows/validate-nuget-publish.yml@dev
```

The workflow otherwise takes the same configuration options as [`publish-nuget`](PublishNuGetPackage.md), but doesn't require the `API_KEY` secret.
