#https://github.com/VAsHachiRoku/RollingEndpointRestart
#
#Prompt for credentials to restart endpoints
$credentials = (Get-Credential)

#Array String of endpoints to control the exact order endpoints should be restarted
$Computers = "EndPnt01", "EndPnt01"

#Initalize the log file with Month, Day, Year, Hour and Minute format per script execution
$LogName = Get-Date -Format "MMddyyyy_HHmm"

#Intialize Counter for Write-Progress bar -Status message
$Counter = 1

#foreach loop, with Try and Catch statements
foreach ($Computer in $Computers) {
    try {
        #Write the progress of current endpoint being rebooted and its number in the queue
        Write-Progress -Activity 'Rolling Reboot of Endpoints' -Status "Currently Reboot Endpoint: $Computer which is $Counter out of $($Computers.Count)" -PercentComplete ((($Counter++) / $Computers.Count) * 100)
        
        #Restart the endpoint and wait for endpoint online verification, with a 5 minute timeout
        Restart-Computer -ComputerName $Computer -Wait -For PowerShell -Timeout 300 -Delay 5 -Force -Credential $credentials -ErrorAction Stop
        
        #Endpoint Successfully rebooted append to log file
        Add-Content -Path ".\SuccessfullyRebooted_$Logname.txt" -Value $Computer
    }
    #Catch statement for Restart Timeout threshold
    catch [Microsoft.PowerShell.Commands.RestartComputerTimeoutException] {
        #Endpoint restart timeout append to log file, and break out of script to avoid restarting other endpoints that may not come back online.
        Add-Content -Path ".\RebootedUnsuccessful_$Logname.txt" -Value $Computer
        break
    }
    #Catch statement for Access Denied, Offline, or Unresolvable endpoint.
    catch [System.InvalidOperationException] {
        #Unable to access or offline endpoint append to log file
        Add-Content -Path ".\Unavailable_$Logname.txt" -Value $Computer
    }
    catch {
        #Write all other error category ID types to the console
        $PSItem.exception.gettype().fullname
    }
} #end foreach
