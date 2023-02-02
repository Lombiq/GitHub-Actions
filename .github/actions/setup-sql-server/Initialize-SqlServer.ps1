if ($Env:RUNNER_OS -eq 'Windows')
{
    choco install sql-server-express --no-progress
}
else
{
    $dockerRunSwitches = @(
        '--name', 'sql2019'
        '--env', 'ACCEPT_EULA=Y'
        '--env', 'SA_PASSWORD=Password1!'
        '--publish', '1433:1433'
        '--detach', 'mcr.microsoft.com/mssql/server:2019-latest'
    )

    docker pull mcr.microsoft.com/mssql/server &&
    docker run @dockerRunSwitches &&
    docker exec --user 0 sql2019 bash -c 'mkdir /data; chmod 777 /data --recursive; chown mssql:root /data'
}
