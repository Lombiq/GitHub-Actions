# Asset Linting

This workflow uses `eslint` and `stylelint` to validate your JavaScript and CSS files. It also invokes our [Markdown Linting](MarkdownLinting.md) workflow.

You would typically consume workflow by passing a comma-separated list of the project paths where scripts or styles are to be linted:

```yaml
...

jobs:
    asset-linting:
        name: Asset Linting
        uses: Lombiq/GitHub-Actions/.github/workflows/asset-lint.yml@dev
        with:
        scripts: >
            src/Modules/Lombiq.ContentEditors/Lombiq.ContentEditors,
            src/Modules/Lombiq.ContentEditors/Lombiq.ContentEditors.Samples,
            src/Modules/Lombiq.DataTables/Lombiq.DataTables,
            src/Modules/Lombiq.HelpfulExtensions/Lombiq.HelpfulExtensions,
            src/Modules/Lombiq.UIKit/Lombiq.UIKit,
            src/Modules/Lombiq.Walkthroughs/Lombiq.Walkthroughs,
            src/Modules/Lombiq.Hosting.Tenants/Lombiq.Hosting.Tenants.Maintenance,
        styles: >-
            src/Modules/Lombiq.ChartJs/Lombiq.ChartJs.Samples,
            src/Modules/Lombiq.HelpfulExtensions/Lombiq.HelpfulExtensions,
            src/Modules/Lombiq.JsonEditor/Lombiq.JsonEditor,
            src/Modules/Lombiq.Privacy/Lombiq.Privacy,
            src/Modules/Lombiq.UIKit/Lombiq.UIKit,
            src/Themes/Lombiq.BaseTheme/Lombiq.BaseTheme.Core,
            src/Themes/Lombiq.BaseTheme/Lombiq.BaseTheme.Native,
            src/Themes/Lombiq.BaseTheme/Lombiq.BaseTheme.Native.Samples,
```

This will lint the files in _wwwroot/js_ and _wwwwroot/css_ respectively. If you need linting in a different directory, you can also append `:{relative path or glob pattern}` after each project directory path. For example to lint scripts in the project root:

```yaml
    asset-linting:
        name: Asset Linting
        uses: Lombiq/GitHub-Actions/.github/workflows/asset-lint.yml@dev
        with:
        scripts: >
            src/Libraries/Lombiq.EInvoiceValidator/Lombiq.EInvoiceValidator : .
```

For descriptions of the workflow inputs, see [the workflow file](../../../.github/workflows/asset-lint.yml).

## Configuration

You can override the following configuration files by having their counterpart in your repository root:

CSS configuration files:

- .stylelintignore: A _.gitignore_ style file where you can list excludes for Stylelint.
- stylelint.config.mjs: The main configuration file for Stylelint.

JavaScript configuration files:

- eslint.config.mjs: The main configuration file for ESLint. It is not recommended to override this file.
- eslint.custom.mjs: If this file exists, it's loaded in by the the workflow's _eslint.config.mjs_ at the highest precedence. In other words you can override rules or other settings here while still extending the main Lombiq ESLint config file.

## How to Run Locally

1. Check out this repository in your local machine.
2. Open PowerShell in the root directory of the repository you want to lint.
3. Type `path-to-GHA/.github/actions/asset-lint/Invoke-Linter.ps1 -ScriptsString relative/path/to/project -StylesString relative/path/to/project`. You can omit either switches if you don't want to lint both.

```pwsh
.../Open-Source-Orchard-Core-Extensions/tools/Lombiq.GitHub.Actions/.github/actions/asset-lint/Invoke-Linter.ps1 -ScriptsString src/Modules/Lombiq.UIKit/Lombiq.UIKit:wwwroot/js -StylesString src/Modules/Lombiq.UIKit/Lombiq.UIKit:wwwroot/css
```

> [!TIP]
> Add the _path-to-GHA/.github/actions/asset-lint_ directory to your execution path so you can use `Invoke-Linter` like a regular command.
