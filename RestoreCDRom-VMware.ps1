#requires -Version 5
#requires -RunAsAdministrator
<#
.SYNOPSIS
   This script is intended to be utilized for customers who are looking to restore their IDE CDROM but would like to do so outside of a Post Recovery Fail Over scenario. The script requires an import CSV
   be prepopulated with the VM names for those machines requiring CD ROM be re-attached. Note that it is required for the VM to be powered off to attach CD ROM to it. 
   
.DESCRIPTION
   Detailed explanation of script
.EXAMPLE
   .\RestoreCDRom-VMware.ps1
.VERSION 
   Applicable versions of Zerto Products script has been tested on.  Unless specified, all scripts in repository will be 5.0u3 and later.  If you have tested the script on multiple
   versions of the Zerto product, specify them here.  If this script is for a specific version or previous version of a Zerto product, note that here and specify that version 
   in the script filename.  If possible, note the changes required for that specific version.  
.LEGAL
   Legal Disclaimer:

----------------------
This script is an example script and is not supported under any Zerto support program or service.
The author and Zerto further disclaim all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose.

In no event shall Zerto, its authors or anyone else involved in the creation, production or delivery of the scripts be liable for any damages whatsoever (including, without 
limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or the inability 
to use the sample scripts or documentation, even if the author or Zerto has been advised of the possibility of such damages.  The entire risk arising out of the use or 
performance of the sample scripts and documentation remains with you.
----------------------
#>
#------------------------------------------------------------------------------#
# Declare variables
#------------------------------------------------------------------------------#
$vCenterServer = "Enter vCenter Server IP"
$vCenterUser = "Enter vCenter Server User Name"
$vCenterPass = "Enter vCenter Server Password"
$LoggingDirectory = "Enter Transcript Logging"
$ImportCSV = "Enter CDROMVMs.csv import"
########################################################################################################################
# Nothing to configure below this line - Starting the main function of the script
########################################################################################################################
#------------------------------------------------------------------------------#
# Setting log directory for engine and current month
#------------------------------------------------------------------------------#
start-transcript $LoggingDirectory

#-----------------------------------------------------------------------------#
# Importing CSV containing VMs
#-----------------------------------------------------------------------------#
$ImportVMsCSV = Import-CSV $ImportCSV

#-----------------------------------------------------------------------------#
# Connecting to vCenter 
#-----------------------------------------------------------------------------#

Try {
Connect-VIserver $vCenterServer -User  $vCenterUser -Password $vCenterPass
}
catch {
    write-host "Caught an exception:" -ForegroundColor Red
    write-host "Cannot connect to vCenter"
    write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red

}


#-----------------------------------------------------------------------------#
# Adding cd-rom drive
#-----------------------------------------------------------------------------#
ForEach ($VM in $ImportVMsCSV){
$VMName = $VM.VMName

# Initiate Shutdown of the OS on the VM if it is Powered On
Wait-Tools -VM $VMName
$MyVM = Get-VM -name $VMName

If($MyVM.PowerState -eq "PoweredOn"){

    Write-Host "Shutting Down" $MyVM -ForegroundColor Green
    Shutdown-VMGuest -VM $MyVM -Confirm:$false
    #Wait for Shutdown to complete
    do{
        #Wait 5 seconds
        Start-sleep -Seconds 5
        #Check VM power status
        $MvM = Get-VM -name $VMName
        $status = Get-VM -Name $MyVM | Select-Object -ExpandProperty PowerState
        Write-Host "Check PowerState: Currently" $status -ForegroundColor Green
      }until($status -eq "PoweredOff")
    }


    #Adding CD Rom Drive to VM after Power Down
    Try {
            New-CDDrive -VM $MyVM
            write-host "Adding CD Rom to" $MyVM -ForegroundColor Green
        }
        catch {
            write-host "Caught an exception:" -ForegroundColor Red
            write-host "Cannot add CDROM drive to" $MyVM
            write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
            write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red

        }

 
    #Power on VM
    Start-VM -VM $MyVM -Confirm:$false
    write-host "Powering on VM:" $MyVM -ForegroundColor Green

    #Wait 60 seconds
    Write-Host "Waiting 60 seconds before next VM" -ForegroundColor Green
    Start-Sleep -Seconds 60
    
}

Write-Host "Disconnecting from vCenter, all VMs complete" -ForegroundColor Green
Disconnect-VIServer $vCenterServer -Confirm:$false
Stop-Transcript