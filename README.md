# check_mandatory_services

Powershell script to check/change the status of services. For use with Nagios/NSClient++.

Show on Icinga (Plugins)[https://exchange.icinga.com/aaronlyy/check_mandatory_services].

## What does this script do?

At first run, this Powershell script creates a snapshot of all running services in form of a .json file.

Every run after that it will check the currently running services against the snapshot and start services to change back to running.

### Return codes

- Returns **0** if every service from the list could be started or all needed services were already running.
- Returns **2** if an error occured while starting a stopped service.

### Logging

Every change and tried change in service state will be logged with a timestamp in a file called **```mansvc.log```**.

### To Do

- Add support for stopped services
- Add exception messages to log
- Add pretty logo to make README look cool :)

## Usage (Standalone)

WIP

## Usage (with Icinga2 (Nagios) & NSClient++)

1. Download the script and move it into you're NSClient++ scripts folder
2. Add a check definition into you're nsclient.cfg
3. Restart the NSClient++ Service using **```services.msc```**
4. Create a new service config on the Icinga2 Master
5. Add the service to your host config
6. Reload Icinga2 Service using **```service icinga2 reload```**

## About

Made with ♥ by [aaronlyy](https://github.com/aaronlyy)
