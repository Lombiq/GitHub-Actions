<#
.Synopsis
    Returns all information of a given Azure Web App.

.DESCRIPTION
    Returns all information of a given Azure Web App defined by its subscription and name (and optionally the name of
    the slot).

.EXAMPLE
    Get-AzureWebAppWrapper -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp"

.EXAMPLE
    Get-AzureWebAppWrapper -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp" -SlotName "Fresh"

.EXAMPLE
    Get-AzureWebAppWrapper -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp" -RetryCount 7
#>


Import-Module Az.Websites

function Get-AzureWebAppWrapper
{
    [CmdletBinding()]
    [Alias("gaw")]
    [OutputType([Microsoft.Azure.Commands.WebApps.Models.PSSite])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Resource Group.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $WebAppName,

        [Parameter(HelpMessage = "The name of the Web App slot.")]
        [string] $SlotName,

        [Parameter(HelpMessage = "The number of attempts for retrieving the data of the website. The default value is 3.")]
        [int] $RetryCount = 3
    )

    Process
    {
        $webAppSlot = $null
        $retryCounter = 0

        do
        {
            try
            {
                $parameters = @{
                    ResourceGroupName = $ResourceGroupName
                    Name = $WebAppName
                    ErrorAction = "Stop"
                }

                if ([string]::IsNullOrEmpty($SlotName))
                {
                    $webAppSlot = Get-AzWebApp @parameters
                }
                else
                {
                    $webAppSlot = Get-AzWebAppSlot @parameters -Slot $SlotName
                }
            }
            catch
            {
                if ($retryCounter -ge $RetryCount)
                {
                    throw "Could not retrieve the Web App `"$WebAppName`":`n$PSItem"
                }

                $retryCounter++

                Write-Warning "Attempt #$retryCounter to retrieve the Web App `"$WebAppName`" failed. Retrying..."
            }
        }
        while ($null -eq $webAppSlot)

        return $webAppSlot
    }
}