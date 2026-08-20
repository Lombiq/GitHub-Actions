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
        Receive-Job $job | Tee-Object -Variable lines | Write-Output

        $timeRemaining = ($TimeoutMinutes * 60) - $stopWatch.Elapsed.TotalSeconds
        if ($timeRemaining -lt 0)
        {
            Write-GitHub "The `"$Name`" job did not finish within $TimeoutMinutes minutes."
            $job | Stop-Job | Remove-Job
            exit 1
        }

        # Stop if the job sent a GHA error message.
        if (($lines | Where-Object { "$PSItem".Trim().StartsWith('::error') }).Count -gt 0)
        {
            # We wait for a few more seconds in case further relevant information is delivered.
            Start-Sleep -Seconds 3

            Stop-Job -Job $job
            Receive-Job -Job $job
            Remove-Job -Job $job

            Write-GitHub "The `"$Name`" job caused an error. ."
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
        exit 1
    }
}
else
{
    Invoke-Command -ScriptBlock $ScriptBlock
}