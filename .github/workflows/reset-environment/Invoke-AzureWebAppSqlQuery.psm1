Import-Module SQLPS

function Invoke-AzureWebAppSqlQuery
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Resource Group.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $WebAppName,
        
        [Parameter(HelpMessage = "The name of the Web App slot.")]
        [string] $SlotName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name.")]
        [string] $ConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to define a query to run.")]
        [string] $Query
    )

    Process
    {
        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -SlotName $SlotName `
            -ConnectionStringName $ConnectionStringName

        return Invoke-Sqlcmd `
            -ServerInstance "$($databaseConnection.ServerName).database.windows.net" `
            -Database $databaseConnection.DatabaseName `
            -Username $databaseConnection.UserName `
            -Password $databaseConnection.Password `
            -Query $Query `
            -EncryptConnection
    }
}