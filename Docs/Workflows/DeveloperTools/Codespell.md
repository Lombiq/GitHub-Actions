# Codespell

Checks spelling by running [codespell](https://github.com/codespell-project/codespell). Unlike spell-checkers that use dictionaries to look for correct spelling, codespell rather looks for common misspellings. This reduces false positives by a lot, while still providing a good enough guard against spelling mistakes.

```yaml
name: Codespell

on:
  pull_request:
    push:
      branches:
        - dev

jobs:
  codespell:
    name: Codespell
    uses: Lombiq/GitHub-Actions/.github/workflows/codespell.yml@dev
```

## Configuring codespell in your project

One-off false positives can be ignored by adding `codespell:ignore yourword` to the end of the line (or `codespell:ignore` to ignore the whole line).

For complete configuration of codespell, you can override the default configuration of this workflow by placing a _.codespellrc_ file in the root of your repository. On how to use this, see the [codespell documentation](https://github.com/codespell-project/codespell?tab=readme-ov-file#using-a-config-file). The default configuration is [here](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/codespell/setup.cfg).

<!-- textlint-disable doubled-spaces -->
> [!WARNING]
> You must use a _.codespellrc_ file, not the other formats or file names supported by codespell.
<!-- textlint-enable doubled-spaces -->

Useful configuration options to override:

- `ignore-words-list`: These words will be considered correct spelling. E.g.: `ignore-words-list = MySpecialWord, MyOtherSpecialWord`.
- `ignore-regex`: Words or phrases matching this regex will be ignored. E.g.: `ignore-regex = (<thead|<\/thead>)`.<!-- codespell:ignore thead -->
- `skip`: Files matching these paths or glob expressions will be skipped. E.g.: `skip = *.txt, */IgnoredPathSegment/*, ./src/Ignored/Folder/*, IgnoredFile.md`.

<!-- textlint-disable doubled-spaces -->
> [!TIP]
> If you want to concatenate to default configuration values instead of completely overriding them (like adding new words to `ignore-words-list`), then use the `+=` assignment. This works like in any programming language. E.g., if the default is `ignore-words-list = one, two`, then you can add `ignore-words-list += , three` to produce `ignore-words-list = one, two, three`. Note that this is simple string concatenation.
<!-- textlint-enable doubled-spaces -->

## How to add codespell to an existing large project

If you have an existing large project where you want to use this workflow, it's quicker to figure out the proper configuration locally. Do the following:

1. [Install](https://github.com/codespell-project/codespell?tab=readme-ov-file#installation) codespell.
2. Add the [default configuration file of this workflow](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/codespell/setup.cfg) to the root of your repository.
3. Run `codespell`.
4. Fix any spelling mistakes. If you need to adjust the configuration, like due to false positives or to make codespell ignore certain files or folders, then change the configuration file and run codespell again. Take note of your changes (you can use Git commits for this).
5. Once you're done, move your project-specific configuration overrides to a _.codespellrc_ file in the root of your repository, following the guide above, and remove the _setup.cfg_ file.
6. Set up this workflow in your repository.
