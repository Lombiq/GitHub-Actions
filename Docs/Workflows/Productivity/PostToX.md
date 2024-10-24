# Post to X (Twitter)

With the the [Twitter, together! GitHub Actions action](https://github.com/twitter-together/action) you can let people post to an X (Twitter) account with pushes to the default branch (e.g., merged pull requests) of a repository. It's really useful to share the responsibility of posting in a team, especially that of an open-source project where the cost of paid features on X allowing this can't be justified.

This workflow wraps Twitter, together! to make it easier to use, for example:

```yaml
name: Post to X (Twitter)

on:
  push:
  pull_request:

jobs:
  post-to-x:
    name: Post to X (Twitter)
    uses: Lombiq/GitHub-Actions/.github/workflows/post-to-x.yml@dev
    secrets:
      X_ACCESS_TOKEN: ${{ secrets.X_ACCESS_TOKEN }}
      X_ACCESS_TOKEN_SECRET: ${{ secrets.X_ACCESS_TOKEN_SECRET }}
      X_API_KEY: ${{ secrets.X_API_KEY }}
      X_API_KEY_SECRET: ${{ secrets.X_API_KEY_SECRET }}
```
