$SnapshotFilePath = "$PSScriptRoot/services.json"
$LogFilePath = "$PSScriptRoot/mansvc.log"

Function Start-Checking {
    $services = Read-Config $SnapshotFilePath
    $errors = @()

    ForEach ($s in $Services){ # iter trough services

        try {
            $serv = Get-Service -Name $s -ErrorAction Stop # get service object from name
        }
        catch {
            $errors += $s
            Write-Log "Error getting service $s"
            continue
        }

        if ($serv.Status -ne "Running") { # check if service status is anything but running
            try {
                Start-Service -Name $s -ErrorAction Stop # try to start the service
                Write-Log "Service $s started"
            }
            catch {
                $errors += $s # save name if starting did not work
                Write-Log "Error starting service $s"
            }
        }
    }

    if ($errors.Count -eq 0){
        Write-Host "All services are running"
        return 0
    }
    else {
        Write-Host "Error getting/starting service(s): " ($errors -Join ", ")
        return 2
    }
}


Function New-Config {
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FilePath
    )
    $services = @()
    Get-Service | Where-Object {$_.Status -Eq "Running"} | ForEach { $services += $_.Name }
    ConvertTo-Json $services | Out-File -FilePath $FilePath
}


Function Read-Config {
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FilePath
    )
    $services = Get-Content $FilePath | ConvertFrom-Json
    return $services
}

Function Write-Log {
    Param
    (
        [String]
        $text
    )
    "[$(Get-Date -format "yyyy-MM-dd HH:mm:ss")] $text" | Out-File "$PSScriptRoot/mansvc.log" -Append
}

#* ------ Main ------
if (Test-Path $SnapshotFilePath -PathType Leaf) {
    $code = Start-Checking
}
else {
    New-Config $SnapshotFilePath
    $code = Start-Checking
}

exit $code