# Create Jira issues for community activities

Creates Jira issues for community activities happening on GitHub, like issues, discussions, and pull requests being opened. Pull requests are only taken into account if they're not already related to a Jira issue (by starting their title with a Jira issue key).

[Jira API tokens](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/) have the same access as the user account they were created for, and their scope can't be restricted ([nor can there be single-use Jira guest users](https://jira.atlassian.com/browse/JRACLOUD-74242)). Thus you'd normally need to have a separate API user account for each use case (unless you want to open up API access too much). Due to this limitation, we're using the [API Key Manager for Jira extension](https://marketplace.atlassian.com/apps/1228630/api-key-manager-for-jira) to provide scope-limited API access.

## Prerequisites

1. Install the [API Key Manager for Jira extension](https://marketplace.atlassian.com/apps/1228630/api-key-manager-for-jira) in your Jira instance.
2. Set up organization or repository secrets for the `JIRA_*` parameters. You may use secret names without the `DEFAULT_*` prefix, but that's our recommendation for organization-level secrets, so you have defaults but can override them on a per-repository basis. For repository secrets, names without this prefix is recommended.
    - `DEFAULT_JIRA_ENDPOINT_URL`: The Endpoint URL indicated under the API Key Manager settings in Jira in the Apps menu.
    - `DEFAULT_JIRA_API_KEY`: Under the API Key Manager settings in Jira in the Apps menu, create an API key with the following settings
      - Valid until: Unless you want to rotate the keys manually, remove the expiration.
      - Description: "Create Jira issues for community activities for <project key>" (or what you prefer).
      - Allowed methods: POST.
      - Allowed endpoints: "/rest/api/3/issue/<project key>-".
3. Set up organization or repository secrets for the issue templates, see below.

The secrets with the `*_JIRA_ISSUE_DESCRIPTION` suffix should contain templates for the Jira issues to be created, using the internal markup format of Jira (not Markdown). Example for one for `ISSUE_JIRA_ISSUE_DESCRIPTION`:

```text
h1. Summary
See the linked GitHub issue, including all the comments.

h1. Checklist
* Assign yourself to the referenced GitHub issue.
* [Issue completion checklist|https://example.com/checklist]
```

All three templates are optional and if not provided, defaults will be used.

## Setup

You can use the workflow as demonstrated below. Note that it's important to use the `pull_request_target` trigger instead of `pull_request` because the latter doesn't trigger for pull requests from forks, defeating the whole purpose of this workflow.

```yaml
name: Create Jira issues for community activities

on:
  discussion:
    types: [created]
  issues:
    types: [opened]
  pull_request_target:
    types: [opened]

jobs:
  create-jira-issues-for-community-activities:
    name: Create Jira issues for community activities
    uses: Lombiq/GitHub-Actions/.github/workflows/create-jira-issues-for-community-activities.yml@dev
    secrets:
      JIRA_ENDPOINT_URL: ${{ secrets.DEFAULT_JIRA_ENDPOINT_URL }}
      JIRA_API_KEY: ${{ secrets.DEFAULT_JIRA_API_KEY }}
      JIRA_PROJECT_KEY: ${{ secrets.DEFAULT_JIRA_PROJECT_KEY }}
      DISCUSSION_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_DISCUSSION_JIRA_ISSUE_DESCRIPTION }}
      ISSUE_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_ISSUE_JIRA_ISSUE_DESCRIPTION }}
      PULL_REQUEST_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_PULL_REQUEST_JIRA_ISSUE_DESCRIPTION }}
    with:
      issue-component: Lombiq.MyProject
```
