<#
.Synopsis
   Local testing script to run the Invoke-SolutionTests script.
#>

$switches = @{
    Solution = "../../../../../Lombiq.OSOCE.sln"
    Verbosity = "quiet"
    Filter = ""
    Configuration = "Debug"
}

.\Invoke-SolutionTests.ps1 @switches
