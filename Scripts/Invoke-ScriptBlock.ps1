param (
    [int] $TimeoutMinutes,
    [string] $Name,
    [ScriptBlock] $ScriptBlock,
    [array] $ArgumentList,
    [boolean] $ShowTimeRemainingUntilTimeout)

if ($TimeoutMinutes -gt 0)
{
    # If there is a timeout, run the commandlet as a job so "Wait-Job" can manage the limit.
    Write-Output "Starting `"$Name`" as a separate job that must finish within $TimeoutMinutes minutes."

    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList

    while ($job.HasMoreData -or $job.JobStateInfo.State -eq [System.Management.Automation.JobState]::Running)
    {
        Receive-Job $job | Tee-Object -Variable line | Write-Output

        $timeRemaining = $TimeoutMinutes - $stopWatch.Elapsed.TotalMinutes
        if ($timeRemaining -lt 0)
        {
            Write-GitHub "The `"$Name`" job did not finish within $TimeoutMinutes minutes."
            $job | Stop-Job | Remove-Job
            exit 1
        }

        if ($ShowTimeRemainingUntilTimeout)
        {
            Write-Output "Until timeout: $([Math]::Ceiling($timeRemaining)) minutes"
        }
    }

    Receive-Job -Job $job
    Remove-Job -Job $job
}
else
{
    Invoke-Command -ScriptBlock $ScriptBlock
}