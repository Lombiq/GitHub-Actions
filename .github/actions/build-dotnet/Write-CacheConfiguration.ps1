function Invoke-Maybe($Block) { try { Invoke-Command -ScriptBlock $Block } catch { return } }

function Write-CacheConfiguration($IsNuget, $IsNpm, $RestoreKeys, $Hash)
{
    $paths = @()

    if ($IsNuget) { $paths += , '~/.nuget/packages' }

    if ($IsNpm)
    {
    (Invoke-Maybe { pnpm store path }), (npm config get cache) |
            Where-Object { -not [string]::IsNullOrEmpty($PSItem) } |
            ForEach-Object { $paths += $PSItem }
    }

    # Ensure the paths exist.
    $paths | ForEach-Object { New-Item -ItemType Directory -Force $PSItem } | Out-Null

    # Multiple paths must be separated by "\n", but we can't include newline in the workflow command so we have to misuse
    # the format function like this.
    Set-GitHubOutput 'paths' ($paths -join '{0}')

    Set-GitHubOutput 'cache-enabled' 'true'
    Set-GitHubOutput 'key' "${RestoreKeys}-${Hash}"
    Set-GitHubOutput 'restore-keys' $RestoreKeys
}
