# Lombiq GitHub Actions

## About

Reusable workflows and actions for Github Actions shared between Lombiq projects, e.g. to build and test [Orchard Core](https://www.orchardcore.net/) apps and .NET Framework and .NET Core applications in general, publish packages to NuGet, verifying and validating pull requests, spell checking, static code analysis and linting, and more! These can be invoked from any other repository's build.

[Check out a demo](https://www.youtube.com/watch?v=bhMnX0TsybM) on our YouTube channel!

## Documentation

- [Reusable workflows](Docs/Workflows.md)
- [Composite actions](Docs/Actions.md)

## Contributing and support

Bug reports, feature requests, comments, questions, code contributions and love letters are warmly welcome. You can send them to us via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.

### Code styling

We recommend using [Visual Studio Code](https://code.visualstudio.com/) with the following extensions and settings. Line width settings are helpful to maintain consistent formatting for multi-line strings (e.g., description properties).

- [GitHub Actions](https://marketplace.visualstudio.com/items?itemName=me-dutour-mathieu.vscode-github-actions) (the unofficial one until [GitHub's own extension](https://github.com/github/roadmap/issues/564) is released) and `yaml.format.printWidth` set to 120.
- [Rewrap](https://marketplace.visualstudio.com/items?itemName=stkb.rewrap) and `rewrap.wrappingColumn` set to 120.
