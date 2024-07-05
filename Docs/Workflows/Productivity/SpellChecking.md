# Spell-checking

Checks for spelling mistakes in a repository using the [Check Spelling](https://github.com/marketplace/actions/check-spelling) GitHub Action, proxied by the [`spelling` action](../../../.github/actions/spelling/action.yml) in this repository, which has [its own documentation](../../SpellCheckingConfiguration.md) describing the configuration options and contribution guidelines. This documentation is also linked automatically at the end of every spell-checking report of a pull request.

If the "Checkout" step of the spelling workflow fails stating that the workflow can't find the repository, you need `contents` permission. If the "Check Spelling" step fails, but no comment was posted, you need "pull-requests" write permission. Add the following permissions just below `uses`:

```yaml
    permissions:
      contents: read
      pull-requests: write
```

## How to integrate spell-checking into a project

1. Start by adding a job to an existing workflow or create one specific to spell-checking with the minimum configuration.
2. Push the changes and open a pull request to have the initial spell-checking report commented to it.
3. Follow the [spell-checking configuration tips](../../SpellCheckingConfiguration.md) to work through the list of unrecognized entries.
4. You will probably end up with a few configuration files and some external dictionaries applied, so your workflow might end up looking something like the complete example below.

### Minimum spell-checking step configuration example

```yaml
  spelling:
    name: Spelling
    uses: Lombiq/GitHub-Actions/.github/workflows/spelling.yml@issue/OSOE-759
```

### Complete spell-checking workflow example

```yaml
name: Spelling

on:
  pull_request:
  push:
    branches:
      - dev

jobs:
  spelling:
    name: Spelling
    uses: Lombiq/GitHub-Actions/.github/workflows/spelling.yml@issue/OSOE-759
    with:
      # Add this parameter to define further dictionary source prefixes, such as a repository with general-purpose dictionaries. Dictionary files from these sources are processed before the default ones, and in the order their prefixes are listed here.
      additional-configuration-source-prefixes: >
        {
          "other-project": "https://raw.githubusercontent.com/Other/Project/dev/.github/actions/spelling/",
        }
      # Use this parameter to list the external dictionary files to use, but beware that check-spelling only accepts flat lists of words (so, for example patterns.txt can't be referenced like this). The order doesn't matter, but sorting it alphabetically makes it easier to maintain. The "cspell" and "lombiq-lgha" prefixes are available by default - see the spelling action for their exact path.
      additional-dictionaries: |
        cspell:csharp/csharp.txt
        other-project:my-dictionary.txt
```
