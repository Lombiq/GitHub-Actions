$maxTryCount = 10

for ($i = 1; $i -le $maxTryCount; $i++)
{
    echo "Waiting for SQL Server to start. Attempt $i/$maxTryCount."

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
        echo "SQL Server is successfully started."
        Exit 0
    }

    if ($i -eq $maxTryCount)
    {
        echo "SQL Server couldn't be started."
        Exit 1
    }

    echo "SQL Server is not ready. Waiting 1 second."
    Start-Sleep -s 1
}
