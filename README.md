# Legal Disclaimer
This script is an example script and is not supported under any Zerto support program or service.
The author and Zerto further disclaim all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose.

In no event shall Zerto, its authors or anyone else involved in the creation, production or delivery of the scripts be liable for any damages whatsoever (including, without 
limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or the inability 
to use the sample scripts or documentation, even if the author or Zerto has been advised of the possibility of such damages.  The entire risk arising out of the use or 
performance of the sample scripts and documentation remains with you.

# Restore-CD-ROM
This script (CDROMRestore-VMware-PostRecovery.ps1) is intended to be utilized as a Post Recovery script for Zerto customers who are failing over to a VMware environment and require an IDE CD ROM to be attached to their VMs. The user will
need to provide an Import CSV before the Post Recovery Operation that lists the names of the VMs which require CD ROM addition. Note that after the Fail Over Recovery Operation has created and 
powered on the VM, this script will power off the VM as VMware requires a VM to be powered down when adding an IDE CD ROM. The script will only execute during a Fail Over Live or Move Operation, these values can be changed by editing line 71
   
For an example of the script that is not a Post Recovery script and can be run after the Zerto operations complete please reference the script example Restore-CDROM-VMware.PS1

# Prerequisites 
This script is required to be run as Administrator 

# Environment Requirements (Recovery ZVM if run as Post Recovery Script)
  - PowerShell 5.0+
  - PowerCLI 6.0+
  - VPG Post Recovery command to run setting
  - VPG Post Recovery Params setting
  - ZVM Service account with permisions to execute script

  In Script Variables
  - vCenter IP / Hostname
  - vCenter User / Pass
  - Logging Directory 
  - VM Import CSV 
  - Output File location

# Running Script 
Once the necessary configuration requirements have been completed the script will run automatically on the recovery ZVM during a Fail Over Test, Fail Over Live, or Move Operation for the VMs determined in the import CSV file
