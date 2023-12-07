if ($Env:RUNNER_OS -eq 'Windows')
{
    choco install sql-server-2022 --no-progress
}
else
{
    $sqlServerName = 'sql2022'
    $sqlServerVersion = '2022-latest'
    $dockerRunSwitches = @(
        '--name', $sqlServerName
        '--env', 'ACCEPT_EULA=Y'
        '--env', 'SA_PASSWORD=Password1!'
        '--publish', '1433:1433'
        '--detach', "mcr.microsoft.com/mssql/server:$sqlServerVersion"
    )

    docker pull "mcr.microsoft.com/mssql/server:$sqlServerVersion" &&
    docker run @dockerRunSwitches &&
    docker exec --user 0 $sqlServerName bash -c 'mkdir /data; chmod 777 /data --recursive; chown mssql:root /data'
}
