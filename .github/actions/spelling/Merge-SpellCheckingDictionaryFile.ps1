<#
.Synopsis
    Merges entries from one dictionary file into another.

.DESCRIPTION
    Merges the entries from the source dictionary file into the target dictionary file, then removes duplicates and
    sorts the entries alphabetically.

.EXAMPLE
    Merge-SpellCheckingDictionaryFile -Source C:\dev\lombiq-excludes.txt -Target C:\dev\custom-excludes.txt
#>

param(
    [parameter(
        Mandatory = $true,
        HelpMessage = 'The path to a dictionary file whose entries you want to merge into another dictionary file.')]
    [string] $Source,

    [parameter(
        Mandatory = $true,
        HelpMessage = "The path to the dictionary file to merge entries into. Will be created if it doesn't exist.")]
    [string] $Target
)

$sourceDictionary = Get-Content -Path $Source
$targetDictionary = (Test-Path -Path $Target -PathType Leaf) ? (Get-Content -Path $Target) : @()

$targetDictionary = $sourceDictionary + $targetDictionary | Sort-Object -Unique

Set-Content -Path $Target -Value $targetDictionary -Force
