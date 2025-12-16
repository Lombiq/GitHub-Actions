# Mirror branches

The `mirror-branches` workflow and action allow synchronizing changes from one repository to another (regardless of the repository running the workflow) based on a predefined list of branch names or a regex to filter on branch names. It uses the GitHub API to fetch information from both the source and destination repositories to find out which branches need to be updated by comparing the head commits' hashes.

## Configuring your consumer workflow

- Authentication is required through a Personal Access Token (PAT) for the destination repository, and also for the source repository unless it's public.
- Classic PATs require the `repo` and `workflow` scopes. Fine-grained PATs require read or write access (depending on whether it's used only for the source and/or destination with the latter requiring write access) to `Contents` and `Workflows`.
- When the following conditions are met:
    1. You mirror changes to and from a repository.
    2. One of the workflows is triggered by the push event and is running in the source or destination repositories.
    3. The branches mirrored to and from that repository overlap.

    Consider adding the PAT for pushing to the repository running the workflow triggered by the push event to a bot user (i.e. a user that doesn't normally commit changes) and set a condition to the job not to run when the push event is triggered by that user. See the first example below with an explanation.
- When you mirror changes from the repository that runs such workflows, consider adding a condition to the job not to run in other repositories.
- You can optionally pass in a webhook URL to send a notification to a Microsoft Teams channel using the `FAILURE_NOTIFICATION_TEAMS_WEBHOOK` secret. See [the official documentation](https://support.microsoft.com/en-us/office/create-incoming-webhooks-with-workflows-for-microsoft-teams-8ae491c7-0394-4861-ba59-055e33f75498) on how to generate one. It is recommended to set up some sort of notification when a workflow that wasn't started by a user action (e.g. schedule trigger) fails - see the second example.

## Examples

### 1. Mirror 'dev-lombiq' branch on push from current repository

This workflow is a one-way mirror of the specified branches (`dev-lombiq` in the example) from the current repository (Lombiq/Client-Project) to another one.

Manual trigger will mirror the selected branch. If you want to keep the manual trigger, but restrict the mirrored branches to the same one(s) specified in the push trigger, list them for the `branch-names` parameter instead of `${{ github.ref_name }}` or use the `branch-regex` parameter instead of `branch-names`.

Notice the condition added to the job to make sure that the workflow only runs in this repository and the condition not to run when the push event is triggered by 'LombiqBot', which is important when you apply the second example too to these repositories. In that case, replace 'LombiqBot' with the user name of the owner of PAT you use to mirror changes into this repository.

```yaml
name: Mirror to client

on:
  workflow_dispatch:
  push:
    branches:
      - dev-lombiq

jobs:
  mirror:
    name: Mirror to client
    if: github.repository == 'Lombiq/Client-Project' && github.event.pusher.name != 'LombiqBot'
    uses: Lombiq/GitHub-Actions/.github/workflows/mirror-branches.yml@dev
    with:
      destination-repository: ClientCompany/Project
      branch-names: ${{ github.ref_name }}
    secrets:
      SOURCE_TOKEN: ${{ secrets.LOMBIQ_CLIENT_PROJECT_LOMBIQ_TOKEN }}
      DESTINATION_TOKEN: ${{ secrets.LOMBIQ_CLIENT_PROJECT_CLIENT_TOKEN }}
```

### 2. Periodically mirror branches from another repository

Mirroring branches on a schedule and manual trigger with the workflow running in the destination repository.

Note that this workflow doesn't necessarily need to be in either the source or destination repository; in that case the job's condition regarding the repository need to be omitted.

If you run a one-way mirror that includes the default branch of the source repository and the mirroring workflow is contained in the destination repository (e.g. you use the mirroring workflow to automatically update your fork of a public SDK), then the destination repository should have a different default branch (where the workflow is added) than the source.

```yaml
name: Mirror from client

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * *' # Once every day.

jobs:
  mirror-from-other:
    name: Mirror from client
    if: github.repository == 'Lombiq/Client-Project'
    uses: Lombiq/GitHub-Actions/.github/workflows/mirror-branches.yml@dev
    with:
      source-repository: ClientOfLombiq/Project
      destination-repository: Lombiq/Client-Project
      branch-regex: '^(?!feature/client-experiment$).+' # Mirror everything, except the 'feature/client-experiment' branch.
    secrets:
      SOURCE_TOKEN: ${{ secrets.LOMBIQ_CLIENT_PROJECT_CLIENT_TOKEN }}
      DESTINATION_TOKEN: ${{ secrets.LOMBIQ_CLIENT_PROJECT_LOMBIQ_TOKEN }}
      FAILURE_NOTIFICATION_TEAMS_WEBHOOK: ${{ secrets.FAILURE_NOTIFICATION_TEAMS_WEBHOOK }}
```
