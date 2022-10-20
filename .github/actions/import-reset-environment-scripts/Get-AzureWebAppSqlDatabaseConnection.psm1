<#
.Synopsis
    Returns the name and server name of an Azure SQL database based on a connection string stored at a specific Web App.

.DESCRIPTION
    Given an Azure subscription name, a Web App name, an optional Web App Slot Name and a connection string name, the
    script will retrieve the name and server name of a specific Azure SQL database.

.EXAMPLE
    Get-AzureWebAppSqlDatabaseConnection `
        -ResourceGroupName "YeahSubscribe" `
        -WebAppName "EverythingIsAnApp" `
        -ConnectionStringName "Nokia"

.EXAMPLE
    Get-AzureWebAppSqlDatabaseConnection `
        -ResourceGroupName "YeahSubscribe" `
        -WebAppName "EverythingIsAnApp" `
        -SlotName "UAT" `
        -ConnectionStringName "Nokia"
#>


function Get-AzureWebAppSqlDatabaseConnection
{
    [CmdletBinding()]
    [Alias("gasdc")]
    [OutputType([Object])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Resource Group.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $WebAppName,
        
        [Parameter(HelpMessage = "The name of the Web App slot.")]
        [string] $SlotName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name.")]
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


        $serverElement = $connectionStringElements | Where-Object { $PSItem.StartsWith("Server=") }
        if ($null -eq $serverElement)
        {
            throw ("The connection string is invalid: Server declaration not found!")
        }

        $serverName = $serverElement.
        Split(":", [System.StringSplitOptions]::RemoveEmptyEntries)[1].
        Split(".", [System.StringSplitOptions]::RemoveEmptyEntries).
        Get(0)
        
        if ([string]::IsNullOrEmpty($serverName))
        {
            throw ("The connection string is invalid: Server name not found!")
        }        


        $databaseElement = $connectionStringElements | Where-Object { $PSItem.StartsWith("Database=") -or $PSItem.StartsWith("Initial Catalog=") }
        if ($null -eq $databaseElement)
        {
            throw ("The connection string is invalid: Database / Initial Catalog declaration not found!")
        }

        $databaseName = $databaseElement.Split("=", [System.StringSplitOptions]::RemoveEmptyEntries)[1]
        if ([string]::IsNullOrEmpty($databaseName))
        {
            throw ("The connection string is invalid: Database name not found!")
        }

        
        $userIdElement = $connectionStringElements | Where-Object { $PSItem.StartsWith("User ID=") }
        if ($null -eq $userIdElement)
        {
            throw ("The connection string is invalid: User ID declaration not found!")
        }

        $userId = $userIdElement.Split("=", [System.StringSplitOptions]::RemoveEmptyEntries)[1]
        if ([string]::IsNullOrEmpty($userId))
        {
            throw ("The connection string is invalid: User ID not found!")
        }

        
        $userName = $userId.Split("@", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
        if ([string]::IsNullOrEmpty($userName))
        {
            throw ("The connection string is invalid: User name not found!")
        }


        $passwordElementKey = "Password="
        $passwordElement = $connectionStringElements | Where-Object { $PSItem.StartsWith($passwordElementKey) }
        if ($null -eq $passwordElement)
        {
            throw ("The connection string is invalid: Password declaration not found!")
        }

        $password = $passwordElement.Substring($passwordElementKey.Length, $passwordElement.Length - $passwordElementKey.Length)
        if ([string]::IsNullOrEmpty($password))
        {
            throw ("The connection string is invalid: Password not found!")
        }
        

        return @{
            ServerName = $serverName
            DatabaseName = $databaseName
            UserId = $userId
            UserName = $userName
            Password = $password
        }
    }
}