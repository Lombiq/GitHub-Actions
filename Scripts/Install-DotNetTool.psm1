function Install-DotNetTool
{
    [CmdletBinding()]
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
    
    begin
    {
        $scopeString = $Global.IsPresent ? "--global" : ""
    }
    
    process
    {
        $installedTool = dotnet tool list $scopeString | Select-Object -Skip 2 | ForEach-Object {
            $segments = $_.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
            return New-Object -TypeName PSObject -Property @{
                PackageId = $segments[0]
                Version   = $segments[1]
                Commands  = $segments[2]
            }
        } | Where-Object { $_.PackageId -eq $Name }
        
        $doInstall = $false
        
        if ($null -ne $installedTool)
        {
            if ($installedTool.Version -ne $Version)
            {
                dotnet tool uninstall $Name $scopeString
                $doInstall = $true
            }
            else
            {
                Write-Output "$Name version $Version is already installed!"
            }
        }
        
        if ($doInstall)
        {
            dotnet tool install $Name --version $Version $scopeString
        }
    }
}