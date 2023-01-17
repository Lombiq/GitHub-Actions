# With node reuse, dotnet build spawns processes that while speed up build, they can cause dotnet test and other dotnet
# tools to randomly hang. So, here we shut down those processes for later actions.
# For details see: https://github.com/Lombiq/UI-Testing-Toolbox/issues/228.
Write-Output 'Shutting down .NET build servers.'
dotnet build-server shutdown
