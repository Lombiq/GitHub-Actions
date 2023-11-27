# Build and Test Orchard Core solution

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
