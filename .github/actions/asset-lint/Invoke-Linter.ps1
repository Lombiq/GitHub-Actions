param (
    [string] $StylesString = '')

$RelativeBasePath = $PWD.Path

# Create a new temporary directory for storing dependencies.
$TemporaryDirectoryPath = (New-TemporaryFile).FullName
Remove-Item -path $TemporaryDirectoryPath -Force
New-Item -ItemType Directory -Path $TemporaryDirectoryPath
"LOMBIQ_TEMP=$TemporaryDirectoryPath" >> $Env:GITHUB_ENV

$styles = $StylesString.split(',') |
    Where-Object { $PsItem.Trim() } |
    ForEach-Object { Join-Path $PWD $PsItem.Trim() } |
    Where-Object { Test-Path $PsItem } |
    ForEach-Object { Get-Item $PsItem }
if ($styles.Count -gt 0)
{
    Push-Location $TemporaryDirectoryPath
    Copy-Item (Join-Path $PSScriptRoot .stylelintignore) .
    Copy-Item (Join-Path $PSScriptRoot stylelint.config.mjs) .
    npm init -y
    npm install stylelint-config-standard

    foreach ($style in $styles)
    {
        $RelativePath = Resolve-Path -Path $style -Relative -RelativeBasePath $RelativeBasePath;

        # We don't try to format the individual warnings as GitHub notifications, because if the file points to a
        # submodule then it won't appear in the summary.
        npx -y stylelint (Join-Path $style '**/*.css') || 
            Write-Output "::error::CSS linting has failed for project `"$RelativePath`". Please check the log for details!"
    }

    Pop-Location
}