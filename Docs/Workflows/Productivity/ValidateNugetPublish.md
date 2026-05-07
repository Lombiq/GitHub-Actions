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

Unless you set `indicate-breaking-changes: 'false'`, failed package validation against the baseline will add the `breaking-changes` label, append "(⚠️ breaking changes)" to the pull request title, and post guidance in a comment. The marker and label are removed automatically if you add the `ignore-breaking-changes` label.

If you add a generated `CompatibilitySuppressions.xml` file to the project, then [`publish-nuget`](PublishNuGetPackage.md) will require the next non-prerelease publish to use a new major version, unless `require-major-version-for-compatibility-suppressions` is set to `'false'`.
