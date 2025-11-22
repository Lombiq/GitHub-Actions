param (
    [string] $ScriptsString = '',
    [string] $StylesString = '',
    [string] $TextsString = '')

$watchdogFileName = 'asset-linting-failed'

function ConvertTo-PathAndGlob([string] $InputString, [string] $DefaultGlob)
{
    $InputString.split(';') |
        Where-Object { $PSItem.Trim() } |
        ForEach-Object {
            $pairs = $PSItem -split ':'
            $project = Join-Path -Path $PWD -ChildPath $pairs[0].Trim()
            $glob = $pairs.Count -eq 1 ? $DefaultGlob : $pairs[1].Trim()

            [pscustomobject] @{ Project = $project; Glob = $glob }
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

function Invoke-Npx()
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingPositionalParameters',
        '',
        Justification = 'False positive on Windows.')]
    param($Package, $ProjectAndGlob, $Type, $Parameters)

    $relativePath = Resolve-Path -Path $ProjectAndGlob.Project -Relative -RelativeBasePath $basePath
    npx -y $Package $ProjectAndGlob.Glob @Parameters || Write-GitHubError -Type $Type -RelativePath $relativePath
}

$scripts = ConvertTo-PathAndGlob -InputString $ScriptsString -DefaultGlob 'wwwroot/js'
if ($scripts.Count -gt 0)
{
    $copiedItems = Initialize-Npm -CopyFrom js

    foreach ($pair in $scripts)
    {
        $parameters = @('--max-warnings', '0')
        Invoke-Npx -Package eslint -ProjectAndGlob $pair -Type JavaScript -Parameters $parameters
    }

    # Clean up copied files. The -Force switch is needed to remove hidden items (i.e. dotfiles in Unix).
    $copiedItems | Remove-Item -Force
}

$styles = ConvertTo-PathAndGlob -InputString $StylesString -DefaultGlob '**/*.css'
if ($styles.Count -gt 0)
{
    $copiedItems = Initialize-Npm -CopyFrom css

    foreach ($pair in $styles)
    {
        Invoke-Npx -Package stylelint -ProjectAndGlob $pair -Type CSS
    }

    $copiedItems | Remove-Item -Force
}

$texts = ConvertTo-PathAndGlob -InputString $TextsString -DefaultGlob '**/*.{md,markdown}'
if ($texts.Count -gt 0)
{
    $copiedItems = Initialize-Npm -CopyFrom md

    foreach ($pair in $texts)
    {
        Invoke-Npx -Package markdownlint-cli2 -ProjectAndGlob $pair -Type 'Markdown (markdownlint-cli2)'
        Invoke-Npx -Package textlint -ProjectAndGlob $pair -Type 'Markdown (textlint)'
    }

    $copiedItems | Remove-Item -Force
}

if (Test-Path $watchdogFileName)
{
    Remove-Item $watchdogFileName
    exit 1
}
