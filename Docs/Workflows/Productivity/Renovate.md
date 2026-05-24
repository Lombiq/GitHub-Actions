# Renovate

[Renovate](https://www.mend.io/renovate/) is a tool that updates dependencies automatically. It can update NuGet and NPM packages, GitHub Actions references, Python dependencies, and more.

This workflow wraps the [Renovate GitHub Action](https://github.com/renovatebot/github-action) to make it easier to use, especially in Lombiq projects, like below. During setup, be sure to configure it with a _renovate.json5_ configuration file ([see docs](https://docs.renovatebot.com/configuration-options/)); you can take inspiration from the [shared configuration we use at Lombiq](https://github.com/Lombiq/renovate-config) and the [Orchard Harvest talk about using Renovate](https://www.youtube.com/watch?v=P2jy8xuvqos).

> [!IMPORTANT]  
> Adjust `branches` to refer to the repo's default branch. The `CHECKOUT_TOKEN` should be set up to also enable Renovate to work, see [the docs](https://github.com/renovatebot/github-action?tab=readme-ov-file#token).

```yaml
name: Renovate

on:
  # Run manually.
  workflow_dispatch:
  # Run every Sunday at 4:00 AM.
  schedule:
    - cron: 0 4 * * 0
  # Run on pushes to dev when the Renovate configuration changes.
  push:
    branches:
      - dev
    paths:
      - renovate.json5

jobs:
  renovate:
    name: Renovate
    uses: Lombiq/GitHub-Actions/.github/workflows/renovate.yml@dev
    secrets:
      CHECKOUT_TOKEN: ${{ secrets.YOUR_CHECKOUT_TOKEN }}
```

<!-- textlint-disable doubled-spaces -->
> [!NOTE]
> There are some differences in behavior compared to the default that the workflow provides:
>
> - Only _renovate.json5_ configuration files in the root of the repository are supported.
> - The `schedule` and `prHourlyLimit` options coming from the `renovate.json5` configuration file are overridden, instead relying on the schedule of the workflow itself.
<!-- textlint-enable doubled-spaces -->

If Renovate is not doing what you expect it to do, you can increase the log level to `debug`, and see in the workflow output what happens:

```yaml
    with:
      log-level: debug
```

You can also specify reviewers that will be added to the PRs created by Renovate (if any other automation adds reviewers by default, these will be added to them):

```yaml
    with:
      additional-reviewers: GitHubUserName1, GitHubUserName2
```
