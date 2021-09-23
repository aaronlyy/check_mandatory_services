#* check_mandatory_services.ps1
#* https://github.com/aaronlyy/check_mandatory_services
#* Last update: 23.09.2021

#Region Parameters
Param(
    [String]$SnapshotFilePath = "$PSScriptRoot/services.json",
    [String]$LogFilePath = "$PSScriptRoot/mansvc.log"
)
#Endregion


#* --- Start-Checking ------------------------------------------------------------------------
#* Takes a file path to a .json file containing a list of services                           -
#* Checks if every service in the list is currently running, if not serivce will be started. -
#* Returns 0 if every service could be started or every service was already running          -
#* Returns 2 if an error occured during checking                                             -
#* -------------------------------------------------------------------------------------------
#Region Start-Checking
Function Start-Checking {
    $services = Read-Snapshot $SnapshotFilePath
    $errors = @()

    ForEach ($s in $Services){ # iter trough services
        $serv = Get-Service -Name $s # get service object from name
        if ($serv.Status -Ne "Running") { # check if service status is anything but running
            try {
                Start-Service -Name $s -ErrorAction Stop # try to start the service
                Write-Log -Content "Service $s started" -FilePath $LogFilePath
            }
            catch {
                $errors += $s # save name if starting did not work
                Write-Log -Content "Error starting service $s" -FilePath $LogFilePath
            }
        }
    }

    if ($errors.Count -Eq 0){
        Write-Host "All services are running"
        return 0
    }
    else {
        Write-Host "Error starting service(s): " ($errors -Join ", ")
        return 2
    }
}
#Endregion


#* --- New-Snapshot ----------------------------------------------------------------------------
#* This function takes a filename and creates a new <filename>.json file with all currently    -
#* running services.                                                                           -
#* ---------------------------------------------------------------------------------------------
#Region New-Snapshot
Function New-Snapshot {
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FilePath
    )

    $services = @()
    Get-Service | Where-Object {$_.Status -Eq "Running"} | ForEach { $services += $_.Name }
    ConvertTo-Json $services | Out-File -FilePath $FilePath
}
#Endregion


#* --- Read-Snapshot ----------------------------------------------------------------------------
#* This function takes a filename and parses the JSON to an array of all running services       -
#* Returns the array.                                                                           -
#* ----------------------------------------------------------------------------------------------
#Region Read-Snapshot
Function Read-Snapshot {
    Param(
    [Parameter(Mandatory=$True)]
    [String]$FilePath
    )

    $services = Get-Content $FilePath | ConvertFrom-Json
    return $services
}
#Endregion

#* --- Write-Log -------------------------------------------------------------------
#* This function takes content and a filepath and writes it to a file              -
#* ---------------------------------------------------------------------------------
#Region Write-Log
Function Write-Log {
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Content,

        [Parameter(Mandatory=$True)]
        [String]$FilePath
    )

    "[$(Get-Date -format "yyyy-MM-dd HH:mm:ss")] $Content" | Out-File $FilePath -Append
}
#Endregion



#Region Main
if (Test-Path $SnapshotFilePath -PathType Leaf) {
    $code = Start-Checking
}
else {
    New-Snapshot $SnapshotFilePath
    $code = Start-Checking
}
exit $code
#Endregion