if ($Env:RUNNER_OS -eq "Windows")
{
    choco install sql-server-express --no-progress
}
else
{
    # Commands taken from https://github.com/ankane/setup-sqlserver.
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    wget -qO- https://packages.microsoft.com/config/ubuntu/$(. /etc/os-release && echo $VERSION_ID)/mssql-server-${sqlserverVersion}.list | sudo tee /etc/apt/sources.list.d/mssql-server-${sqlserverVersion}.list
    sudo apt-get update
    sudo apt-get install mssql-server mssql-tools
    sudo MSSQL_SA_PASSWORD='Password1!' MSSQL_PID=Express /opt/mssql/bin/mssql-conf -n setup accept-eula
}
