Function Get-RunningServices {
    # returns an array of all running services that don't match a specific filter
    $filter = @( # array of regex strings 
        "WdiSystemHost",
        "CDPUserSvc_.+",
        "WpnUserService_.+",
        "PrintWorkflowUserSvc_.+",
        "OneSyncSvc_.+",
        "NPSMSvc_.+",
        "UserDataSvc_.+",
        "UnistoreSvc_.+",
        "UdkUserSvc_.+",
        "PimIndexMaintenanceSvc_.+",
        "cbdhsvc_.+",
        "DevicesFlowUserSvc_.+"
    )
    $filterString = $filter -Join "|" # join regex strings to one long regex string
    $services = @()
    Get-Service | Where-Object {$_.Status -Eq "Running" -And $_.Name -Notmatch $filterString} | ForEach {$services += $_.Name} # write names into array
    return $services
}

Function New-Config {
    # takes an array an saves it into a json document
    Param(
        [Parameter(Mandatory=$True)][String[]]$Services
    )
    ConvertTo-Json $Services | Out-File -FilePath "$PSScriptRoot/services.json"
}

Function Read-Config {
    # returns an array of servicenames from a config file
    $services = Get-Content "$PSScriptRoot/services.json" | ConvertFrom-Json # open file and parse json
    return $services
}

Function Test-Config {
    # checks if a config file exists
    if (Test-Path "$PSScriptRoot/services.json" -PathType leaf) {
        return $True
    }
    else {
        return $False
    }
}

Function Write-Log {
    # writes given text into a new line in the logfile
    Param
    (
        [Parameter(Mandatory=$True)]
        [String]$text
    )
    "[$(Get-Date -format "yyyy-MM-dd HH:mm:ss")] $text" | Out-File "$PSScriptRoot/mansvc.log" -Append
}

Function Test-Service {
    # return true if given service is running else false
    Param(
        [Parameter(Mandatory=$True)][String]$ServiceName
    )
    $service = Get-Service -Name $ServiceName
    if ($service.Status -Eq "Running"){
        return $True
    }
    else {
        $False
    }
}


# --- main ---
# config checking
if (-Not (Test-Config)) { # check if no config exists
    $services = Get-RunningServices # get currently running services
    New-Config -Services $services # create a new config
    Write-Log -Text "Config created"
}

# read config
$config = Read-Config

# error, etc arrays
$getErrors = @()
$startErrors = @()
$stopErrors = @()

$startedServices = @()

# loop through config and start not running services
foreach ($s in $config) {
    # try to get service
    try {
        $service = Get-Service -Name $s -ErrorAction Stop
    }
    catch {
        Write-Log -Text "$s - Error getting service"
        $getErrors += $s # add service to getError if service could
        continue
    }

    # check if service is not running and start if so
    if ($service.Status -Ne "Running") {
        # try to start service
        try {
            Start-Service -Name $s -ErrorAction Stop
            $startedServices += $s
            Write-Log -Text "$s - Service started"
        }
        catch {
            Write-Log -Text "$s - Error starting service"
            $startErrors += $s
        }
    }
}

# check started services again
foreach ($s in $startedServices) {
    $service = Get-Service -Name $s
    if ($service.Status -Ne "Running") {
        Write-Log -Text "$s - Service was started but stopped right after"
        $stopError += $s
    }
}

# return code & return message

if ($startErrors.Count -Eq 0 -And $getErrors.Count -Eq 0 -And $stopErrors.Count -Eq 0) {
    $code = 0
    $message = "All services are running"
}
else {
    $code = 2
    $message = "Get errors: $getErrors`nStart errors: $startErrors`nStop errors: $stopErrors"
}

Write-Host $message
exit $code