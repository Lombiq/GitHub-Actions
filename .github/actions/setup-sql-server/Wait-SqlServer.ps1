if ($Env:RUNNER_OS -ne "Windows")
{
    # Taken from: https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-ver16#ubuntu.
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
    sudo apt-get update 
    sudo apt-get install mssql-tools unixodbc-dev
    bash -c "'export PATH=\"$PATH:/opt/mssql-tools/bin\"' >> ~/.bash_profile"
    bash -c "'export PATH=\"$PATH:/opt/mssql-tools/bin\"' >> ~/.bashrc"
    bash -c "source ~/.bashrc"
}


$maxTryCount = 10

for ($i = 1; $i -le $maxTryCount; $i++)
{
    Write-Output "Waiting for SQL Server to start. Attempt $i/$maxTryCount."

    if ($Env:RUNNER_OS -eq "Windows")
    {
        sqlcmd -b -S .\SQLEXPRESS -Q "SELECT @@SERVERNAME as ServerName" 2>&1>$null
    }
    else
    {
        sqlcmd -b -U sa -P 'Password1!' -Q "SELECT @@SERVERNAME as ServerName" 2>&1>$null
    }

    if ($?)
    {
        Write-Output "SQL Server is successfully started."
        Exit 0
    }

    if ($i -eq $maxTryCount)
    {
        Write-Error "SQL Server couldn't be started."
        Exit 1
    }

    Write-Output "SQL Server is not ready. Waiting 1 second."
    Start-Sleep -s 1
}
