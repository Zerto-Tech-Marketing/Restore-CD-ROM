#requires -RunAsAdministrator
<#
.SYNOPSIS
   This script is intended to be utilized as a Post Recovery script for Zerto customers who are failing over to a VMware environment and require an IDE CD ROM to be attached to their VMs. The user will
   need to provide an Import CSV before the Post Recovery Operation that lists the names of the VMs which require CD ROM addition. Note that after the Fail Over Recovery Operation has created and 
   powered on the VM, this script will power off the VM as VMware requires a VM to be powered down when adding an IDE CD ROM.   
   The script will only execute during a Fail Over Live or Move Operation, these values can be changed by editing line 71
.DESCRIPTION
   Detailed explanation of script
.EXAMPLE
   .\CDROMRestore-VMware.ps1
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
to use the sample scripts or documentation, even if the author or Zerto has been advised of the possibility of such damages.  The 

entire risk arising out of the use or 
performance of the sample scripts and documentation remains with you.
----------------------
#>
#------------------------------------------------------------------------------#
# Declare variables
#------------------------------------------------------------------------------#
$vCenterServer = "Enter vCenter Server"
$vCenterUser = "Enter vCenter User"
$vCenterPass = "Enter vCenter Password"
$LoggingDirectory = "Enter Transcript Location"
$ImportCSV = "Enter Import CSV Location"
$NoOperationOutput = "Enter Output file location"
########################################################################################################################
# Nothing to configure below this line - Starting the main function of the script
########################################################################################################################
#------------------------------------------------------------------------------#
# Setting log directory for engine and current month
#------------------------------------------------------------------------------#
start-transcript $LoggingDirectory

#Get Zerto Operation from Zerto Virtual Manager
$Operation = $env:ZertoOperation


#-------------------------------------------------------------------------------#
# Importing PowerCLI snap-in required for successful authentication with Zerto API
#-------------------------------------------------------------------------------#
function LoadSnapin{
  param($PSSnapinName)
  if (!(Get-PSSnapin | where {$_.Name   -eq $PSSnapinName})){
    Add-pssnapin -name $PSSnapinName
  }
}
# Loading snapins and modules
LoadSnapin -PSSnapinName   "VMware.VimAutomation.Core"


#If you want to test the script, uncomment below to hardcode Operation
#$Operation = "FailOverBeforeCommit"

#If the Zerto Operation is a Test, exit Script
If ($Operation -eq "FailoverBeforeCommit" -or $Operation -eq "MoveBeforeCommit"){

Write-Host "Beginning connection to vCenter to add CDROM" -ForegroundColor Green


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

#Wait 60 seconds to ensure virtual machine has successfully powered on
Start-Sleep 60

#-----------------------------------------------------------------------------#
# Adding cd-rom drive
#-----------------------------------------------------------------------------#
ForEach ($VM in $ImportVMsCSV){
$VMName = $VM.VMName

# Initiate Shutdown of OS
Wait-Tools -VM $VMName
$MyVM = Get-VM -name $VMName

If($MyVM.PowerState -eq "PoweredOn"){

    Write-Host "Shutting Down" $MyVM -ForegroundColor Green
    #Shutdown-VMGuest -VM $MyVM -Confirm:$false
    Stop-VMGuest -VM $MyVM -Confirm:$false
    #Wait for Shutdown to complete
    do{
        #Wait 10 seconds
        Start-sleep -Seconds 10
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

    #Wait 15 seconds before next task
    Write-Host "Waiting 15 seconds before next task" -ForegroundColor Green
    Start-Sleep -Seconds 15
    
}

}

Else{
$NoOperation = "Current Zerto Operations does not call for CD ROM addition for VM $MyVM"
$NoOperation | Out-File -filepath $NoOperationOutput

}

Write-Host "Disconnecting from vCenter, all tasks complete" -ForegroundColor Green
Disconnect-VIServer $vCenterServer -Confirm:$false
Stop-Transcript