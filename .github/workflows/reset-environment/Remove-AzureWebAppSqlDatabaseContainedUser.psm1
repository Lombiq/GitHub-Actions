<#
.Synopsis
    Removes a contained user from a SQL Azure database.

.DESCRIPTION
    Removes a contained user from a SQL Azure database specified by a Subscription name, a Web App (and Slot) name and
    the Connection String name of the database and the contained user.

.EXAMPLE
    Remove-AzureWebAppSqlDatabaseContainedUser `
        -ResourceGroupName "LikeAndSubscribe" `
        -WebAppName "AppsEverywhere" `
        -ConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost-master" `
        -UserConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString"
#>


function Remove-AzureWebAppSqlDatabaseContainedUser
{
    [CmdletBinding()]
    [Alias("rawasdcu")]
    Param
    (
        [Alias("ResourceGroupName")]
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide the name of the Resource Group the database's Web App is in.")]
        [string] $DatabaseResourceGroupName,

        [Alias("WebAppName")]
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $DatabaseWebAppName,
        
        [Alias("SlotName")]
        [Parameter(HelpMessage = "The name of the Source Web App slot.")]
        [string] $DatabaseSlotName,

        [Alias("ConnectionStringName")]
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a connection string name for the executing user.")]
        [string] $DatabaseConnectionStringName,

        [Parameter(HelpMessage = "The name of the user connection string's Resource Group if it differs from the Source.")]
        [string] $UserResourceGroupName = $DatabaseResourceGroupName,

        [Parameter(HelpMessage = "The name of the user connection string's Web App if it differs from the Source.")]
        [string] $UserWebAppName = $DatabaseWebAppName,
        
        [Parameter(HelpMessage = "The name of the user connection string's Web App Slot if it differs from the Source.")]
        [string] $UserSlotName = $DatabaseSlotName,

        [Parameter(HelpMessage = "The name of the user connection string if it differs from the one for executing.")]
        [string] $UserConnectionStringName = $DatabaseConnectionStringName
    )

    Process
    {
        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection `
            -ResourceGroupName $DatabaseResourceGroupName `
            -WebAppName $DatabaseWebAppName `
            -SlotName $DatabaseSlotName `
            -ConnectionStringName $DatabaseConnectionStringName
        
        $userDatabaseConnection = Get-AzureWebAppSqlDatabaseConnection `
            -ResourceGroupName $UserResourceGroupName `
            -WebAppName $UserWebAppName `
            -SlotName $UserSlotName `
            -ConnectionStringName $UserConnectionStringName

        if ($databaseConnection.UserName -eq $userDatabaseConnection.UserName)
        {
            throw ("The database connection's user cannot delete itself!")
        }

        $query = "DROP USER IF EXISTS [$($userDatabaseConnection.UserName)];"

        return Invoke-AzureWebAppSqlQuery `
            -ResourceGroupName $DatabaseResourceGroupName `
            -WebAppName $DatabaseWebAppName `
            -SlotName $DatabaseSlotName `
            -ConnectionStringName $DatabaseConnectionStringName `
            -Query $query
    }
}