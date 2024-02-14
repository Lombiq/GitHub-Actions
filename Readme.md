# Lombiq GitHub Actions

## About

Reusable workflows and actions for GitHub Actions shared between Lombiq projects, for example:

- Build and test [Orchard Core](https://www.orchardcore.net/) apps
- Build and test .NET Framework and .NET Core applications in general
- Publish packages to NuGet
- Verify and validate pull requests
- Check spelling
- Perform static code analysis and linting
- Deploy to an Azure App Service, swap staging and production slots, and copy production data to the staging site
- And more!

These can be invoked from any other repository's build.

[Check out a demo](https://www.youtube.com/watch?v=bhMnX0TsybM) on our YouTube channel, and the Orchard Harvest 2023 conference talk about automated QA in Orchard Core [here](https://youtu.be/CHdhwD2NHBU).

We at [Lombiq](https://lombiq.com/) also used these workflows for the following projects:

- The new [Lombiq website](https://lombiq.com/) when migrating it from Orchard 1 to Orchard Core ([see case study](https://lombiq.com/blog/how-we-renewed-and-migrated-lombiq-com-from-orchard-1-to-orchard-core)).
- The new client portal for [WTW](https://www.wtwco.com/) ([see case study](https://lombiq.com/blog/lombiq-s-journey-with-wtw-s-client-portal)).<!-- #spell-check-ignore-line -->
- They also make [DotNest, the Orchard SaaS](https://dotnest.com/) better.

## Documentation

- [Reusable workflows](Docs/Workflows.md)
- [Composite actions](Docs/Actions.md)

## Contributing and support

Bug reports, feature requests, comments, questions, code contributions and love letters are warmly welcome. You can send them to us via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.

To ensure that when changing actions or workflows their references to other actions/workflows are up-to-date (i.e. instead of `@dev` they reference each other with `@current-branch`) the [Validate GitHub Actions Refs workflow](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/workflows/validate-this-gha-refs.yml) will fail if references are incorrect. This is the case also if after a pull request approve that references don't point to the target branch; before merging, that should be fixed, otherwise merging via the merge queue will fail.
