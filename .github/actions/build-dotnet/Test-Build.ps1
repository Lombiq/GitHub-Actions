<#
.Synopsis
   Local testing script to run the Build-DotNetSolutionOrProject script.
#>

$buildSwitches = @'
'@

$expectedCodeAnalysisErrors = @'
'@

$switches = @{
    Configuration = "Release"
    SolutionOrProject = "../../../../../Lombiq.OSOCE.sln"
    Verbosity = "quiet"
    EnableCodeAnalysis = "true"
    Version = "1.2.3"
    Switches = $buildSwitches
    ExpectedCodeAnalysisErrors = $expectedCodeAnalysisErrors
    CreateBinaryLog = $true
}

.\Build-DotNetSolutionOrProject.ps1 @switches
