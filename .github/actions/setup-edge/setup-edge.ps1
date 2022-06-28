function Get-ProcessOutput
{
    Param (
        [Parameter(Mandatory=$true)]$FileName,
        $Args
    )
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.FileName = $FileName
    if($Args) { $process.StartInfo.Arguments = $Args }
    $out = $process.Start()
    
    $StandardError = $process.StandardError.ReadToEnd()
    $StandardOutput = $process.StandardOutput.ReadToEnd()
    
    $output = New-Object PSObject
    $output | Add-Member -type NoteProperty -name StandardOutput -Value $StandardOutput
    $output | Add-Member -type NoteProperty -name StandardError -Value $StandardError
    return $output
}

function Program {
    param(
        [string]
        $EdgeLinuxVersion,
        [string]
        $EdgeWindowsVersion
    )

    if ($Env:RUNNER_OS -eq "Windows")
    {
        
    }
    else
    {
        bash -c "curl -O https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_${EdgeLinuxVersion}_amd64.deb"
        bash -c "sudo apt install ./microsoft-edge-stable_${EdgeLinuxVersion}_amd64.deb"
    }
}

Program $args[0] $args[1]
