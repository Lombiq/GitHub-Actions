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

## Versioning, Tags and Releases

To release versions of Lombiq GitHub Actions, and allow consumers to reference a specific version of a reusable workflow or composite action (e.g. `@v1.0`), we employ some automation to do this in a consistent and predictable way.

See [issue #284 "Introduce versioning and releases (OSOE-735)"](https://github.com/Lombiq/GitHub-Actions/issues/284) for additional details on why we do this. <!-- #spell-check-ignore-line -->

New versions of Lombiq GitHub Actions are automatically tagged using the [Tag Version (this repo)](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/workflows/tag-version-this-repo.yml) workflow. This workflow is triggered for release branches with a name that matches the `release/**` pattern (e.g. `release/v1.0`, `release/v2.0-alpha`, etc.).

The create a new release, create a new branch following the above naming convention at the commit to be released and push it.

When you push your new release branch, the following things happen automatically:

1. The [Tag Version (this repo)](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/workflows/tag-version-this-repo.yml) workflow runs and calls the reusable workflow [Tag Version](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/workflows/tag-version.yml).
2. The [Tag Version](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/workflows/tag-version.yml) workflow calls the [Set GitHub Actions References](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/set-gha-refs/action.yml) reusable action.
3. The [Set GitHub Actions References](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/set-gha-refs/action.yml) action recursively searches all files in the `.github` folder to find each call to a GitHub Action or Workflow contained in this repository.
4. By default, references to called actions and workflows targeting the release branch (see above) are string replaced with the version name (e.g. `v1.0`).
   - Additionally, the [Set GitHub Actions References](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/set-gha-refs/action.yml) action has a parameter called [additional-pattern-include-list](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/set-gha-refs/action.yml#L24) which allows for replacing `release/v1.0` under special circumstances such as for the [spelling action explicit file reference](https://github.com/Lombiq/GitHub-Actions/blob/dev/.github/actions/spelling/action.yml#L133) scenario.
5. The [stefanzweifel/git-auto-commit-action](https://github.com/stefanzweifel/git-auto-commit-action/commit/8756aa072ef5b4a080af5dc8fef36c5d586e521d) action is used to automatically: <!-- #spell-check-ignore-line -->
   - Commit the updated files to the `release/v1.0` branch.
   - Create a new git tag using the release name (e.g. `v1.0`).
6. Tags are force pushed to update the `v1.0` tag if it needs to be updated.
