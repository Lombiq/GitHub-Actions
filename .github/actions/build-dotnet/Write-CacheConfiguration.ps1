param($IsNuget, $IsNpm, $RestoreKeys, $Hash)

function Set-Output($Key, $Value) { Write-Output "$Key=$Value" >> $GITHUB_OUTPUT }
function Invoke-Maybe($Block) { try { Invoke-Command -ScriptBlock $Block } catch { return } }

$paths = @()

if ($IsNuget) { $paths += ,'~/.nuget/packages' }

if ($IsNpm)
{
    (Invoke-Maybe { pnpm store path }), (npm config get cache) |
        ? { -not [string]::IsNullOrEmpty($_) } |
        % { $paths += $_ }
}

# Ensure the paths exist.
$paths | % { New-Item -ItemType Directory -Force $_ } | Out-Null

# Multiple paths must be separated by "\n", but we can't include newline in the workflow command so we have to misuse
# the format function like this.
Set-Output 'paths' ($paths -join '{0}')

Set-Output 'cache-enabled' 'true'
Set-Output 'key' "${RestoreKeys}-${Hash}"
Set-Output 'restore-keys' $RestoreKeys
