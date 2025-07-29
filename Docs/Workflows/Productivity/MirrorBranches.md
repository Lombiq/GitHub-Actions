# Mirror branches

The `mirror-branches` workflow and action allow synchronizing changes from one repository to another (regardless of the repository running the workflow) based on a predefined list of branch names or a regex to filter on branch names. It uses the GitHub API to fetch information from both the source and destination repositories to find out which branches need to be updated by comparing the head commits' hashes.

## Configuring your consumer workflow

- Authentication is required through a Personal Access Token (PAT) for the destination repository, and also for the source repository unless it's public.
- Classic PATs require the `repo` and `workflow` scopes. Fine-grained PATs require read or write access (depending on whether it's used only for the source and/or destination with the latter requiring write access) to `Contents` and `Workflows`.
- When the following conditions are met:
    1. You mirror changes to and from a repository.
    2. One of the workflows is triggered by the push event and is running in the source or destination repositories.
    3. The branches mirrored to and from that repository overlap.

    Consider adding the PAT for pushing to the repository running the workflow triggered by the push event to a bot user (i.e. a user that doesn't normally commits changes) and set a condition to the job not to run when the push event is triggered by that user. See the first example below with an explanation.
- When you mirror changes from the repository that runs such workflows, consider adding a condition to the job not to run in other repositories.

## Examples

### 1. Mirror 'dev-lombiq' branch on push from current repository

This workflow is a one-way mirror of the 'dev-lombiq' branch from the current repository (Lombiq/Client-Project) to another one. Notice the condition added to the job to make sure that the workflow only runs in this repository and the condition not to run when the push event is triggered by 'LombiqBot', which is important when you apply the second example too to these repositories.

```yaml
name: Mirror to client

on:
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

```yaml
name: Mirror from client

on:
  workflow_dispatch:
  schedule:
    - cron: '0 * * * *'  # Runs every hour

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
```
