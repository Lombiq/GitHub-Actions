param (
    [Parameter(Mandatory = $true, HelpMessage = "The name of the tool to install.")]
    [string]
    $Name,

    [Parameter(Mandatory = $true, HelpMessage = "The version of the tool to install.")]
    [string]
    $Version,

    [Parameter(HelpMessage = "When present, the tool will be installed globally, locally otherwise.")]
    [switch]
    $Global
)

$scopeString = ""
if ($Global.IsPresent)
{
    $scopeString = "--global"
}

$installedTool = dotnet tool list $scopeString | Select-Object -Skip 2 | ForEach-Object {
    $segments = $_.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    return New-Object -TypeName PSObject -Property @{
        PackageId = $segments[0]
        Version   = $segments[1]
        Commands  = $segments[2]
    }
} | Where-Object { $_.PackageId -eq $Name }

$doInstall = $true

if ($null -ne $installedTool -and $installedTool -ne "")
{
    if ($installedTool.Version -ne $Version)
    {
        dotnet tool uninstall $Name $scopeString
    }
    else
    {
        Write-Output "$Name version $Version is already installed!"
        $doInstall = $false
    }
}

if ($doInstall)
{
    dotnet tool install $Name --version $Version $scopeString
}
