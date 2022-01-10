# Lombiq NuGet Publishing Github Actions



## About

Add a general overview of the project here. Don't forget to update the year in the Licence! Keep or remove the OSOCE note below as necessary.

Do you want to quickly try out this project and see it in action? Check it out in our [Open-Source Orchard Core Extensions](https://github.com/Lombiq/Open-Source-Orchard-Core-Extensions) full Orchard Core solution and also see our other useful Orchard Core-related open-source projects!


## Documentation

Github actions shared between Lombiq projects.

Refer [Github actions reusable workflows](https://docs.github.com/en/actions/learn-github-actions/reusing-workflows#overview)

This includes two workflows that can be invoked through the `call-build-workflow` step.

- build.yml
- publish.yml


To add to a project create a folder from the root of the repository that will call these actions `.github/workflows/build.yml` or `.github/workflows/publish.yml`

Example `build.yml`

```
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
    uses: Lombiq/NuGet-Publishing-GitHub-Actions/.github/workflows/build.yml@v1
```

This workflow is triggered on push to `dev` and pull requests to `dev` and invokes the `build.yml` workflow from this repository. It takes no parameters.

Example `publish.yml`

```
name: publish

on:
  push:
    tags:
      - v*

jobs:
  call-publish-workflow:
    uses: Lombiq/NuGet-Publishing-GitHub-Actions/.github/workflows/publish.yml@v1
    secrets:
      apikey: ${{ secrets.LOMBIQ_NUGET_PUBLISH_API_KEY }}
```

The `publish.yml` workflow is triggered on a tag pushed to any branch with the prefix `v` and should contain a version number, i.e. `v1.0.1`, which will be extracted and used to version the NuGet packages produced.

It takes one non optional secret parameter `apikey`, the organization API key for pushing to NuGet, and one optional parameter, `source`

`source`
```
    uses: Lombiq/NuGet-Publishing-GitHub-Actions/.github/workflows/publish.yml@v1
    with:
      source: `custom-nuget-source-to-push-too`
```

When `source` is not provided, it assumes a default value of pushing to the [Lombiq nuget feed](https://www.nuget.org/profiles/Lombiq).


## Contributing and support

Bug reports, feature requests, comments, questions, code contributions, and love letters are warmly welcome, please do so via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.