<#
.Synopsis
    Changes the pricing tier of a SQL Azure database.

.DESCRIPTION
    Changes the pricing tier of a SQL Azure database defined by a Subscription name, the name of a Web App and the name
    of a Connection String.

.EXAMPLE
    Set-AzureWebAppSqlDatabaseServiceObjective `
        -ResourceGroupName "GreatStuffHere" `
        -WebAppName "CloudFirst" `
        -SlotName "MobileFirst" `
        -ConnectionStringName "DatabaseFirst" `
        -ServiceObjectiveName "S2"
#>


Import-Module Az.Sql

function Set-AzureWebAppSqlDatabaseServiceObjective
{
    [CmdletBinding()]
    [Alias("swadso")]
    [OutputType([Microsoft.Azure.Commands.Sql.Database.Model.AzureSqlDatabaseModel])]
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

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the service objective to scale " +
            "the database to. Examples: B, S1, S4, P4, P6")]
        [string] $ServiceObjectiveName,

        [Parameter(Helpmessage = "The edition of the database pricing tier to scale the database to. It needs to be " +
            "defined if the target Service Objective is in a different edition than the current one.")]
        [string] $Edition = "Standard"
    )

    Process
    {
        $database = Get-AzureWebAppSqlDatabase `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -SlotName $SlotName `
            -ConnectionStringName $ConnectionStringName

        if ($null -eq $database)
        {
            throw ("Database not found for the `"$ConnectionStringName`" connection string!")
        }
        elseif ($database.CurrentServiceObjectiveName -ne $database.RequestedServiceObjectiveName)
        {
            Write-Warning ("Another operation is still pending for the database named `"$($database.DatabaseName)`" " +
                "on the server `"$($database.ServerName)`"!")
            
            return $null
        }
        elseif ($database.CurrentServiceObjectiveName -eq $ServiceObjectiveName)
        {
            Write-Warning ("The database named `"$($database.DatabaseName)`" on the server `"$($database.ServerName)`" " +
                "is already running in the `"$ServiceObjectiveName`" tier!")

            return $null
        }

        $serviceObjectives = Get-AzSqlServerServiceObjective `
            -ResourceGroupName $ResourceGroupName `
            -ServerName $database.ServerName

        $availableServiceObjectiveNames = $serviceObjectives `
        | Where-Object { !$PSItem.IsSystem -and $PSItem.Enabled } `
        | Select-Object -ExpandProperty "ServiceObjectiveName"

        if (!$availableServiceObjectiveNames.Contains($ServiceObjectiveName))
        {
            throw ("The `"$ServiceObjectiveName`" tier is not available for the server `"$($database.ServerName)`". " +
                "The available tiers are:`n$([string]::Join(", ", $availableServiceObjectiveNames)).")
        }

        try
        {
            Write-Host ("`n*****`nChanging Service Objective of the database named `"$($database.DatabaseName)`" on " +
                "the server `"$($database.ServerName)`" from `"$($database.Edition) $($database.CurrentServiceObjectiveName)`" " +
                "to `"$($Edition) $($ServiceObjectiveName)`"...`n*****")

            return Set-AzSqlDatabase `
                -ResourceGroupName $ResourceGroupName `
                -ServerName $database.ServerName `
                -DatabaseName $database.DatabaseName `
                -RequestedServiceObjectiveName $ServiceObjectiveName `
                -Edition $Edition `
                -ErrorAction Stop
        }
        catch
        {
            Write-Error ("Changing the Service Objective failed - see the detailed error below. Did you define the " +
                "Edition of the target Service Objective? The current value is `"$Edition`".")
            
            throw
        }
    }
}