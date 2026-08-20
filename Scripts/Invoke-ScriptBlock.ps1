param (
    [int] $TimeoutMinutes,
    [string] $Name,
    [ScriptBlock] $ScriptBlock,
    [array] $ArgumentList,
    [boolean] $ShowDiagnostics)

if ($TimeoutMinutes -gt 0)
{
    # If there is a timeout, run the commandlet as a job so "Wait-Job" can manage the limit.
    Write-Output "Starting `"$Name`" as a separate job that must finish within $TimeoutMinutes minutes."

    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    $failed = $false

    while ($job.HasMoreData -or $job.JobStateInfo.State -eq [System.Management.Automation.JobState]::Running)
    {
        Receive-Job $job

        $timeRemaining = ($TimeoutMinutes * 60) - $stopWatch.Elapsed.TotalSeconds
        if ($timeRemaining -lt 0)
        {
            Write-GitHub "The `"$Name`" job did not finish within $TimeoutMinutes minutes."
            $job | Stop-Job | Remove-Job
            exit 1
        }

        if ($ShowDiagnostics)
        {
            Write-Output "Until timeout: $([Math]::Ceiling($timeRemaining)) seconds."

            if ($isLinux)
            {
                $memoryTotal = [int](free -m | awk '/Mem/{print $2}')
                $memoryUsed = [int](free -m | awk '/Mem/{print $3}')
                $memoryPercent = 100.0 * $memoryUsed / $memoryTotal
                Write-Output ('Memory used: {0} MB ({1:0.00}%)' -f $memoryUsed, $memoryPercent)
            }
        }

        Start-Sleep -Seconds 5
    }

    $failed = $failed || $job.State -eq 'Stopped' || ($job.ChildJobs.Count -gt 0 -and $job.ChildJobs[0].State -eq 'Stopped')

    Receive-Job -Job $job
    Remove-Job -Job $job
    
    if ($failed)
    {
        throw "The `"$Name`" job failed."
    }
}
else
{
    Invoke-Command -ScriptBlock $ScriptBlock
}