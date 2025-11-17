$initialSpace = (Get-PSDrive -PSProvider FileSystem |
        Where-Object { $PSItem.Used -ne $null } |
        Measure-Object -Property Free -Sum).Sum

# NOT removing superseded Windows component store files, because this takes 1-2 minutes and is thus too slow.
# Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

# Remove Android SDK.
if ($Env:ANDROID_HOME)
{
    Remove-Item -Path "$Env:ANDROID_HOME" -Recurse -Force -ErrorAction SilentlyContinue
}

$extraAndroidPaths = @(
    "$Env:LOCALAPPDATA\Android",
    'C:\Android'
)

foreach ($path in $extraAndroidPaths)
{
    if (Test-Path $path)
    {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove other large caches and temp files.
Remove-Item -Path "$Env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# We can't remove all unused Docker images since that would also remove images from prepared images.
# docker image prune --all --force

# We can't remove the unused build cache since that would also remove the Elasticsearch build cache (used in the Set up
# Elasticsearch step) and any possible caches from prepared images.
# docker builder prune --all --force

# Remove Java (JDKs).
Remove-Item -Path 'C:\hostedtoolcache\windows\Java_*' -Recurse -Force -ErrorAction SilentlyContinue

# Remove Swift toolchain.
Remove-Item -Path 'C:\Program Files\Swift' -Recurse -Force -ErrorAction SilentlyContinue

# Remove Haskell (GHC).
Remove-Item -Path "$Env:LOCALAPPDATA\Programs\stack" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\ProgramData\chocolatey\lib\ghc' -Recurse -Force -ErrorAction SilentlyContinue

# Remove Julia.
Remove-Item -Path 'C:\hostedtoolcache\windows\Julia' -Recurse -Force -ErrorAction SilentlyContinue

$finalSpace = (Get-PSDrive -PSProvider FileSystem |
        Where-Object { $PSItem.Used -ne $null } |
        Measure-Object -Property Free -Sum).Sum
$freedSpace = [math]::Round(($finalSpace - $initialSpace) / 1GB, 2)
Write-Output "Freed up approximately $freedSpace GB of storage space."
