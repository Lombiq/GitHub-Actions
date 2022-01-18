# Lombiq NuGet Publishing Github Actions



## About

Github Actions shared between Lombiq projects, used to publish packages to NuGet.


## Documentation

This includes two workflows that can be invoked through the `call-build-workflow` step:

- _build.yml_: Builds the project with the .NET SDK.
- _publish.yml_: Builds the project with the .NET SDK and publishes it as a NuGet package to the configured NuGet feed.

To add to a project create a folder from the root of the repository that will call these actions, _.github/workflows/build.yml_ and/or _.github/workflows/publish.yml_.

Example _build.yml_:

```yaml
name: build

on:
  push:
    branches: [dev]
    paths-ignore:
      - "Docs/**"
      - "Readme.md"

  pull_request:
    branches: [dev]

jobs:
  call-build-workflow:
    uses: Lombiq/NuGet-Publishing-GitHub-Actions/.github/workflows/build.yml@dev
```

This workflow is triggered on push to `dev` and pull requests to `dev` and invokes the _build.yml_ workflow from this repository. It takes no parameters.

Example _publish.yml_:

```yaml
name: publish

on:
  push:
    tags:
      - v*

jobs:
  call-publish-workflow:
    uses: Lombiq/NuGet-Publishing-GitHub-Actions/.github/workflows/publish.yml@dev
    secrets:
      apikey: ${{ secrets.LOMBIQ_NUGET_PUBLISH_API_KEY }}
```

The _publish.yml_ workflow is triggered on a tag pushed to any branch with the prefix `v` and should contain a version number, e.g. `v1.0.1`, which will be extracted and used to version the NuGet packages produced.

It takes one non-optional secret parameter, `apikey`, the organization API key for pushing to NuGet, and one optional parameter, `source`:

```yaml
    uses: Lombiq/NuGet-Publishing-GitHub-Actions/.github/workflows/publish.yml@v1
    with:
      source: `custom-nuget-source-to-push-too`
```

When `source` is not provided, it assumes a default value of pushing to the [Lombiq NuGet feed](https://www.nuget.org/profiles/Lombiq).

Refer to [Github Actions reusable workflows](https://docs.github.com/en/actions/learn-github-actions/reusing-workflows#overview) for more information.


## Contributing and support

Bug reports, feature requests, comments, questions, code contributions, and love letters are warmly welcome, please do so via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.
