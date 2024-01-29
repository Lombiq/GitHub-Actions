# Validate pull request

Validates pull requests for various criteria:

- Labels and comments on pull requests with merge conflicts.
- Adds a Jira-style issue code (e.g. PROJ-123) to the pull request's title, and a link to the Jira issue in the body if it's not there yet.

```yaml
name: Validate Pull Request

on:
  push:
  # You can use pull_request if this is for a private repo that can't be forked.
  pull_request_target:
    types: [opened, synchronize]

jobs:
  validate-pull-request:
    name: Validate Pull Request
    uses: Lombiq/GitHub-Actions/.github/workflows/validate-pull-request.yml@dev
```

If you get "Error: GraphqlError: Resource not accessible by integration" errors then also add the following permissions just below `uses`:<!--#spell-check-ignore-line-->

```yaml
    permissions:
      pull-requests: write
      repository-projects: read
```
