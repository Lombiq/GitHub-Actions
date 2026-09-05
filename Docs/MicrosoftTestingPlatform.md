# Microsoft Testing Platform migration (v6)

The `test-dotnet` action and modern .NET build-and-test workflows now default to Microsoft Testing Platform (MTP). This is a breaking change for VSTest consumers.

1. Use .NET SDK 10 or later and set `"test": { "runner": "Microsoft.Testing.Platform" }` in the solution's _global.json_. Preserve any existing SDK settings.
2. Upgrade xUnit projects to `xunit.v3` 4.0.0 or later, set `<UseMicrosoftTestingPlatformRunner>true</UseMicrosoftTestingPlatformRunner>`, and remove `Microsoft.NET.Test.Sdk` and `xunit.runner.visualstudio`. All test projects in the solution must support MTP.
3. Reference `Microsoft.Testing.Extensions.GitHubActionsReport` and `Microsoft.Testing.Extensions.TrxReport` 2.4.0 or later in each test project. Add `Microsoft.Testing.Extensions.HangDump` at the same version if using `blame-hang-timeout`. The updated Lombiq test SDK includes these packages.

The action uses `--report-gh` for annotations and job summaries, and `--report-trx` for downloadable results. It disables assembly log groups to preserve the UI Testing Toolbox's per-test groups. Report filenames distinguish assemblies, target frameworks, and architectures.

The `test-filter` input still accepts VSTest-style expressions with xUnit 4, such as `FullyQualifiedName!~SecurityScanningTests`. Other MTP test frameworks must support `--filter` to use this input. The `blame-hang-timeout` input now configures MTP's hang dump extension, and `enable-diagnostic-mode` enables MTP diagnostic files. Bare hang timeout values remain milliseconds.

Test projects are identified by evaluated MSBuild properties. During solution runs, empty test projects and projects without tests matching the filter are allowed; an explicit project run fails if no tests run. Test failures and process failures fail the action based on the runner's exit code.

For legacy test projects, set `test-platform: VSTest` on `test-dotnet`, `build-and-test-dotnet`, or `build-and-test-orchard-core`, and keep the VSTest runner configuration. The `msbuild-and-test` workflow continues to select VSTest for .NET Framework applications.

Publish this change as v6.0.0 after merging the coordinated migration. Follow the [release branch workflow](../Readme.md#versioning-tags-and-releases), which updates internal action references before creating the release tag.
