if (-not (Test-Path dependencies.xml)) { exit 0 }

$fileName = (Get-Childitem *.nuspec).FullName
$nuspec = [xml](Get-Content $fileName)
$group = $nuspec.package.metadata.dependencies.group

foreach($dependency in ([xml](Get-Content dependencies.xml)).dependencies.dependency)
{
    $node = $nuspec.ImportNode($dependency, $True)
    $group.AppendChild($node)
}

$nuspec.Save($fileName)
