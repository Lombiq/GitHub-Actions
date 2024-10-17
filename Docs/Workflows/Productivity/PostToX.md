# Post to X (Twitter)

With the the [Twitter, together! GitHub Actions action](https://github.com/twitter-together/action) you can let people post to an X (Twitter) account with pushes (pull requests) to a repository. It's really useful to share the responsibility of posting in a team, especially that of an open-source project where the paid features of X allowing this can't be justified. This workflow wraps Twitter, together! to make it easier to use.

You can use it like this:

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
