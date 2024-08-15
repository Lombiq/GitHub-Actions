<#
.Synopsis
   Local testing script to run the Invoke-SolutionOrProjectTests script. This needs to be invoked from the solution folder.
#>

$switches = @{
    SolutionOrProject = '.\Lombiq.OSOCE.sln'
    Verbosity = 'quiet'
    Filter = ''
    Configuration = 'Debug'
    BlameHangTimeout = '600000'
    TestProcessTimeout = '600000'
}

.\tools\Lombiq.GitHub.Actions\.github\actions\test-dotnet\Invoke-SolutionOrProjectTests.ps1 @switches
