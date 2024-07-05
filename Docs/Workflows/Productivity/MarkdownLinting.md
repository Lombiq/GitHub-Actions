# Markdown Linting

This workflow uses [`markdownlint-cli2`](https://github.com/DavidAnson/markdownlint-cli2) through its wrapper action for linting markdown files according to an optional configuration file. Such a configuration file includes a set of rules that are checked against when linting the files and can be found in `../../../.github/actions/markdown-lint/lombiq.markdownlint.json` and is used by default.

You would typically consume the corresponding GHA workflow for markdown linting like this:

```yaml
...

jobs:
    markdown-linting:
        name: Markdown Linting
        uses: Lombiq/GitHub-Actions/.github/workflows/markdown-lint.yml@issue/OSOE-759
```

The list of input parameters specific to the behavior of `markdownlint` are the the same as its wrapper action and [described in its readme](https://github.com/DavidAnson/markdownlint-cli2-action?tab=readme-ov-file#inputs). The values are passed on directly, but the defaults are changed to use Lombiq's configuration file.
