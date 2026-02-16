# Open Pull Request

Opens a pull request from a source branch to a target branch in a repository. This can be used to automatically open pull requests e.g. in a fork to merge changes from a branch in the original repository to your branch.

The workflow automatically checks if there are any differences between the branches and if a pull request already exists, preventing duplicate PRs and unnecessary notifications.

```yaml
name: Keep Dev Up to Date

on:
  # Run manually.
  workflow_dispatch:
  # Run on the 1st of every month.
  schedule:
    - cron: 0 4 1 * *

jobs:
  keep-dev-up-to-date:
    name: Keep Dev Up to Date
    uses: Lombiq/GitHub-Actions/.github/workflows/open-pull-request.yml@dev
    secrets:
      CHECKOUT_TOKEN: ${{ secrets.YOUR_PERSONAL_ACCESS_TOKEN }}
    with:
      source-branch: main
      pull-request-body: >
        Add an optional pull request body here, like @mentioning a team or linking a related issue.
```

Setting `CHECKOUT_TOKEN` is only necessary if your repository has private submodules or if you want a specific user (not the github-actions bot) to be the author of the pull request.
