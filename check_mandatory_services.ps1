Function Start-Checking {
    $services = Read-Config
    $errors = @()

    ForEach ($s in $Services){ # iter trough services
        $serv = Get-Service -Name $s # get service object from name
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
        Write-Host "Error starting service(s): " ($errors -Join ", ")
        return 2
    }
}


Function New-Config {
    $services = @()
    Get-Service | Where-Object {$_.Status -Eq "Running"} | ForEach { $services += $_.Name }
    ConvertTo-Json $services | Out-File -FilePath "$PSScriptRoot/services.json"
}


Function Read-Config {
    $services = Get-Content "$PSScriptRoot/services.json" | ConvertFrom-Json
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
if (Test-Path "$PSScriptRoot/services.json" -PathType Leaf) {
    $code = Start-Checking
}
else {
    New-Config
    $code = Start-Checking
}

exit $code