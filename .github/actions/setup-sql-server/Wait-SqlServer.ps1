$maxTryCount = 10

for ($i = 1; $i -le $maxTryCount; $i++)
{
    Write-Output "Waiting for SQL Server to start. Attempt $i/$maxTryCount."

    # The -C switch is to trust the server certificate, which was added for the process to work on Ubuntu 24.04-based
    # runners where sqlcmd had to be installed manually. It's not an issue, since the server is running locally.
    if ($Env:RUNNER_OS -eq 'Windows')
    {
        sqlcmd -C -b -S .\SQLEXPRESS -Q 'SELECT @@SERVERNAME as ServerName' 2>&1>$null
    }
    else
    {
        sqlcmd -C -b -U sa -P 'Password1!' -Q 'SELECT @@SERVERNAME as ServerName' 2>&1>$null
    }

    if ($?)
    {
        Write-Output 'SQL Server is successfully started.'
        Exit 0
    }

    if ($i -eq $maxTryCount)
    {
        Write-Error "SQL Server couldn't be started."
        Exit 1
    }

    Write-Output 'SQL Server is not ready. Waiting 1 second.'
    Start-Sleep -s 1
}
