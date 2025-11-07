[Diagnostics.CodeAnalysis.SuppressMessage(
    'PSAvoidUsingPositionalParameters',
    '',
    Justification = 'Join-Path has really chaotic named parameters, basically unreadable.')]
param (
    [string] $LibraryPath,
    [string] $Type,
    [string] $Paths)

function Test-NoPath($Paths) { -not (Test-Path -Path $Paths | Where-Object { $PSItem }) }

function Install-NodeJsPackage($LibraryPath)
{
    if (Test-NoPath -Paths package.json, package.json5, package.yaml)
    {
        Copy-Item $LibraryPath/config/consumer/package.project.json package.json
    }

    if (Test-NoPath -Paths eslint.config.js, eslint.config.cjs, eslint.config.mjs)
    {
        Copy-Item $LibraryPath/config/consumer/.eslintrc.project.js eslint.config.cjs
    }

    if (Test-NoPath -Paths .prettierrc, .prettierrc.js)
    {
        Copy-Item $LibraryPath/config/consumer/.prettierrc.project.js .prettierrc.js
    }

    $styleLintPaths = @(
        '.stylelintrc'
        '.stylelintrc.js'
        '.stylelintrc.mjs'
        '.stylelintrc.cjs'
        '.stylelintrc.yml'
        '.stylelintrc.yaml'
        '.stylelintrc.json'
        'stylelint.config.js'
        'stylelint.config.mjs'
        'stylelint.config.cjs'
    )
    if (Test-NoPath -Paths $styleLintPaths)
    {
        Copy-Item $LibraryPath/config/consumer/.stylelintrc.project.js .stylelintrc.js
    }

    pnpm link --global nodejs-extensions
    node $LibraryPath/scripts/add-dev-dependencies.js
}

if ($Paths.Trim())
{
    $startPath = $PWD.Path

    if ($Paths.Trim().StartsWith('{'))
    {
        $pathItems = $Paths | ConvertFrom-Json -AsHashtable
        $pathItems.Keys | ForEach-Object {
            $projectPath = (Get-Item $PSItem).FullName
            $sourcePath = Join-Path $LibraryPath 'config' 'consumer' 'package.project.json'
            $targetPath = Join-Path $projectPath 'package.json'

            # In this case we assume that there is no project.json file, otherwise the config would already be in it.
            $json = Get-Content $sourcePath | ConvertFrom-Json
            $json | Add-Member -Type NoteProperty -Name 'nodejsExtensions' $pathItems[$PSItem]
            $json | ConvertTo-Json | Out-File -FilePath $targetPath

            # Verify results.
            Write-Output "Package file output: $targetPath"
            Get-Content $targetPath
        }

        $Paths = $pathItems.Keys -join ','
    }

    $absolutePaths = $Paths.Split(',') |
        ForEach-Object { $PSItem.Trim() } |
        Where-Object { $PSItem } |
        Get-Item |
        ForEach-Object { $PSItem.FullName }

    foreach ($projectPath in $absolutePaths)
    {
        Set-Location $projectPath
        Install-NodeJsPackage -LibraryPath $LibraryPath
        npm explore nodejs-extensions -- pnpm "lint:$Type"
    }

    Set-Location $startPath
}
