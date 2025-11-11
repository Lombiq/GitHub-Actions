param (
    [string] $ScriptsString = '',
    [string] $StylesString = '')

$basePath = $PWD.Path
$watchdogFileName = 'asset-linting-failed'

function ConvertTo-PathAndGlob([string] $InputString, [string] $DefaultGlob)
{
    $InputString.split(',') |
        Where-Object { $PSItem.Trim() } |
        ForEach-Object {
            $pairs = $PSItem -split ':'
            $project = Join-Path -Path $basePath -ChildPath $pairs[0].Trim()
            $glob = $pairs.Count -eq 1 ? $DefaultGlob : $pairs[1].Trim()

            [pscustomobject] @{ Project = $project; Glob = (Join-Path $project $glob) }
        }
}

function Initialize-Npm($CopyFrom)
{
    $copiedItems = Get-ChildItem (Join-Path $PSScriptRoot $CopyFrom) -Force |
        Where-Object { -not (Test-Path $PSItem.Name) } |
        Copy-Item -Destination . -PassThru
    npm install | Write-Information -InformationAction Continue

    return $copiedItems
}

function Write-GitHubError($Type, $RelativePath)
{
    # We have a single error notification and don't try to format the individual linter warnings as GitHub
    # notifications, because if the file points to a submodule then the message won't appear in the run summary.
    Write-Output "::error::$Type linting has failed for project `"$RelativePath`". Please check the log for details!"
    Out-File -FilePath $watchdogFileName
}

$scripts = ConvertTo-PathAndGlob -InputString $ScriptsString -DefaultGlob 'wwwroot/js'
if ($scripts.Count -gt 0)
{
    $copiedItems = Initialize-Npm -CopyFrom js

    foreach ($pair in $scripts)
    {
        $relativePath = Resolve-Path -Path $pair.Project -Relative -RelativeBasePath $PWD

        npx -y eslint $pair.Glob --max-warnings 0 || Write-GitHubError -Type JavaScript -RelativePath $relativePath
    }

    # Clean up copied files. The -Force switch is needed to remove hidden items (i.e. dotfiles in Unix).
    $copiedItems | Remove-Item -Force
}

$styles = ConvertTo-PathAndGlob -InputString $StylesString -DefaultGlob '**/*.css'
if ($styles.Count -gt 0)
{
    # Create a new temporary directory for storing dependencies.
    $temporaryDirectoryPath = (New-TemporaryFile).FullName
    Remove-Item -Path $temporaryDirectoryPath -Force
    New-Item -ItemType Directory -Path $temporaryDirectoryPath
    Push-Location $temporaryDirectoryPath

    Initialize-Npm -CopyFrom css
    @('.stylelintignore', 'stylelint.config.mjs') |
        ForEach-Object { Join-Path $basePath $PSItem } |
        Where-Object { Test-Path $PSItem } |
        Get-Item |
        Copy-Item .

    foreach ($pair in $styles)
    {
        $relativePath = Resolve-Path -Path $pair.Project -Relative -RelativeBasePath $basePath

        npx -y stylelint $pair.Glob || Write-GitHubError -Type CSS -RelativePath $relativePath
    }

    # Reset location and clean up temporary files.
    Pop-Location
    Remove-Item -Path $temporaryDirectoryPath -Recurse -Force
}

if (Test-Path $watchdogFileName)
{
    Remove-Item $watchdogFileName
    exit 1
}
