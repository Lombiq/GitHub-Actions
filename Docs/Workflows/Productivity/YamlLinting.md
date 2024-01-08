# YAML Linting

This solution uses [`yamllint`](https://github.com/adrienverge/yamllint) for linting YAML files according to a configuration file. Such a configuration file includes a set of rules that are checked against when linting the files and can be found in `/.trunk/configs/.yamllint.yaml`.

You would typically consume the corresponding GHA workflow for YAML linting like this:

```yaml
...

jobs:
    yaml-linting:
        name: YAML Linting
        uses: Lombiq/GitHub-Actions/.github/workflows/yaml-lint.yml@dev
        with:
            config-file-path: 'tools/Lombiq.GitHub.Actions/.trunk/configs/.yamllint.yaml'
            search-path: '.'
```

Where:

- `config-file-path``: Specifies the location of the `yamllint` rules file to use. See more details about such file [here](https://yamllint.readthedocs.io/en/stable/rules.html).
- `search-path``: Where the files to lint should be searched.

## Integration with VSCode

During local development, YAML linting can be enabled in VSCode via the [Trunk Check](https://marketplace.visualstudio.com/items?itemName=Trunk.io) extension. Such a tool will look for the `yamllint` configuration file located in the folder `/.trunk`, which is already setup.

Additionally, the linter can be run as a standalone tool:

```bash
yamllint -c ./.trunk/configs/.yamllint.yaml ./github
```

Optionally, the Trunk Code extension can be used in conjunction with the [YAML by Red Hat](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) extension, which provides IntelliSense and description-on-hover capabilities based on a schema.
