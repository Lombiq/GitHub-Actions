<#
.Synopsis
    Returns the account name and key of an Azure Blob Storage based on a connection string stored at a specific Web App.

.DESCRIPTION
    Given an Azure subscription name, a Web App name and a connection string name, the script will retrieve the account
    name and key of an Azure Blob Storage.

.EXAMPLE
    Get-AzureWebAppStorageConnection `
        -ResourceGroupName "YeahSubscribe" `
        -WebAppName "EverythingIsAnApp" `
        -ConnectionStringName "Nokia"
#>


function Get-AzureWebAppStorageConnection
{
    [CmdletBinding()]
    [Alias("gasc")]
    [OutputType([Object])]
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
        $connectionString = Get-AzureWebAppConnectionString `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -SlotName $SlotName `
            -ConnectionStringName $ConnectionStringName

        $connectionStringElements = $connectionString.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)


        $accountNameElementKey = "AccountName="
        $accountNameElement = $connectionStringElements | Where-Object { $PSItem.StartsWith($accountNameElementKey) }
        if ($null -eq $accountNameElement)
        {
            throw ("The connection string is invalid: Account Name declaration not found!")
        }

        $accountName = $accountNameElement.Substring($accountNameElementKey.Length, $accountNameElement.Length - $accountNameElementKey.Length)
        if ([string]::IsNullOrEmpty($accountName))
        {
            throw ("The connection string is invalid: Account Name not found!")
        }


        $accountKeyElementKey = "AccountKey="
        $accountKeyElement = $connectionStringElements | Where-Object { $PSItem.StartsWith($accountKeyElementKey) }
        if ($null -eq $accountKeyElement)
        {
            throw ("The connection string is invalid: Account Key declaration not found!")
        }

        $accountKey = $accountKeyElement.Substring($accountKeyElementKey.Length, $accountKeyElement.Length - $accountKeyElementKey.Length)
        if ([string]::IsNullOrEmpty($accountKey))
        {
            throw ("The connection string is invalid: Account Key not found!")
        }


        return @{ AccountName = $accountName; AccountKey = $accountKey }
    }
}