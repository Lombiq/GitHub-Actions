# Validate submodule

Validates pull requests in submodule repositories for various criteria:

- Adds a Jira-style issue code (e.g. PROJ-123) to the pull request's title, and a link to the Jira issue in the body if it's not there yet.
- Checks if a pull request exists in the parent repository.

Example _validate-pull-request.yml_:

```yaml
name: Validate Pull Request

on:
  # You can use pull_request if this is for a private repo that can't be forked.
  pull_request_target:

jobs:
  validate-pull-request:
    name: Validate Pull Request
    uses: Lombiq/GitHub-Actions/.github/workflows/validate-submodule-pull-request.yml@dev
    with:
      repository: Lombiq/Hastlayer-SDK
```

If this is for a submodule of [Lombiq's Open-Source Orchard Core Extensions](https://github.com/Lombiq/Open-Source-Orchard-Core-Extensions/), the `repo` input can be omitted, because the above is its default value. Otherwise, use your parent repository's address in the `{owner}/{repo_name}` format.

Refer to [Github Actions reusable workflows](https://docs.github.com/en/actions/learn-github-actions/reusing-workflows#overview) for more information.
