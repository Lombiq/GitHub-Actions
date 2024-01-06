# Build and Test .NET solution

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
