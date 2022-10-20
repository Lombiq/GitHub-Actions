<#
.Synopsis
    Adds a contained user to a SQL Azure database with the optionally specified role.

.DESCRIPTION
    Adds a contained user to a SQL Azure database specified by a Subscription name, a Web App (and Slot) name and the
    Connection String name of the database and the contained user.

.EXAMPLE
    Add-AzureWebAppSqlDatabaseContainedUser `
        -ResourceGroupName "LikeAndSubscribe" `
        -WebAppName "AppsEverywhere" `
        -ConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost-master" `
        -UserConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost"
#>


function Add-AzureWebAppSqlDatabaseContainedUser
{
    [CmdletBinding()]
    [Alias("aawasdcu")]
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

        [Parameter(HelpMessage = "The name of the user connection string's Resource Group if it differs from the database's.")]
        [string] $UserResourceGroupName = $DatabaseResourceGroupName,

        [Parameter(HelpMessage = "The name of the user connection string's Web App if it differs from the database's.")]
        [string] $UserWebAppName = $DatabaseWebAppName,
        
        [Parameter(HelpMessage = "The name of the user connection string's Web App Slot if it differs from the database's.")]
        [string] $UserSlotName = $DatabaseSlotName,

        [Parameter(HelpMessage = "The name of the user connection string if it differs from the database's.")]
        [string] $UserConnectionStringName = $DatabaseConnectionStringName,

        [Parameter(HelpMessage = "The role of the user to be added to the database. The default value is `"db_owner`".")]
        [string] $UserRole = "db_owner"
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

        if ($databaseConnection.ServerName -ne $userDatabaseConnection.ServerName `
                -or $databaseConnection.DatabaseName -ne $userDatabaseConnection.DatabaseName)
        {
            throw ("The contained user's connection string must connect to the same server and database as the " +
                "database connection that executes the query!")
        }

        if ($databaseConnection.UserName -eq $userDatabaseConnection.UserName)
        {
            throw ("The contained user must be different than the user executing the query!")
        }

        $query = "CREATE USER [$($userDatabaseConnection.UserName)] WITH PASSWORD = '$($userDatabaseConnection.Password)';" +
        "ALTER ROLE [$UserRole] ADD MEMBER [$($userDatabaseConnection.UserName)];"

        return Invoke-AzureWebAppSqlQuery `
            -ResourceGroupName $DatabaseResourceGroupName `
            -WebAppName $DatabaseWebAppName `
            -SlotName $DatabaseSlotName `
            -ConnectionStringName $DatabaseConnectionStringName `
            -Query $query
    }
}