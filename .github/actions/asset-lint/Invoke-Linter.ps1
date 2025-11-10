param (
    [string] $ScriptsString = '',
    [string] $StylesString = '')

$basePath = $PWD.Path

# Create a new temporary directory for storing dependencies.
$temporaryDirectoryPath = (New-TemporaryFile).FullName
Remove-Item -Path $temporaryDirectoryPath -Force
New-Item -ItemType Directory -Path $temporaryDirectoryPath

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

function Push-TempNpm($CopyFrom)
{
    Push-Location $temporaryDirectoryPath
    npm init -y
    Get-ChildItem (Join-Path $PSScriptRoot $CopyFrom) -Force | ForEach-Object { Copy-Item $PsItem . }
    npm install
}

function Get-RelativePath($Path) { Resolve-Path -Path $Path -Relative -RelativeBasePath $basePath }

$scripts = ConvertTo-PathAndGlob -InputString $ScriptsString -DefaultGlob '**/*.js'
if ($scripts.Count -gt 0)
{
    Push-TempNpm -CopyFrom js -Packages @('stylelint-config-standard')

    foreach ($pair in $scripts)
    {
        $relativePath = Get-RelativePath -Path $pair.Project

        # We don't try to format the individual warnings as GitHub notifications, because if the file points to a
        # submodule then it won't appear in the summary.
        npx -y eslint $pair.Glob || 
            Write-Output "::error::JavaScript linting has failed for project `"$relativePath`". Please check the log for details!"
    }

    Pop-Location
}

$styles = ConvertTo-PathAndGlob -InputString $StylesString -DefaultGlob '**/*.css'
if ($styles.Count -gt 0)
{
    Push-TempNpm -CopyFrom css -Packages @('stylelint-config-standard')

    foreach ($pair in $styles)
    {
        $relativePath = Get-RelativePath -Path $pair.Project

        npx -y stylelint $pair.Glob || 
            Write-Output "::error::CSS linting has failed for project `"$relativePath`". Please check the log for details!"
    }

    Pop-Location
}

# Clear out temporary files.
Remove-Item -Path $temporaryDirectoryPath -Recurse -Force
