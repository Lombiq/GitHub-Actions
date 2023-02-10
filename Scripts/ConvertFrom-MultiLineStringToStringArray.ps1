param(
    [parameter(Mandatory = $true)]
    [string] $Lines
)

return [string]::IsNullOrWhiteSpace($Lines) ? @() : $Lines -split "`n|`r" | ForEach-Object { $PSItem.Trim() } | Where-Object { $PSItem -ne '' }
