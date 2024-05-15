<#
.Synopsis
   Local testing script to run the Invoke-SolutionTests script. This needs to be invoked from the solution folder.
#>

$switches = @{
    Solution = '.\Lombiq.OSOCE.sln'
    Verbosity = 'quiet'
    Filter = ''
    Configuration = 'Debug'
    BlameHangTimeout = '600000'
    TestProcessTimeout = '600000'
}

.\tools\Lombiq.GitHub.Actions\.github\actions\test-dotnet\Invoke-SolutionTests.ps1 @switches
