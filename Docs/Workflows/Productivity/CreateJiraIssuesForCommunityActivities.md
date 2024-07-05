# Create Jira issues for community activities

Creates Jira issues for community activities happening on GitHub, like issues, discussions, and pull requests being opened. Pull requests are only taken into account if they're not already related to a Jira issue (by starting their title with a Jira issue key).

## Prerequisites

1. Create a separate user account in Jira for each such use case (unless you want to open up API access too much). We recommend creating at least one bot account dedicated to automation tasks. Ensure this account has the permissions required to create and edit issues in the target Jira project(s), which, if you're using the default Jira configuration, requires the Developers role.
2. Create a [Jira API token](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/) under the user. Note that such tokens have the same access as the user account they were created for, and their scope can't be restricted ([nor can there be single-use Jira guest users](https://jira.atlassian.com/browse/JRACLOUD-74242)).
3. Set up organization or repository secrets for the `JIRA_*` parameters ([see docs](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-development-environment-secrets-for-your-repository-or-organization)). We recommend using the `DEFAULT_*` prefix for organization-level secrets to establish defaults that can be overridden on a per-repository basis. For repository-specific secrets, omit this prefix.
    - `DEFAULT_JIRA_BASE_URL`: The URL of your Jira (Atlassian) instance, following the `https://<yourdomain>.atlassian.net` pattern (e.g. `https://lombiq.atlassian.net`), or your custom domain.
    - `DEFAULT_JIRA_USER_EMAIL`: The e-mail address of the user account.
    - `DEFAULT_JIRA_API_TOKEN`: The API token of the user account.
4. Set up organization or repository secrets for the issue templates, see below.

The secrets with the `*_JIRA_ISSUE_DESCRIPTION` suffix should contain templates for the Jira issues to be created, using the internal markup format of Jira (not Markdown). Example for one for `ISSUE_JIRA_ISSUE_DESCRIPTION`:

```text
h1. Summary
See the linked GitHub issue, including all the comments.

h1. Checklist
* Assign yourself to the referenced GitHub issue.
* [Issue completion checklist|https://example.com/checklist]
```

All three templates are optional and if not provided, defaults from [the `Initialize-IssueTemplates` script](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/create-jira-issues-for-community-activities/Initialize-IssueTemplates.ps1) will be used.

## Setup

You can use the workflow as demonstrated below. It's crucial to use the `pull_request_target` trigger instead of `pull_request`. The `pull_request` trigger does not activate for pull requests from forks, which is necessary for this workflow to function as intended. Note that while it's safe to run our `create-jira-issues-for-community-activities` workflow started by `pull_request_target`, you should be careful what else such workflows do, see [the official docs](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#pull_request_target).

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
    uses: Lombiq/GitHub-Actions/.github/workflows/create-jira-issues-for-community-activities.yml@issue/OSOE-759
    secrets:
      JIRA_BASE_URL: ${{ secrets.DEFAULT_JIRA_BASE_URL }}
      JIRA_USER_EMAIL: ${{ secrets.DEFAULT_JIRA_USER_EMAIL }}
      JIRA_API_TOKEN: ${{ secrets.DEFAULT_JIRA_API_TOKEN }}
      JIRA_PROJECT_KEY: ${{ secrets.DEFAULT_JIRA_PROJECT_KEY }}
      DISCUSSION_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_DISCUSSION_JIRA_ISSUE_DESCRIPTION }}
      ISSUE_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_ISSUE_JIRA_ISSUE_DESCRIPTION }}
      PULL_REQUEST_JIRA_ISSUE_DESCRIPTION: ${{ secrets.DEFAULT_PULL_REQUEST_JIRA_ISSUE_DESCRIPTION }}
    with:
      issue-component: Lombiq.MyProject
```
