# Post-pull request checks automation

Various automation that should be run after all other checks succeeded for a pull request. Currently does the following:

- Merges the current pull request if the "merge-and-resolve-jira-issue-if-checks-succeed" or "merge-if-checks-succeed" label is present. With prerequisite jobs you can execute this only if all others jobs have succeeded. Unlike [GitHub's auto-merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request), this works without branch protection rules.
- Resolves the Jira issue corresponding to the pull request if the "resolve-jira-issue-if-checks-succeed" or "merge-and-resolve-jira-issue-if-checks-succeed" label is present, or sets the issue to Done if the "done-jira-issue-if-checks-succeed" label is.

## Prerequisites

You'll need to configure `JIRA_*` secrets first. See the [documentation of `create-jira-issues-for-community-activities`](CreateJiraIssuesForCommunityActivities.md) for details.

## Setup

See an example of how you can utilize this workflow, together with jobs that do other checks below. For details on `MERGE_TOKEN` check out the workflow's inline documentation.

```yaml
name: Build and Test

on:
  pull_request:
  push:
    branches:
      - dev

jobs:
  build-and-test:
    name: Build and Test
    uses: Lombiq/GitHub-Actions/.github/workflows/build-and-test-orchard-core.yml@dev

  spelling:
    name: Spelling
    uses: Lombiq/GitHub-Actions/.github/workflows/spelling.yml@dev

  post-pull-request-checks-automation:
    name: Post Pull Request Checks Automation
    needs: [build-and-test, spelling]
    if: github.event.pull_request != ''
    uses: Lombiq/GitHub-Actions/.github/workflows/post-pull-request-checks-automation.yml@dev
    secrets:
      JIRA_ENDPOINT_URL: ${{ secrets.DEFAULT_JIRA_ENDPOINT_URL }}
      JIRA_API_KEY: ${{ secrets.DEFAULT_JIRA_API_KEY }}
      MERGE_TOKEN: ${{ secrets.DEFAULT_MERGE_TOKEN }}
```

If you get "Cannot index into a null array." or "gh: Resource not accessible by integration (HTTP 403)" errors, you need additional permissions for the `gh` CLI tool used in the workflow. Add the following permissions just below `uses`:

```yaml
    permissions:
      actions: read
      pull-requests: read
```
