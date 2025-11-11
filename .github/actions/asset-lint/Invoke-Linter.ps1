param (
    [string] $ScriptsString = '',
    [string] $StylesString = '')

$basePath = $PWD.Path

function ConvertTo-PathAndGlob([string] $InputString, [string] $DefaultGlob)
{
    $InputString.split(',') |
        Where-Object { $PsItem.Trim() } |
        ForEach-Object {
            $pairs = $PsItem -split ':'
            $project = Join-Path -Path $basePath -ChildPath $pairs[0].Trim()
            $glob = $pairs.Count -eq 1 ? $DefaultGlob : $pairs[1].Trim()

            [pscustomobject] @{
                Project = $project;
                Glob = (Join-Path $project $glob)
            }
        }
}

function Init-Npm($CopyFrom)
{
    $copiedItems = Get-ChildItem (Join-Path $PSScriptRoot $CopyFrom) -Force | 
        Where-Object { -not (Test-Path $PsItem.Name) } |
        Copy-Item -Destination . -PassThru
    npm install | Write-Information -InformationAction Continue

    return $copiedItems
}

$scripts = ConvertTo-PathAndGlob -InputString $ScriptsString -DefaultGlob 'wwwroot/js/**'
if ($scripts.Count -gt 0)
{
    $copiedItems = Init-Npm -CopyFrom js
    Write-Error ($copiedItems -join ', ')

    foreach ($pair in $scripts)
    {
        $relativePath = Resolve-Path -Path $pair.Project -Relative -RelativeBasePath $PWD

        # We don't try to format the individual warnings as GitHub notifications, because if the file points to a
        # submodule then it won't appear in the summary.
        npx -y eslint $pair.Glob || 
            Write-Output "::error::JavaScript linting has failed for project `"$relativePath`". Please check the log for details!"
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

    Init-Npm -CopyFrom css

    foreach ($pair in $styles)
    {
        $relativePath = Resolve-Path -Path $pair.Project -Relative -RelativeBasePath $basePath

        npx -y stylelint $pair.Glob || 
            Write-Output "::error::CSS linting has failed for project `"$relativePath`". Please check the log for details!"
    }

    # Reset location and clean up temporary files.
    Pop-Location
    Remove-Item -Path $temporaryDirectoryPath -Recurse -Force
}
