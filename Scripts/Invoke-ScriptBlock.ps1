param (
    [int] $TimeoutMinutes,
    [string] $Name,
    [ScriptBlock] $ScriptBlock,
    [array] $ArgumentList
)

if ($TimeoutMinutes -gt 0)
{
    # If there is a timeout, run the commandlet as a job so "Wait-Job" can manage the limit.
    Write-Output "Starting `"$Name`" as a separate job that must finish within $TimeoutMinutes minutes."

    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    $completed = Wait-Job -Job $job -Timeout ($TimeoutMinutes * 60)

    if ($null -eq $completed)
    {
        Write-Output "::error::The `"$Name`" job did not finish within $TimeoutMinutes minutes."
        $job | Stop-Job | Remove-Job
        exit 1
    }

    Receive-Job -Job $job
    Remove-Job -Job $job
}
else
{
    Invoke-Command -ScriptBlock $ScriptBlock
}