<#
.Synopsis
    Retrieves a connection string from an Azure Web App.

.DESCRIPTION
    Retrieves a connection string from an Azure Web App identified by the subscription, Web App name (and optional Slot
    name) and the name of the connection string.

.EXAMPLE
    Get-AzureWebAppWrapper -ResourceGroupName "InsertNameHere" -WebAppName "YummyWebApp" -ConnectionStringName "DatDatabase"

.EXAMPLE
    Get-AzureWebAppWrapper -ResourceGroupName "InsertNameHere" -WebAppName "YummyWebApp" -SlotName "Lucky" -ConnectionStringName "DatDatabase"
#>


Import-Module Az.Websites

function Get-AzureWebAppConnectionString
{
    [CmdletBinding()]
    [Alias("gacs")]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Resource Group.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $WebAppName,

        [Parameter(HelpMessage = "The name of the Web App slot.")]
        [string] $SlotName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the connection string.")]
        [string] $ConnectionStringName
    )

    Process
    {
        $webApp = Get-AzureWebAppWrapper -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -SlotName $SlotName

        $connectionString = ($webApp.SiteConfig.ConnectionStrings | Where-Object { $PSItem.Name -eq $ConnectionStringName }).ConnectionString

        if ([string]::IsNullOrEmpty($connectionString))
        {
            $connectionString = ($webApp.SiteConfig.AppSettings | Where-Object { $PSItem.Name -eq $ConnectionStringName }).Value
        }

        if ([string]::IsNullOrEmpty($connectionString))
        {
            throw ("Connection String or App Setting with the name `"$ConnectionStringName`" doesn't exist!")
        }

        return $connectionString
    }
}