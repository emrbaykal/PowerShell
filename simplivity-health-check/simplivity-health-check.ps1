####################################################################
#                  HPE Simplivity Health Check                     #
####################################################################

<#
.Synopsis
    This Script perform Health Checks to the simplivity servers.

.DESCRIPTION
    This Script perform Health Checks to the simplivity servers.
	
.EXAMPLE
    PS C:\Simplivity-Health-Check\> Set-ExecutionPolicy Unrestricted 

    PS C:\Simplivity-Health-Check\> . .\simplivity-health-check.ps1
	
	1- SVT Cluster State Check:
	 
	   PS C:\Simplivity-Health-Check\> Get-SVT-Cluster
	 
    2- Collect Simplivity Support Dump:
	 
	   PS C:\Simplivity-Health-Check\> Get-SVT-Support-Dump
	   
	3- Upload Report Files To The HPE SFTP Server:
	 
	   PS C:\Simplivity-Health-Check\> Upload-Report-Files
	   
	4- Check Update Manager Host Requirements
	 
	   PS C:\Simplivity-Health-Check\> Get-Update-Manager
	   
.INPUTS
	Customer Name & Surname ,Customer E-Mail, Company Name, VMWare VCenter Server(ip), VCenter Username & Password.   

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 2.2.0.0
    Date    : 20/06/2025
	AUTHOR  : Emre Baykal - HPE Services
#>

# Adjust Powershell Window Size
$pshost = Get-Host              # Get the PowerShell Host.
$pswindow = $pshost.UI.RawUI    # Get the PowerShell Host's UI.

$newsize = $pswindow.BufferSize # Get the UI's current Buffer Size.
$newsize.Width = 214            # Set the new buffer's width to 208 columns.
$newsize.Height = 8000
$pswindow.buffersize = $newsize # Set the new Buffer Size as active.

$newsize = $pswindow.windowsize # Get the UI's current Window Size.
$newsize.Width = 214            # Set the new Window Width to 208 columns.
$newsize.Height = 50
$pswindow.windowsize = $newsize # Set the new Window Size as active.

Clear-Host

Write-Host "#############################################################################################################################"  -ForegroundColor White
Write-Host "#                                   Welcome To HPE Simplivity Health Check PowerCLI                                         #" -ForegroundColor White
Write-Host "#############################################################################################################################`n" -ForegroundColor White

Write-Host "Note: This PowerShell Script Performs Health Checks On HPE SimpliVity Systems To Ensure The System Is Functioning Properly.`n" 

Write-Host "* If you want to perform analysis on SimpliVity Cluster and SVT hosts: Get-SVT-Cluster "  
Write-Host "* If you want to collect support dump on Omnistack Host:               Get-SVT-Support-Dump "
Write-Host "* If you want to upload report files to the HPE SFTP server:           Upload-Report-Files " 
Write-Host "* If you want to check update manager host requirements met:           Get-Update-Manager`n" 

function Load-Modules {
	
	 #Load HPESimpliVity , VMware.VimAutomation.Core, Posh-SSH
	 Write-Host "Checking PowerShell Modules That Should Be loaded... "
	 $InstalledModule = Get-Module -ListAvailable
	 $ModuleNames = $InstalledModule.Name
 
	 if(-not($ModuleNames -like "HPESimpliVity") -or -not($ModuleNames -like "VMware.VimAutomation.Core") -or -not($ModuleNames -like "Posh-SSH"))
	 {
		 Write-Host "Copying Modules to C:\Users\$($Env:UserName)\Documents\WindowsPowerShell\Modules Directory.. " -ForegroundColor Yellow
		 if (-Not (Test-Path "C:\Users\$($Env:UserName)\Documents\WindowsPowerShell\Modules")) {
			 New-Item -ItemType Directory "C:\Users\$($Env:UserName)\Documents\WindowsPowerShell\Modules" | Out-Null
		 }
		 if (Test-Path "$PSScriptRoot\PowerShell-Modules") {
		 try {
			 Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $False -Confirm:$false | Out-Null
		 } catch {
		 try {
			 Import-Module HPESimpliVity -ErrorAction Stop
			 Import-Module VMware.VimAutomation.Core -ErrorAction Stop
			 Import-Module Posh-SSH -ErrorAction Stop
		 } catch {
			 Write-Host "Error loading modules: $_" -ForegroundColor Red
			 break
		 }
			 break
		 }
		 } else {
			 Write-Host "PowerShell-Modules directory not found. Ensure the required modules are available." -ForegroundColor Red
			 break
		 }
		 $capturedErrors | foreach-object { if ($_ -notmatch "already exists") { write-error $_ } }
		 Get-ChildItem -Path "C:\Users\$Env:UserName\Documents\WindowsPowerShell\Modules\*" -Recurse | Unblock-File
        # Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $False -Confirm:$false | Out-Null
		 
		 Write-Host "Loading modules :  HPESimpliVity ,VMware.VimAutomation.Core, Posh-SSH " -ForegroundColor Yellow
		 Import-Module HPESimpliVity, VMware.VimAutomation.Core, Posh-SSH
		 
		 if(($(Get-Module -Name "HPESimpliVity")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "HPESimpliVity module cannot be loaded. Please fix the problem and try again" -ForegroundColor Red
			 Write-Host ""
			 Write-Host "Exit..."
			 break
		 }
 
		 if(($(Get-Module -Name "VMware.VimAutomation.Core")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "VMware.VimAutomation.Core module cannot be loaded. Please fix the problem and try again" -ForegroundColor Red
			 Write-Host ""
			 Write-Host "Exit..."
			 break
		 }
		 
		 if(($(Get-Module -Name "Posh-SSH")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "Posh-SSH module cannot be loaded. Please fix the problem and try again" -ForegroundColor Red
			 Write-Host ""
			 Write-Host "Exit..."
			 break
		 }
		 
	 }
 
	 else
	 {
		 Write-Host "Loading modules :  HPESimpliVity ,VMware.VimAutomation.Core, Posh-SSH " -ForegroundColor Yellow
		 Import-Module HPESimpliVity, VMware.VimAutomation.Core, Posh-SSH
		 
		 $InstalledSimplivityModule  =  Get-Module -Name "HPESimpliVity"
		 $InstalledVmwareModule  =  Get-Module -Name "VMware.VimAutomation.Core"
		 $InstalledPoshSSHModule  =  Get-Module -Name "Posh-SSH"
		 
		 if(($(Get-Module -Name "HPESimpliVity")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "HPESimpliVity module cannot be loaded. Please fix the problem and try again" -ForegroundColor Red
			 Write-Host ""
			 Write-Host "Exit..."
			 break
		 }
 
		 if(($(Get-Module -Name "VMware.VimAutomation.Core")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "VMware.VimAutomation.Core module cannot be loaded. Please fix the problem and try again" -ForegroundColor Red
			 Write-Host ""
			 Write-Host "Exit..."
			 break
		 }
		 
		 if(($(Get-Module -Name "Posh-SSH")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "Posh-SSH module cannot be loaded. Please fix the problem and try again" -ForegroundColor Red
			 Write-Host ""
			 Write-Host "Exit..."
			 break
		 }
		 
		 
		 Write-Host "HPESimpliVity Module Version : $($InstalledSimplivityModule.Version) , VMware Module Version : $($InstalledVmwareModule.Version) , SSH Module Version: $($InstalledPoshSSHModule.Version) installed on your machine." -ForegroundColor Green
		 Write-host ""
	 }
 

}
function Invoke-SVT {
	
	 # Define the path to variable file
	 $InfraVariableFile = "$PSScriptRoot\infra_variable.json"
	 # Define the path to the credential file
	 $credFile = "$PSScriptRoot\cred.XML"
	 #Reports Directory
	 $global:ReportDirPath= "$PSScriptRoot\Reports"
 
	 #Load Required Powershell Modules
	 Load-Modules
 
	 # Check if the credential file already exists
	 if (-Not (Test-Path $InfraVariableFile)) {
		 do {
		 Write-Host "`nPlease fill in the following information about customer..." -ForegroundColor Yellow
		 
		 # Define Customer Name / Enter the name of the person who administers the system.
		 $global:customername  = Read-Host -Prompt 'Customer Name & Surname '
		 
		 # Define Customer Mail / # Define Custome Name / Enter the name of the person who administers the system.
		 $global:customermail  = Read-Host -Prompt 'Customer E-Mail '
		 
		 # Define Company Name / Enter the company's name.
		 $global:companyname  = Read-Host -Prompt 'Company Name '
		 
		 Write-Host "`nPlease fill in the following information about infrastructure..." -ForegroundColor Yellow
		 # Define Vmwre vCenter Server Information
		 $global:vCenterServer  = Read-Host -Prompt 'VMWare VCenter Server(ip) '
 
		 Write-Host "`nCheck the following entries..."
		 Write-Host "Customer Name:                '$global:customername' "
		 Write-Host "Customer E-Mail:              '$global:customermail' "
		 Write-Host "Company Name:                 '$global:companyname' "
		 Write-Host "Vmware Virtual Center Server: '$global:vCenterServer' "
		 
		 # Prompt user for confirmation
		 $confirmation = Read-Host -Prompt "`nDo you confirm the entered information? (Y/N)"
  
		 if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
				 Write-Host "Information confirmed. Proceeding with the script...`n"
				 break  
		 } else {
				 Write-Host "Confirmation not received. Please fill in the information again !!"
		 
		 }
		 } while ($true)
		 
			 # Create a PowerShell custom object with the entered information
			 $jsonData = [PSCustomObject]@{
				 vCenterServer = $global:vCenterServer
				 customername = $global:customername
				 customermail = $global:customermail
				 companyname = $global:companyname
			 }
 
			 # Convert the object to JSON format
			 $jsonString = $jsonData | ConvertTo-Json
			 
			 # Write the JSON data to the file
			 $jsonString | Set-Content -Path $InfraVariableFile
			 
			 Write-Host "Information has been saved to: $InfraVariableFile"
 
	 } else {
		 
			 Write-Host "The Infrastructure Variable file $InfraVariableFile already exists. No action taken..." -ForegroundColor Green
		 
			 # Read the JSON content from the file
			 $jsonInfraContent = Get-Content -Path $InfraVariableFile | Out-String | ConvertFrom-Json 
 
			 # Access the variables from the object
			 $global:vCenterServer = $jsonInfraContent.vCenterServer
			 $global:customername = $jsonInfraContent.customername
			 $global:customermail = $jsonInfraContent.customermail
			 $global:companyname = $jsonInfraContent.companyname
	 }
	  
	 # Check if the credential file already exists
	 if (-Not (Test-Path $credFile)) {
		 # Prompt the user for credentials
		 $global:Cred = Get-Credential -Message 'Enter VMWare VCenter Server Credential' -Username 'administrator@vsphere.local' | Export-Clixml "$PSScriptRoot\cred.XML"
		 Write-Host "Credentials saved to $credFile."
		 
	 } else {
		 Write-Host "The credential file $credFile already exists. No action taken..." -ForegroundColor Green
	 }
 
	 #Import Credential File
	 $global:Cred = Import-CLIXML "$PSScriptRoot\cred.XML"
	 
		 #Check if Reports Directory Exists
	 if(!(Test-Path -Path $global:ReportDirPath))
	 {
		 #powershell create reports directory
		 $directory = New-Item -ItemType Directory -Path $global:ReportDirPath
		 Write-Host "New reports directory $($directory) created successfully..." -f Green
	 }
	 else
	 {
		 Write-Host "Repors directory already exists..." -f Yellow
	 }


 }
 
function Test-Net-Connection($destination)  {
	
	try {
		
		$Global:ProgressPreference = 'SilentlyContinue'
		$portlist = @(
		   "22"
		   "443" 
		   "80"
		)
		
		foreach ($port in $portlist) {
				$connection = Test-NetConnection -Port $port -ComputerName $destination -ErrorAction stop -WarningAction Stop
		}

		Write-Host "Message: TCP Port Connection Test Success...`n" -ForegroundColor Green
			
	} catch {
		
		Write-Host "`nMessage: TCP Port Connection Test Failed, Check Firewall or Network Infrastructure !!! `n" -ForegroundColor Red
		Break
			
	}
	
	$Global:ProgressPreference = 'Continue'
	$Error.Clear()
	 
}
 
 function Get-SVT-Cluster {
	 
	 Clear-Host
	 
	 Write-Host "`n#############################################################################################################################"  -ForegroundColor White
     Write-Host "#                                              HPE Simplivity Health Check                                                  #" -ForegroundColor White
     Write-Host "#############################################################################################################################`n" -ForegroundColor White
 
	 # Define Report Date
	 $reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"
 
	 #Log Timestamp
	 $logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }
 
	 ## Authentication & Variables & Installed Modules
	 Invoke-SVT
	 
	 ## Network Port Test
	 Write-Host "`nExecuting TCP Ports Connection Tests (22/TCP, 443/TCP, 80/TCP) To The VMware VCenter..."  -ForegroundColor Yellow
	 Test-Net-Connection $global:vCenterServer
 

			 $ErrorActionPreference = "SilentlyContinue"
			 $WarningPreference ="SilentlyContinue"
 
			 #Login Vmware VCenter
			 try {
 
				 Write-Output "Trying to establish connection to the Vmware Virtual Center Server:"
				 $VMWareVcenter = Connect-VIServer -Server $global:vCenterServer -Protocol https -Credential $global:Cred -Force -ErrorAction Stop
 
				 Write-Host "Connection established to target VCenter $($global:vCenterServer)`n" -ForegroundColor Green
 
			 } catch {
 
				 Write-Host "Connection could not be established to target VCenter $($global:vCenterServer) .`n" -ForegroundColor Red
				 Break
 
			 }
 

			 #Datacenter Variables
			 $datacenter_list = Get-Datacenter -Server $global:vCenterServer
			 $datacentername = @()
			 $datacenterid = 1
			 $DCNameMap = @{}
 
             # Display the names of array members with index numbers
			 Write-Host "     VMware Environment DataCenter List:    " -ForegroundColor Yellow
			 Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 foreach ($datacenter in $datacenter_list) {
				 $datacentername = $datacenter.name
 
				 # Display Datacenter Name 
				 Write-Host "ID: $datacenterid - VMware DataCenter Name: $datacentername" -ForegroundColor Yellow
 

				 $DCNameMap["$datacenterid"] = $datacentername
				 $datacenterid++
			 }
             Write-Host "--------------------------------------------" -ForegroundColor Yellow
 
			 do {
				 # Prompt the user to select Datacenter
				 $selecteddcId = $(Write-Host "Select DataCenter by ID [1,2,3,..]: " -NoNewline -ForegroundColor White; Read-Host -ErrorAction SilentlyContinue)
				 $selecteddcname = $DCNameMap[$selecteddcId]
 

				 if ($selecteddcname) {
					 Write-Host "Selected DataCenter Name: $selecteddcname`n" -ForegroundColor Green
					 break 
				 } else {
					 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
				 }
			 } while ($true)
 
              
             #Cluster Variables
			 $cluster_list = Get-Cluster -Server $global:vCenterServer -Location $selecteddcname
			 $clustername = @()
			 $clusterid = 1
			 $CLSNameMap = @{}
 
			 # Display the names of datacenter members with index numbers
			 Write-Host "      VMware Environment Cluster List:      " -ForegroundColor Yellow
			 Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 foreach ($cluster in $cluster_list) {
				 $clustername = $cluster.name
 
				 # Display Cluster Name 
				 Write-Host "ID: $clusterid - VMware Cluster Name: $clustername" -ForegroundColor Yellow
 
				 # Map the ID to the IP address and add it to the array
				 $CLSNameMap["$clusterid"] = $clustername
				 $clusterid++
			 }
             Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 do {
				 # Prompt the user to select Cluster
				 $selectedclsId = $(Write-Host "Select Cluster by ID [1,2,3,..]: " -NoNewline -ForegroundColor White; Read-Host -ErrorAction SilentlyContinue)
				 $selectedclsname = $CLSNameMap[$selectedclsId]
 
				 # Validate and assign the selected IP address
				 if ($selectedclsname) {
					 Write-Host "Selected Cluster Name: $selectedclsname`n" -ForegroundColor Green
					 break 
				 } else {
					 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
				 }
			 } while ($true)
 
			 #Connect to the SimpliVity cluster
			 $ovcvms = Get-VM -Location $selectedclsname | Where-Object { $_.Name -like "OmniStackVC*" }
			 $OvcIpAddresses = @()
			 $ovcid = 1
			 $ovcIpMap = @{}
 
			 # Display the names of array members with index numbers
			 Write-Host "     Omnistack Virtual Controller List:     " -ForegroundColor Yellow
			 Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 foreach ($ovcvm in $ovcvms) {
				 $ovc = Get-VMGuest -VM $ovcvm
				 $ovcvmName = $ovcvm
				 $ovchostname = $ovc.HostName
				 $OvcIpAddress = $ovc.IPAddress | Select-Object -First 1
 
				 # Display VM Name and IP Address
				 Write-Host "ID: $ovcid - OVC VM Name: $ovcvmName - Management IP Address: $($OvcIpAddress)" -ForegroundColor Yellow
 
				 # Map the ID to the IP address and add it to the array
				 $ovcIpMap["$ovcid"] = $OvcIpAddress
				 $ovcid++
			 }
             Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 
			 if ($ovcid -ge 2 )
			 {
				 do {
					 # Prompt the user to select an IP address
					 $selectedovcId = $(Write-Host "Select an OVC IP Address by ID: [1,2,3,..]: " -NoNewline -ForegroundColor White; Read-Host -ErrorAction SilentlyContinue)
					 $selectedovcIpAddress = $ovcIpMap[$selectedovcId]
 
					 # Validate and assign the selected IP address
					 if ($selectedovcIpAddress) {
						 Write-Host "Selected OVC IP Address: $selectedovcIpAddress`n" -ForegroundColor Green
						 break 
					 } else {
						 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
					 }
 
				 } while ($true)
				 
                ## Network Port Test
	            Write-Host "Executing TCP Ports Connection Tests (22/TCP, 443/TCP, 80/TCP) To The Omnistack Virtual Controller: $($selectedovcIpAddress) ..."  -ForegroundColor Yellow
	            Test-Net-Connection $selectedovcIpAddress
 
				 try {
					 # Attempt to access OVC IP address in the array
					 Write-Host "Trying to establish connection to the Omnistack Virtual Controller: $($selectedovcIpAddress)" -ForegroundColor Yellow
					 $svt_connection = Connect-Svt -ovc $selectedovcIpAddress -Credential $global:Cred -ErrorAction Stop
 
					 Write-Host "Connection established to target OVC Host - $($selectedovcIpAddress) `n" -ForegroundColor Green
				 } catch {
 
					 Write-Host "Connection could not be established to target OVC Host !!!`n" -ForegroundColor Red
					 Break
				 }
				 
				 try {
					 # Attempt to access each OVC IP address using SSH 
					 Write-Host "Trying to establish connection to the Omnistack Virtual Controller Via SSH: $($selectedovcIpAddress)" -ForegroundColor Yellow
					 $OVCSSHConnection = New-SSHSession -ComputerName $selectedovcIpAddress -port 22 -Credential $Cred -AcceptKey -ErrorAction Stop
					 Write-Host "SSH Connection established to target OVC Host - $($selectedovcIpAddress) `n" -ForegroundColor Green
					 $SSHOVCSession = Get-SSHSession | Where-Object { $_.Host -like "$($selectedovcIpAddress)" } | Select-Object SessionId
					 
				 } catch {
 
					 Write-Host "SSH Connection could not be established to target OVC Host !!!`n" -ForegroundColor Red
					 Break
				 }
 
			 } else {
				 Write-Host "Message: Can Not Get OVC Informations Rleated Cluster, Re-Run Script Then Select Another Cluster !!! `n" -ForegroundColor Red
				 Break
			 }
		
			 # Get SVT Cluster Status
			 $clusterstate = Get-SvtCluster -ClusterName $selectedclsname -Raw | ConvertFrom-Json 
			 $upgradestate = $null
			 $memberscount = $null
			 $arbiterconfigured = $null
			 $arbiterconnected = $null
			 $storagefreestate = $null
			 $vmclsstate = $null
			 $shutdownstatecheck = $null
			 $vmhastate = $null
			 $CLSReportFile = "$($global:ReportDirPath)\$($clusterstate.omnistack_clusters[0].name)-$($logtimestamp).log"
 
			 # Start a transcript log For Cluster State
			 Start-Transcript -Path $CLSReportFile 
					 		 
			 Write-Host "`n#############################################################################################################################" -ForegroundColor Yellow
			 Write-Host "#                                    HPE Simplivity Cluster Health Check Report                                             #" -ForegroundColor Yellow
			 Write-Host "#############################################################################################################################`n" -ForegroundColor Yellow
 
			 Write-Host "`nReport Creation Date: $($reportdate)" 
			 Write-Host "Customer Name:        $($global:customername)" 	
			 Write-Host "Customer E-Mail:      $($global:customermail)" 
			 Write-Host "Company Name:         $($global:companyname)`n" 

			 Write-Host "`n### VMWare Virtual Center  ###" -ForegroundColor White
			 Write-Host "`nvCenter Server Name:             $($VMWareVcenter.Name)"
			 Write-Host "vCenter Server Version:          $($VMWareVcenter.Version)"
			 Write-Host "vCenter Server Build Number:     $($VMWareVcenter.Build)"
			 
			 Write-Host "`n### SVT Cluster State ###" -ForegroundColor White
			 
			 # Get VMWare Cluster State
			 $vmwarecluster = Get-Cluster -Name $clusterstate.omnistack_clusters[0].name
			 # Get Vmware Cluster Avarage CPU Usage Realtime
			 $clustercpuusage = $vmwarecluster  | Get-Stat -Stat "cpu.usage.average" -Realtime | Measure-Object -Property Value -Average
			 # Get VMWare Cluster Avarage Memory Usage Realtime
			 $clustermemusage = $vmwarecluster | Get-Stat -Stat "mem.usage.average" -Realtime | Measure-Object -Property Value -Average  
			 
			 Write-Host "`nDatacenter Name:                  $($clusterstate.omnistack_clusters[0].hypervisor_object_parent_name)"
			 Write-Host "Cluster Name:                     $($clusterstate.omnistack_clusters[0].name)"
			 Write-Host "Hypervisor Type:                  $($clusterstate.omnistack_clusters[0].hypervisor_type)"
			 Write-Host "Management System:                $($clusterstate.omnistack_clusters[0].hypervisor_management_system_name)"	
			 
			 if ($clusterstate.omnistack_clusters[0].members.Count -lt 16) {
					 Write-Host "SVT Cluster Members Count:        $($clusterstate.omnistack_clusters[0].members.Count)"
			 
			 } else {
					 Write-Host "SVT  Cluster Members Count:        $($clusterstate.omnistack_clusters[0].members.Count)" -ForegroundColor Red
					 $memberscount = 1
			 }
			 Write-Host "SVT Current Running Version:      $($clusterstate.omnistack_clusters[0].version)"
			 if ($clusterstate.omnistack_clusters[0].upgrade_state -eq 'SUCCESS_COMMITTED') {
					 Write-Host "SVT Cluster Ver. Upgrade State:   $($clusterstate.omnistack_clusters[0].upgrade_state)"
			 
			 } else {
					 Write-Host "SVT Cluster Ver. Upgrade State:   $($clusterstate.omnistack_clusters[0].upgrade_state)" -ForegroundColor Red
					 $upgradestate = 1
			 }				 
			 Write-Host "SVT Time Zone:                    $($clusterstate.omnistack_clusters[0].time_zone)"
			 if ($vmwarecluster.ExtensionData.Summary.OverallStatus -eq 'green') {
				 Write-Host "VMWare CLs State:                 HEALTHY"
			 }else {
				 Write-Host "VMWare CLs State:                 WARRING" -ForegroundColor yellow
				 $vmclsstate = 1
			 }
             if ($vmwarecluster.HAEnabled -eq 'True') {
				 Write-Host "VMWare CLs HA State:              Turned ON"
			 }else {
				 Write-Host "VMWare CLs HA State:              Turned OFF" -ForegroundColor Red
				 $vmhastate = 1
			 }             
			 if ($vmwarecluster.DrsEnabled -eq 'True') {
				 Write-Host "VMWare CLs DRS State:             Turned ON"
				 Write-Host "VMWare CLs DRS Automation State:  $($vmwarecluster.DrsAutomationLevel)"
			 }else {
				 Write-Host "VMWare CLS DRS State:             Turned OFF" -ForegroundColor yellow
			 }			 
			 Write-Host "VMWare CLs Num Hosts:             $($vmwarecluster.ExtensionData.Summary.NumHosts)"
			 if ($clustercpuusage.Average -gt 80) {
			     Write-Host "VMWare CLs Average CPU Usage:     $($clustercpuusage.Average.ToString("F2")) % (Last 24 Hours)" -ForegroundColor Yellow
			 } else {
                 Write-Host "VMWare CLs Average CPU Usage:     $($clustercpuusage.Average.ToString("F2")) % (Last 24 Hours)"
             }
              if ($clustermemusage.Average -gt 80) {			 
			     Write-Host "VMWare CLs Average Memory Usage:  $($clustermemusage.Average.ToString("F2")) % (Last 24 Hours)" -ForegroundColor Yellow
			 } else {
				  Write-Host "VMWare CLs Average Memory Usage:  $($clustermemusage.Average.ToString("F2")) % (Last 24 Hours)"
			 }
			 Write-Host "VMWare CLs Total VM:              $($vmwarecluster.ExtensionData.Summary.UsageSummary.TotalVmCount)"
			 Write-Host "VMWare CLs PoweredOff VM:         $($vmwarecluster.ExtensionData.Summary.UsageSummary.PoweredOffVmCount)"
			 
			 $pysical_space = $($clusterstate.omnistack_clusters[0].allocated_capacity / 1TB).ToString("F2")
			 $used_space = $($clusterstate.omnistack_clusters[0].used_capacity / 1TB).ToString("F2")
			 $free_space = $($clusterstate.omnistack_clusters[0].free_space / 1TB).ToString("F2")
			 $local_backup_space = $($clusterstate.omnistack_clusters[0].local_backup_capacity / 1TB).ToString("F2")
			 $percentFree = $(($clusterstate.omnistack_clusters[0].free_space / $clusterstate.omnistack_clusters[0].allocated_capacity) * 100).ToString("F2")	
			 $efficiency_ratio = $($clusterstate.omnistack_clusters[0].efficiency_ratio) 
 
			 
			 Write-Host "`n### SVT Cluster Storage State ###" -ForegroundColor White
			 Write-Host "`nHPE Simplivity Efficiency Ratio:   $efficiency_ratio" 
			 Write-Host "Pysical Space:                     $pysical_space TiB" 
			 Write-Host "Used Space:                        $used_space TiB"
			 Write-Host "Free Space:                        $free_space TiB"
			 if ($percentFree -ge 20) {
				 Write-Host "Percentage Free Capacity:          $percentFree %"
			 }else {
				 Write-Host "Percentage Free Capacity:          $percentFree %" -ForegroundColor Red
				 $storagefreestate = 1
			 }
			 Write-Host "Local Backup Capacity:             $local_backup_space TiB"
			 
			 # Get SVT Host Status 
			 $hostlist = Get-Cluster -Name $clusterstate.omnistack_clusters[0].name | Get-VMHost
			 # Create a table to display svt host information
			 $HostTable = @()
			 foreach ($HostDetail in $hostlist) {
					 $EsxiPercentCpu = $(($HostDetail.CpuUsageMhz / $HostDetail.CpuTotalMhz ) * 100).ToString("F0")
					 $EsxiPercentMem = $(($HostDetail.MemoryUsageGB / $HostDetail.MemoryTotalGB ) * 100).ToString("F0")
					 $EsxiTotalMem = $HostDetail.MemoryTotalGB.ToString("F2")
					 			 
					 $HostInfo = New-Object PSObject -Property @{
							 'Name' = $HostDetail.ExtensionData.Name
							 'ConnectionState' = $HostDetail.ConnectionState
							 'PowerState' = $HostDetail.PowerState
							 'OverallStatus' = $HostDetail.ExtensionData.Summary.OverallStatus
							 'RebootRequired' = $HostDetail.ExtensionData.Summary.RebootRequired
							 'NumCpu' = $HostDetail.NumCpu
							 'CpuUsage %' = $EsxiPercentCpu
							 'TotalMem(GB)' = $EsxiTotalMem
							 'MemoryUsage %' = $EsxiPercentMem
							 'Version' = $HostDetail.Version
					 }
					 $HostTable += $HostInfo
			 }
			 # Display Detail of SVT Host to the table
			 Write-Host "`n### Simplivity (ESXI) Hosts List ###" -ForegroundColor White
			 $HostTable | Sort -Property 'CpuUsage %', 'MemoryUsage %' | Format-Table -Property 'Name', 'ConnectionState', 'PowerState', 'OverallStatus', 'RebootRequired', 'NumCpu', 'CpuUsage %', 'TotalMem(GB)', 'MemoryUsage %', 'Version' | Format-Table -AutoSize
			 
			 ## SVT Host Alarms
             $VMHAlarmReport = @()
             $VMHostStatus = (Get-VMHost -Location $selectedclsname  | Get-View) | Select-Object Name,OverallStatus,ConfigStatus,TriggeredAlarmState
             $HostErrors= $VMHostStatus  | Where-Object {$_.OverallStatus -ne "Green" -and $_.TriggeredAlarmState -ne $null} 

             if ($HostErrors){
	             foreach ($HostError in $HostErrors){
		              foreach($alarm in $HostError.TriggeredAlarmState){
			              $Hprops = @{
			              'Simplivity Host (ESXI)' = $HostError.Name
			              'Over All Status' = $HostError.OverallStatus
			              'Triggered Alarms' = (Get-AlarmDefinition -Id $alarm.alarm).Name
			               }
			             [array]$VMHAlarmReport += New-Object PSObject -Property $Hprops
		              }
	            }
	        }

			 Write-Host "### Simplivity Hosts (ESXI) Active Alarms ###" -ForegroundColor White
             if ($VMHAlarmReport){
                  $VMHAlarmReport | Format-Table -Property 'Simplivity Host (ESXI)', 'Over All Status', 'Triggered Alarms'
             }else{
                  Write-Host "`nNo Active Alert Found On SVT (ESXI) Hosts..." 
		     }
			
			 ## VMware Vcenter Events
             $VCAlertsTable = @()
			 $VCEventDate = (Get-Date).AddDays(-1)
             $start = (Get-Date).AddHours(-24)
             $VCAlerts = Get-VIEvent -Start $start -MaxSamples ([int]::MaxValue) | Where-Object {$_ -is [VMware.Vim.AlarmStatusChangedEvent] -and ($_.To -match "red|yellow") -and ($_.FullFormattedMessage -notlike "*Virtual machine*")` -and ($_.CreatedTime -gt $VCEventDate)}

             if ($VCAlerts) {
				 
				 foreach ($VCAlertsDetail in $VCAlerts) {
					 $VCAlertsInfo = New-Object PSObject -Property @{
							 'VMWare vCenter Events' = $VCAlertsDetail.FullFormattedMessage
							 'Alert Created Time' = $VCAlertsDetail.CreatedTime
					}		 
					 $VCAlertsTable += $VCAlertsInfo
				} 
				
				 # Display Detail of SVT Host to the table
			     Write-Host "`n### VMWare vCenter Critical Events For The Last 24 Hours ###" -ForegroundColor White
			     $VCAlertsTable | Sort-Object -Property 'Alert Created Time' -Descending | Format-Table -Property 'VMWare vCenter Events', 'Alert Created Time' | Format-Table -AutoSize
			 
			  }else {
				Write-Host "`nNo Critical Alert Found in the Last 24 Hours...  `n" -ForegroundColor Green  
              }	
			  
			 Write-Host "`n### SVT Cluster Arbiter State ###" -ForegroundColor White
			 Write-Host "`nRequired Arbiter:   $($clusterstate.omnistack_clusters[0].arbiter_required)"
			 
			 if ($clusterstate.omnistack_clusters[0].arbiter_required -eq 'true') {
				 if ($clusterstate.omnistack_clusters[0].arbiter_configured -eq 'true') {
						 Write-Host "Arbiter Configured:   $($clusterstate.omnistack_clusters[0].arbiter_configured)"
						 
						 if ($clusterstate.omnistack_clusters[0].arbiter_connected -eq 'true') {
								 Write-Host "Arbiter Conected:   $($clusterstate.omnistack_clusters[0].arbiter_connected)"
								 Write-Host "Arbiter Address:   $($clusterstate.omnistack_clusters[0].arbiter_address)"
							 }else {
								 Write-Host "Arbiter Conected:   $($clusterstate.omnistack_clusters[0].arbiter_connected)" -ForegroundColor Red
								 $arbiterconnected = 1 
							 }
	             
				 } else {
						 Write-Host "Arbiter Configured  :   $($clusterstate.omnistack_clusters[0].arbiter_configured)" -ForegroundColor Red
						 $arbiterconfigured = 1
				 }
				 
			 }
			  
             # Shows Datacenter has Intelligent Workload Optimizer enabled or disabled ?
			 Write-Host "`n### Intelligent Workload Optimizer State ###`n" -ForegroundColor White
			 $SvtIntWorkCmd = "source /var/tmp/build/bin/appsetup; /var/tmp/build/cli/svt-iwo-show --datacenter $($selecteddcname) --cluster $($selectedclsname)"
			 $SvtIntWork = Invoke-SSHcommand -SessionId $SSHOVCSession.SessionID -Command $SvtIntWorkCmd  -TimeOut 60
			 $SvtIntWork.Output  
			 
			 # Get SVT Datastore Status
			 Write-Host "`n### Simplivity Datastore List ###" -ForegroundColor White
			 $DSDetailList = Get-SvtDatastore | Where-Object  ClusterName -eq $clusterstate.omnistack_clusters[0].name |  Select-Object DatastoreName, SizeGB, SingleReplica, ClusterName, Deleted, PolicyName
			 $DatastoreTable = @()
 
			 foreach ($DSDetail in $DSDetailList) {
				 $dsInfo = New-Object PSObject -Property @{
					 'Datastore Name' = $DSDetail.DatastoreName
					 'Size GB' = $DSDetail.SizeGB
					 'Cluster Name' = $DSDetail.ClusterName
					 'Single Replica' = $DSDetail.SingleReplica
					 'Deleted' = $DSDetail.Deleted
					 'Backup Policy Name' = $DSDetail.PolicyName
				 }
				 $DatastoreTable += $dsInfo
			 }
			 # Display Detail of Datastore to the table
			 $DatastoreTable | Format-Table -Property 'Datastore Name', 'Size GB', 'Cluster Name', 'Single Replica', 'Deleted', 'Backup Policy Name'
 	  

			 # Get Virtual Machine States
			 Write-Host "`n### The Information Of Driven Virtual Machines ###" -ForegroundColor White
			 $VMDetailList = Get-SvtVM -ClusterName $clusterstate.omnistack_clusters[0].name 
			 # Create a table to display virtual machine information
			 $VMTable = @()
 
			 foreach ($VMDetail in $VMDetailList) {
				 
				 $VMBackup = Get-SvtBackup -DestinationName $clusterstate.omnistack_clusters[0].name -VmName $VMDetail.VmName -All -ErrorAction SilentlyContinue
				 
				 if ($VMBackup) {
					 $BackupSize = (($VMBackup | Measure-Object -Property SizeGB -Sum).Sum).ToString("F2")
				     $NumOfBackup =  $VMBackup.BackupName.count
				 } else {
					 $BackupSize = 0
					 $NumOfBackup = 0
			     } 

				 $VMState = Get-VM -name $VMDetail.VmName -ErrorAction SilentlyContinue
				 
                 if ($VMState) {
					 $NumCPU = $VMState.NumCpu
				     $MEM =  $VMState.MemoryGB
					 $ProvisionedSpace = $VMState.ProvisionedSpaceGB.ToString("F2")
					 $UsedSpace = $VMState.UsedSpaceGB.ToString("F2")
					 
				 } else {
					 $NumCPU = 0
				     $MEM =  0
					 $ProvisionedSpace = 0
					 $UsedSpace = 0
			     } 				 
				 
				 $vmInfo = New-Object PSObject -Property @{
					 'VM Name      ' = $VMDetail.VmName
					 'Power State' = $VMDetail.VmPowerState
					 'Num CPU' = $NumCPU
					 'Mem GB' = $MEM
					 'Provisioned Space(GB)' = $ProvisionedSpace
					 'Used Space(GB)' = $UsedSpace
					 'SVT HA Status ' = $VMDetail.HAstatus
					 'SVT Datastore Name' = $VMDetail.DatastoreName
					 'SVT Backup Policy Name   ' = $VMDetail.PolicyName
					 'Local Bckp(GB)' = $BackupSize
					 'Num Of Bckp'   =  $NumOfBackup
					 'VM Host          ' = $VMDetail.HostName
				 }
				 $VMTable += $vmInfo
				 $NumOfBackup = 0
			 }
			 # Display Detail of VM to the table
			 $VMTable | Sort -Property 'VM Host          ', 'Local Bckp(GB)' | Format-Table -Property 'VM Name      ', 'Power State', 'Num CPU', 'Mem GB', 'Provisioned Space(GB)', 'Used Space(GB)','SVT Datastore Name', 'SVT Backup Policy Name   ', 'Local Bckp(GB)', 'Num Of Bckp', 'VM Host          '
			      			 
			 ## Active VM Alarms
             $VMAlarmReport = @()
             $VMStatus = (Get-VM | Get-View) | Select-Object Name,OverallStatus,ConfigStatus,TriggeredAlarmState
             $VMErrors = $VMStatus  | Where-Object {$_.OverallStatus -ne "Green"}

             if ($VMErrors) {
                  foreach ($VMError in $VMErrors){
                      foreach ($TriggeredAlarm in $VMError.TriggeredAlarmstate) {
                            $VMprops = @{
                              'Virtual Machine Name' = $VMError.Name
                              'Over All Status' = $VMError.OverallStatus
                              'Triggered Alarms' = (Get-AlarmDefinition -Id $TriggeredAlarm.Alarm).Name
                            }
                        [array]$VMAlarms += New-Object PSObject -Property $VMprops
                      }
                 }
            }

		    Write-Host "### Virtual Machine Active Alarms ###" -ForegroundColor White
            if ($VMAlarms){
	             $VMAlarms | Format-Table -Property 'Virtual Machine Name', 'Over All Status', 'Triggered Alarms'
            }else{
	             Write-Host "`nNo Active Alerts Found On Virtual Machines... "
            }   

            # Snapshot Report
			$snapshotdays = "3"
            $Snapshotdate = (Get-Date).AddDays(-$snapshotdays)
            $VMSnapshotReport = @()
            $SnapshotCmd  = Get-Cluster -Name $clusterstate.omnistack_clusters[0].name | Get-VM | get-snapshot
            $SnapshotDateReport = $SnapshotCmd | Select-Object vm, name,created,description | Where-Object {$_.created -lt $Snapshotdate}

            if ($SnapshotDateReport){
                foreach ($snapshot in $SnapshotDateReport) {
		             $SnapInfo = New-Object PSObject -Property @{
			            'VM Name' = $snapshot.vm
			            'Snapshot Name' = $snapshot.name
			            'Snapshot Creation Date' = $snapshot.created
			            'Snapshot Description' = $snapshot.description 
		            }
			        $VMSnapshotReport += $SnapInfo
	            }
            }

            Write-Host "`n### Snapshots Older Than $($snapshotdays) Days ###" -ForegroundColor White
            if ($SnapshotDateReport) {
                $VMSnapshotReport | Format-Table -Property 'VM Name', 'Snapshot Name', 'Snapshot Creation Date', 'Snapshot Description'
            }
            else {
                Write-Host "`nNo Snapshots older than $($snapshotdays)" 
            }
			
			 $BackupPolicies  = Get-SvtPolicy -Raw | ConvertFrom-Json
			 # Create an empty array to store the rule data
			 $BackupRulesTable = @()

			 # Iterate over each policy and its rules
			 foreach ($BackupPolicy in $BackupPolicies.policies) {
				foreach ($rule in $BackupPolicy.rules) {
					$BackupRuleData = New-Object PSObject -Property @{
						"Policy Name" = $BackupPolicy.name 
						"Rule Number" = $rule.number  
						"Frequency - Hours" = ( $rule.frequency / 60 ) 
						"Destination" = $rule.destination_name 
						"Backup Days" = $rule.Days 
						"Expiration Time - Day" = ( $rule.retention / 60 ) / 24
						"External Store Name" = $rule.external.store.name 
						
					}
					$BackupRulesTable += $BackupRuleData
				}
			 }
			 
			 Write-Host "`n### Simplivity Backup Policies ###" -ForegroundColor White
			 $BackupRulesTable | Format-Table -Property 'Policy Name', 'Backup Days', 'Rule Number', 'Destination', 'External Store Name', 'Frequency - Hours', 'Expiration Time - Day'

             # Displays information about the backups queued for replication on the backup state machine
			 Write-Host "### Backups Queued For Replication On The Backup State Machine ###`n" -ForegroundColor White
			 $SvtBackupQueueCmd = "source /var/tmp/build/bin/appsetup; /var/tmp/build/dsv/dsv-backup-util --operation state-info"
			 $SvtBackupQueue = Invoke-SSHcommand -SessionId $SSHOVCSession.SessionID -Command $SvtBackupQueueCmd  -TimeOut 60
			 if ($SvtBackupQueue.Output) {
				 $SvtBackupQueue.Output
			 }else {
				 Write-Host "`nSimplivity Backup Queue Is Empty On The Backup State Machine For Replication... `n"
			 }
			 
			 # Display Datacenter Balance State
			 Write-Host "`n### Datacenter Resource Balancing State ###`n" -ForegroundColor White
             $SvtBalanceCmd = "source /var/tmp/build/bin/appsetup; sudo /var/tmp/build/dsv/dsv-balance-show --shownodeip --consumption --showHiveName"	
			 $SvtBalance = Invoke-SSHcommand -SessionId $SSHOVCSession.SessionID -Command $SvtBalanceCmd -TimeOut 60
			 $SvtBalance.Output	
			 
			 # Get Virtual Machine Replica Sets
			 Write-Host "`n### Virtual Machine Replica Sets  ###" -ForegroundColor White
			 $SvtVMReplicaSet = Get-SVTvmReplicaSet -ClusterName $clusterstate.omnistack_clusters[0].name 
			 # Create a table to display virtual machine replicaset information
			 $ReplicaSetTable = @()
 
			 foreach ($ReplicaDetail in $SvtVMReplicaSet) {
				 
				 $VMReplicaState = Get-VM -name $ReplicaDetail.VmName -ErrorAction SilentlyContinue
				 
                 if ($VMReplicaState) {
					 $VMReplicaUsedSpace = $VMReplicaState.UsedSpaceGB.ToString("F2")
					 
				 } else {
					 $VMReplicaUsedSpace = 0
			     } 		
				 
				 $ReplicaInfo = New-Object PSObject -Property @{
					 'VM Name         ' = $ReplicaDetail.VmName
					 'State     ' = $ReplicaDetail.State
					 'SVT HA Status   ' = $ReplicaDetail.HAstatus
					 'Space(GB)' = $VMReplicaUsedSpace
					 'Primary Replica Location   ' = $ReplicaDetail.Primary
					 'Secondary Replica Location ' = $ReplicaDetail.Secondary
				 }
				 $ReplicaSetTable += $ReplicaInfo
			 }
			 # Display Detail of VM ReplicaSet to the table
			 $ReplicaSetTable | Sort -Property 'Primary Replica Location   ' | Format-Table -Property 'VM Name         ', 'State     ', 'SVT HA Status   ', 'Space(GB)', 'Primary Replica Location   ', 'Secondary Replica Location '
			        	
			 Write-Host "`n### SimpliVity Displaced VM List ###" -ForegroundColor White
             foreach ($VMList in $VMDetailList) {
                 $VMReplica = $SvtVMReplicaSet | Where-Object VmName -EQ $VMList.VmName
                 if ($VMList.Hostname -ne $VMReplica.Primary) {
		              $ReplicaState = New-Object PSObject -Property @{
                          'VM Name         '              = $VMList.VmName
                          'VM Running Host            '   = $VMList.HostName
                          'Primary Replica Location   '   = $VMReplica.Primary
                          'Secondary Replica Location '   = $VMReplica.Secondary
                        }    
	                  $ReplicaStateTable += $ReplicaState
	            }
            } 

             if ($ReplicaStateTable) {
                # Display Detail of Displaced VM Status to the table
                $ReplicaStateTable | Format-Table -Property 'VM Name         ', 'VM Running Host            ', 'Primary Replica Location   ', 'Secondary Replica Location '
             }
             else {
                Write-Host "`nNo Virtual Machine Detected Running Outside Of Where Their Primary Storage Is Located...`n" 
             }
			 
			 # Check Degrede VM Replicasets 
			 $vmreplicasetdegreded = $SvtVMReplicaSet | Where-Object  HAStatus -eq  DEGRADED
			 
			 # Display Support State
			 Write-Host "`n### Datacenter Support Reg. State ###`n" -ForegroundColor White
			 $SvtSupportCmd = "source /var/tmp/build/bin/appsetup; /var/tmp/build/cli/svt-support-show"
			 $SvtSupport = Invoke-SSHcommand -SessionId $SSHOVCSession.SessionID -Command $SvtSupportCmd  -TimeOut 60
			 $SvtSupport.Output
				   
             # Remove OVC SSH Sessşon
			 Remove-SSHSession -SessionId $SSHOVCSession.SessionID | Out-Null
 
			 if ($upgradestate -eq $null -and $memberscount -eq $null -and $arbiterconfigured -eq $null -and $arbiterconnected -eq $null -and $storagefreestate -eq $null -and $vmreplicasetdegreded.Count -eq 0 -and $vmclsstate -eq $null -and $vmhastate -eq $null) {
					 Write-Host "`nMessage: The status of the cluster ($($clusterstate.omnistack_clusters[0].name)) is consistent and you can continue to upgrade .... " -ForegroundColor Green
			 } else {
				 
				 Write-Host "`nMessage: SVT cluster ($($clusterstate.omnistack_clusters[0].name)) status is not consistent and should fix error states !!! " -ForegroundColor Red
				 
				 if ($upgradestate) {
				 Write-Host "`nError Message: Update status not in the expected state !!! "  -ForegroundColor Red
				 }
				 if ($memberscount) {
				 Write-Host "`nError Message: Svt cluster ($($clusterstate.omnistack_clusters[0].name)) is comprised of more than 16 HPE OmniStack hosts !!!"  -ForegroundColor Red
				 }
				 if ($arbiterconfigured) {
				 Write-Host "`nError Message: Arbiter host configuration is required. It has not been configured !!!"  -ForegroundColor Red
				 }
				 if ($arbiterconnected) {
				 Write-Host "`nError Message: Arbiter host is configured, but not connected to the SVT cluster !!!"  -ForegroundColor Red
				 }
				 if ($storagefreestate) {
				 Write-Host "`nError Message: Free space is below the value required for upgrading !!!"  -ForegroundColor Red
				 }
				 if ($vmreplicasetdegreded.Count -ne 0) {
				 Write-Host "`nError Message: Some Of virtual machines HA NOT COMPLIANT !!!"  -ForegroundColor Red
				 }
				 if ($vmclsstate) {
				 Write-Host "`nError Message: There are some errors or warnings in the cluster, check cluster state !!!"  -ForegroundColor yellow
				 }
				 if ($vmhastate) {
				 Write-Host "`nError Message: VMware Cluster High Availability Not Enabled, check cluster status !!!"  -ForegroundColor yellow
				 }
				 
			 }
		  
			 Stop-Transcript
			 
			 Write-Host "`n#############################################################################################################################" -ForegroundColor Yellow
			 Write-Host "#                                      HPE Simplivity Hosts Health Check Report                                             #" -ForegroundColor Yellow
			 Write-Host "#############################################################################################################################`n" -ForegroundColor Yellow
			 
			 $hoststate = Get-SvtHost -ClusterName $clusterstate.omnistack_clusters[0].name -Raw | ConvertFrom-Json 
			 
			 foreach ($svthost in $hoststate.hosts) {
				 $hostconnectivity = $null
				 $hostupgradestate = $null
				 $hostdisktstate = $null
				 $hostversion = $null
				 $hwstate = $null
				 $raidhwstate = $null
				 $raidbatteryhwstate = $null
				 $cpuusage = $null
				 $memusage = $null
				 $shutdownstatecheck = $null
				 # Get ESXI Host Infromation
				 $esxihost = Get-VMHost -Name $svthost.name  | Select-Object -Property NumCpu, CpuTotalMhz, CpuUsageMhz, MemoryTotalGB, MemoryUsageGB, Version, Build 
				 $percentCpu = $(($esxihost.CpuUsageMhz / $esxihost.CpuTotalMhz ) * 100).ToString("F0")
				 $percentMem = $(($esxihost.MemoryUsageGB / $esxihost.MemoryTotalGB ) * 100).ToString("F0")	
                 $NetTestCmd = "source /var/tmp/build/bin/appsetup; /var/tmp/build/cli/svt-network-test --datacenter $($selecteddcname) --cluster $($selectedclsname)"  
				 $ServiceStateCmd = "source /var/tmp/build/bin/appsetup; sudo /var/tmp/build/dsv/dsv-managed-service-show"
				 $cfgdbstateCmd = "source /var/tmp/build/bin/appsetup; sudo /var/tmp/build/dsv/dsv-cfgdb-get-sync-status"
				 $NetStateCmd = "/bin/netstat -win"	
                 $shutdownstateCmd = "source /var/tmp/build/bin/appsetup; sudo /var/tmp/build/dsv/dsv-shutdown-status"				 
				 $HOSTReportFile = "$($global:ReportDirPath)\$($svthost.name)-$($logtimestamp).log"
				 
				Write-Host "`n#### SVT Host: $($svthost.name) ####`n" -ForegroundColor yellow
				
				## Network Port Test
				Write-Host "Executing TCP Ports Connection Tests (22/TCP, 443/TCP, 80/TCP) To The Omnistack Virtual Controller: $($svthost.name) ..."  -ForegroundColor Yellow
	            Test-Net-Connection $svthost.management_ip
				 
				 try {
					 # Attempt to access each OVC IP address using SSH
					 Write-Host "Trying to establish connection to the OVC Host: $($svthost.name)" -ForegroundColor Yellow
					 $SSHOVCConnection = New-SSHSession -ComputerName $svthost.management_ip -port 22 -Credential $Cred -AcceptKey -ErrorAction Stop
					 $OVCSession = Get-SSHSession | Where-Object { $_.Host -like "$($svthost.management_ip)" } | Select-Object SessionId
					 Write-Host "Connection established to target OVC Host - $($svthost.name) `n" -ForegroundColor Green
					 
				 } catch {
 
					 Write-Host "`nSSH Connection could not be established to OVC Host: $($svthost.name)!!!`n" -ForegroundColor Red
					 Break
				 }
 
			     # Start a transcript log for SVT Hosts
			     Start-Transcript -Path $HOSTReportFile

                 Write-Host "`n#### SVT Host Summary: $($svthost.name) ####`n" -ForegroundColor White				 
				 
				 Write-Host "`nSVT Host Name:               $($svthost.name)"
				 Write-Host "SVT Host IP:                 $($svthost.hypervisor_management_system)"
				 if ($svthost.state -eq 'ALIVE') {
					 Write-Host "SVT Host State:              $($svthost.state)" 
				 }else {
					 Write-Host "SVT Host State:              $($svthost.state)" -ForegroundColor Red
					 $hostconnectivity = 1
				 }   
				 Write-Host "SVT Host Model:              $($svthost.model)"
				 if ($svthost.version -eq $clusterstate.omnistack_clusters[0].version) {
					 Write-Host "SVT Host Version:            $($svthost.version)"
				 }else {
					 Write-Host "SVT Host Version:            $($svthost.version)" -ForegroundColor Red
					 $hostversion = 1
				 }
				 if ($svthost.upgrade_state -eq 'SUCCESS') {
					 Write-Host "SVT Upgrade State:           $($svthost.upgrade_state)"
				 }else {
					 Write-Host "SVT Upgrade State:           $($svthost.upgrade_state)" -ForegroundColor Red
					 $hostupgradestate = 1
				 }
				 # Check Host Shutdown State
				 $shutdownstate = Invoke-SSHcommand -SessionId $OVCSession.SessionID -Command $shutdownstateCmd -TimeOut 60
                 if ($shutdownstate.Output -match "task\s*is\s*not\s*running\s*") {
                     Write-Host "SVT Shutdown State:          The host is not in shutdown state" 
                } else {
                    Write-Host "SVT Shutdown State:           The host is in shutdown state duty" -ForegroundColor Red
					$shutdownstatecheck = 1
                }
				 Write-Host "SVT Host ESXI Image Version: $($esxihost.Version)"
				 Write-Host "SVT Host ESXI Build:         $($esxihost.Build)"
				 Write-Host "SVT Host CPU Total MHz:      $($esxihost.CpuTotalMhz)"
				 if ($percentCpu -le 85) {
					 Write-Host "SVT Host CPU Usage :         $percentCpu %"
				 }else {
					 Write-Host "SVT Host CPU Usage :         $percentCpu %" -ForegroundColor yellow
					 $cpuusage = 1
				 }
				 Write-Host "SVT Host Memory GB:          $($esxihost.MemoryTotalGB.ToString("F0"))"
				 if ($percentMem -le 85) {
					 Write-Host "SVT Host Memory Usage :      $percentMem %"
				 }else {
					 Write-Host "SVT Host Memory Usage :      $percentMem %" -ForegroundColor yellow
					 $memusage = 1
				 }
				 
				 ## SVT Host Alarms
                 $SVTAlarmReport = @()
                 $SVTHostStatus = (Get-VMHost -Name $svthost.name | Get-View) | Select-Object Name,OverallStatus,ConfigStatus,TriggeredAlarmState
                 $SVTHostErrors= $SVTVMHostStatus  | Where-Object {$_.OverallStatus -ne "Green" -and $_.TriggeredAlarmState -ne $null} 

                if ($SVTHostErrors){
	                foreach ($SVTHostError in $SVTHostErrors){
		                 foreach($svtalarm in $SVTHostError.TriggeredAlarmState){
			                 $SVTHprops = @{
			                 'Simplivity Host (ESXI)' = $SVTHostError.Name
			                 'Over All Status' = $SVTHostError.OverallStatus
			                 'Triggered Alarms' = (Get-AlarmDefinition -Id $svtalarm.alarm).Name
			                 }
			                 [array]$SVTAlarmReport += New-Object PSObject -Property $SVTHprops
		                 }
	                }
	             }

			     Write-Host "`n# SVT Host - $($svthost.name) Active Alarms #" -ForegroundColor White
                 if ($SVTAlarmReport){
                      $SVTAlarmReport | Format-Table -Property 'Simplivity Host (ESXI)', 'Over All Status', 'Triggered Alarms'
                 }else{
                      Write-Host "`nNo Active Alert Found On $($svthost.name)..." 
		         }
				 
				 Write-Host "`n# SVT Host - $($svthost.name) Hardware State  #" -ForegroundColor White
				 $hosthwinfo = Get-SvtHardware -Hostname $svthost.name -Raw | ConvertFrom-Json 
				 
				 Write-Host "`nModel Number:                $($hosthwinfo.host.model_number)"
				 Write-Host "Serial Number:               $($hosthwinfo.host.serial_number)"
				 Write-Host "Firmware Revision:           $($hosthwinfo.host.firmware_revision)"
				 if ($hosthwinfo.host.status -eq 'GREEN') {
					 Write-Host "Hardware Status:             HEALTHY"
				 }else {
					 Write-Host "Hardware Status:             FAULTY" -ForegroundColor Red
					 $hwstate = 1
				 }
				 Write-Host "Raid Card Product Name:      $($hosthwinfo.host.raid_card.product_name)"
				 Write-Host "Raid Card Firmware Revision: $($hosthwinfo.host.raid_card.firmware_revision)" 
				 if ($($hosthwinfo.host.status) -eq 'GREEN') {
					 Write-Host "Raid Card Status:            HEALTHY"
				 }else {
					 Write-Host "Raid Card Status:            FAULTY" -ForegroundColor Red
					 $raidhwstate = 1
				 }
				 if ($($hosthwinfo.host.status) -eq 'GREEN') {
					 Write-Host "Raid Card Battery Status:    HEALTHY"
				 }else {
					 Write-Host "Raid Card Battery Status:    FAULTY" -ForegroundColor Red
					 $raidbatteryhwstate = 1
				 }
				 
				 
				 Write-Host "`n# SVT Host - $($svthost.name) Disk State #" -ForegroundColor White
				 $hostdisktstate = Get-SvtDisk -Hostname $svthost.name | Where-Object Health -ne HEALTHY
				 $hostdiskinfo = Get-SvtDisk -Hostname $svthost.name | Select-Object SerialNumber, Manufacturer, ModelNumber, Health, RemainingLife, CapacityTB, Slot
				 $diskTable = $hostdiskinfo | ForEach-Object {
					 [PSCustomObject]@{
						 SerialNumber = $_.SerialNumber
						 Manufacturer = $_.Manufacturer
						 ModelNumber = $_.ModelNumber
						 Health = $_.Health
						 RemainingLife = $_.RemainingLife
						 CapacityTB = $_.CapacityTB
						 Slot = $_.Slot
					 }
				 }
				 
				 $diskTable | Format-Table -AutoSize
				 
		
				Write-Host "`n# Omnistack Virutal Controller - $($svthost.virtual_controller_name) Network State #" -ForegroundColor White
				 # Create OVC Host IP Table
				$ovchosttable = $svthost| ForEach-Object {
					 [PSCustomObject]@{
						 'Mgmt IP        ' = $_.management_ip
						 'Mgmt Net Mask  ' = $_.management_mask
						 'Mgmt MTU       ' = $_.management_mtu
						 'Fed IP         ' = $_.federation_ip
						 'Fed Net Mask   ' = $_.federation_mask
						 'Fed MTU        ' = $_.federation_mtu
						 'Str IP         ' = $_.storage_ip
						 'Str Net Mask   ' = $_.storage_mask
						 'Str MTU        ' = $_.storage_mtu
					 }
				 }
				$ovchosttable | Format-Table
					
				# Display Network Interface States
				$NetState = Invoke-SSHcommand -SessionId $OVCSession.SessionID -Command $NetStateCmd -TimeOut 60
				Write-Host "`n# Omnistack Virutal Controller - $($svthost.virtual_controller_name) Network Interface State #`n" -ForegroundColor White
				$NetState.Output
				   
				# Display Network Test Results
				$NetTest = Invoke-SSHcommand -SessionId $OVCSession.SessionID -Command $NetTestCmd -TimeOut 60
				Write-Host "`n# Omnistack Virutal Controller - $($svthost.virtual_controller_name) Network Connectivity Test #`n" -ForegroundColor White
				$NetTest.Output
			
			    # Retrieves the sync status of this HPE OmniStack host from CfgDB.
				$cfgdbstate = Invoke-SSHcommand -SessionId $OVCSession.SessionID -Command $cfgdbstateCmd -TimeOut 60
				Write-Host "`n# Omnistack Virutal Controller - $($svthost.virtual_controller_name) CfgDB Sync Status #`n" -ForegroundColor White
				$cfgdbstate.Output
				
				# Display Service States
				$ServiceState = Invoke-SSHcommand -SessionId $OVCSession.SessionID -Command $ServiceStateCmd -TimeOut 60
				Write-Host "`n# Omnistack Virutal Controller - $($svthost.virtual_controller_name) Host Status Of All Managed Services. #`n" -ForegroundColor White
				$ServiceState.Output
				
				## Omnistack Virtual Controller Active Alarms
                $OVCAlarmReport = @()
                $OVCStatus = (Get-VM -Name $svthost.virtual_controller_name | Get-View) | Select-Object Name,OverallStatus,ConfigStatus,TriggeredAlarmState
                $OVCErrors = $VMStatus  | Where-Object {$_.OverallStatus -ne "Green"}

                if ($OVCErrors) {
                      foreach ($OVCError in $OVCErrors){
                          foreach ($OVCTriggeredAlarm in $OVCError.TriggeredAlarmstate) {
                                $OVCprops = @{
                                  'Over All Status' = $OVCError.OverallStatus
								  'Acknowledged' = $OVCTriggeredAlarm.Acknowledged
                                  'Triggered Alarms' = (Get-AlarmDefinition -Id $OVCTriggeredAlarm.Alarm).Name
								  'Triggered Alarm Time' = $OVCTriggeredAlarm.Time
                                }
                            [array]$OVCAlarms += New-Object PSObject -Property $OVCprops
                          }
                     }
                }

                Write-Host "`n# Omnistack Virtual Controller - $($svthost.virtual_controller_name) Active Alarms #" -ForegroundColor White
                if ($OVCAlarms){
	                $OVCAlarms | Format-Table -Property 'Over All Status', 'Acknowledged', 'Triggered Alarms', 'Triggered Alarm Time'
                }else{
	                Write-Host "`nNo Active Alerts Found On Omnistack Virtual Controller...  `n"
                }
				 
				# Remove OVC SSH Sessşon
			    Remove-SSHSession -SessionId $OVCSession.SessionID | Out-Null
		    
				 if ($hostconnectivity -eq $null -and $hostupgradestate -eq $null -and $hostdisktstate -eq $null -and $hostversion -eq $null -and $hwstate -eq $null -and $raidhwstate -eq $null -and $raidbatteryhwstate -eq $null -and $cpuusage -eq $null -and $memusage -eq $null -and $shutdownstatecheck -eq $null) {
						 Write-Host "`nMessage: The status of the SVT Host - ( $($svthost.name) ) is consistent and you can continue to upgrade ....`n" -ForegroundColor Green
				 
				 } else {
					 
					 Write-Host "`nMessage: SVT Host - ( $($svthost.name) status is not consistent and should fix error states !!! `n" -ForegroundColor Red
					 
					 if ($hostconnectivity) {
					 Write-Host "Error Message: SVT Host - ( $($svthost.name) State Not Alive !!!"  -ForegroundColor Red
					 }
					 if ($hostupgradestate) {
					 Write-Host "Error Message: SVT Host - ( $($svthost.name) Update status not in the expected state !!! "  -ForegroundColor Red
					 }
					 if ($hostdisktstate) {
					 Write-Host "Error Message: Detection of faulty discs on the SVT host - ( $($svthost.name) , opening of a support case !!!"  -ForegroundColor Red
					 }
					 if ($hostversion) {
					 Write-Host "Error Message: Incompatible software version actively running on SVT host - ( $($svthost.name)  !!!"  -ForegroundColor Red
					 }
					 if ($hwstate) {
					 Write-Host "Error Message: Detection of faulty hardware component on the SVT host - ( $($svthost.name) , opening of a support case !!!"  -ForegroundColor Red
					 }
					 if ($raidhwstate) {
					 Write-Host "Error Message: Detection of faulty raid card on the SVT host - ( $($svthost.name) , opening of a support case !!!"  -ForegroundColor Red
					 }
					 if ($raidbatteryhwstate) {
					 Write-Host "Error Message: Detection of faulty raid card battery on the SVT host - ( $($svthost.name) , opening of a support case !!!"  -ForegroundColor Red
					 }
					 if ($cpuusage) {
					 Write-Host "Error Message: High CPU usage detected on the SVT host - ( $($svthost.name) !!!"  -ForegroundColor yellow
					 }
					 if ($memusage) {
					 Write-Host "Error Message: High Memory usage detected on the SVT host - ( $($svthost.name) !!!"  -ForegroundColor yellow
					 }
					 if ($shutdownstatecheck) {
	                 Write-Host "`nError Message: SVT Host The host is in SHUTDOWN STATE DUTY !!!"  -ForegroundColor  Red
                 }	
				 }	
 
                 Stop-Transcript
				 Write-Host "`n"
			 }	 
 
      
			 Write-Host "`n#############################################################################################################################" -ForegroundColor Yellow
			 Write-Host "#                                                Capture Balance File                                                       #" -ForegroundColor Yellow
			 Write-Host "#############################################################################################################################`n" -ForegroundColor Yellow
 
			 $sshbalance = "source /var/tmp/build/bin/appsetup; sudo /var/tmp/build/dsv/dsv-balance-manual --datacenter $($selecteddcname) --cluster $($selectedclsname)"
			 $sshmovebalance = 'sudo find /tmp/balance/replica_distribution_file*.csv -maxdepth 1 -type f -exec cp {} /core/capture/  \;'
			 $sshbalancefile = 'sudo find /core/capture/replica_distribution_file*.csv -maxdepth 1 -type f'
 
			  
			 try {
				 # Attempt to access  OVC IP addres 
				 Write-Host "Try to establish target OVC Host - $($selectedovcIpAddress)" -ForegroundColor Yellow  
				 $SSHCaptureCon = New-SSHSession -ComputerName $selectedovcIpAddress -port 22 -Credential $global:Cred -ErrorAction Stop
				 Write-Host "Connection established to target OVC Host - $($selectedovcIpAddress) `n" -ForegroundColor Green
			 } catch {
			 
				 Write-Host "Connection could not be established to target OVC Host - $($selectedovcIpAddress) !!!`n" -ForegroundColor Red
				 Break
			 }
			 
			 # Get SSH Session
			 $CaptureSession = Get-SSHSession | Where-Object { $_.Host -like "$($selectedovcIpAddress)" } | Select-Object SessionId
 
			 try {
				 # Capture Balance Report
				 Write-Host "Running capture balance report command on target virtual controller..."
				 $null = Invoke-SSHcommand -SessionId $CaptureSession.SessionId -Command $sshbalance -TimeOut 60  -ErrorAction Stop
			 
				 # Move Balance Report to /core/capture directory
				 Write-Host "Move Balance Report to /core/capture directory... `n"
				 $null = Invoke-SSHcommand -SessionId $CaptureSession.SessionId -Command $sshmovebalance -TimeOut 10 -ErrorAction Stop
			 
			 } catch {
			 
				 Write-Host "Capture balance report can not create on target virtual controller... !!!`n" -ForegroundColor Red
				 Break
			 }
			 
			 try {
			 
				 $balancefile = Invoke-SSHcommand -SessionId $CaptureSession.SessionId -Command $sshbalancefile | Select-Object -ExpandProperty Output 
				 $CaptureBalanceFile = ($balancefile | Select-Object -last 1).Split('/')[-1]
			 
				 Start-Sleep 2
				 $CaptureBalanceWeb = "http://$selectedovcIpAddress/capture/$CaptureBalanceFile"
				 Write-Host "Downloading the Balance Report file: $CaptureBalanceWeb ..." -ForegroundColor Green
				 Invoke-WebRequest -Uri $CaptureBalanceWeb -OutFile "$global:ReportDirPath\$CaptureBalanceFile"
			 
				 # Delete Balance Report File
				 $null = Invoke-SSHcommand -SessionId $CaptureSession.SessionId -Command "sudo rm -f  $balancefile" -TimeOut 10 -ErrorAction Stop
				  
				 # Disconnect SSH Session
				 Remove-SSHSession -SessionId $CaptureSession.SessionID | Out-Null
 
				 Write-Host "You Can Find SVT Balance Report Below: $global:ReportDirPath\$CaptureBalanceFile `n" -ForegroundColor yellow
			 
			 } catch {
			 
				 Write-Warning "Could not download the support file from $selectedovcIpAddress : $($_.Exception.Message)"
				 Remove-SSHSession -SessionId $CaptureSession.SessionID | Out-Null
			 
			 }			
 
	 
	 finally
	 {
			
			 Write-Host "Disconnect from vCenter Server..." -ForegroundColor Yellow
			 # Disconnect from vCenter Server
			 Disconnect-VIServer -Server $global:vCenterServer -Force -Confirm:$false
			 
			 Write-Host "Disconnect All SSH Session...`n" -ForegroundColor Yellow
			 # Disconnect ALL SSH Sessşon
			 Get-SSHSession | Remove-SSHSession | Out-Null
 
			 if($Error.Count -ne 0 )
			 {
			 	 Write-Host "Script executed with few errors !!!" -ForegroundColor Red
		         Write-host -f Red "Error:" $Error 
			 }
			 
			 Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
			 
			 # Remove Variables
			 Remove-Variable * -ErrorAction SilentlyContinue; $error.Clear();
	 }
	 
 ### End Function
 }
 
 function Get-SVT-Support-Dump {
	 
	Clear-Host
	

		try{	 
			 Write-Host "#############################################################################################################################" -ForegroundColor White
			 Write-Host "#                                                Capture Support Dump                                                       #" -ForegroundColor White
			 Write-Host "#############################################################################################################################`n" -ForegroundColor White
			 
			 $sshcapture = 'source /var/tmp/build/bin/appsetup; /var/tmp/build/cli/svt-support-capture > /dev/null 2>&1 &'
			 $sshpurge = 'sudo find /core/capture/Capture*.tgz -maxdepth 1 -type f -exec rm -fv {} \;'
			 $sshfile = 'ls -pl /core/capture'
 
			 $ErrorActionPreference = "SilentlyContinue"
			 $WarningPreference ="SilentlyContinue"
 
			 ## Authentication & Variables & Installed Modules
			 Invoke-SVT
			 
			 ## Network Port Test
	         Write-Host "`nExecuting TCP Ports Connection Tests (22/TCP, 443/TCP, 80/TCP) To The VMware VCenter..."  -ForegroundColor Yellow
	         Test-Net-Connection $global:vCenterServer
 
			 #Login Vmware VCenter
			 try {
 
				 Write-Output "`nTrying to establish connection to the Vmware Virtual Center Server:"
				 $VMWareVcenter = Connect-VIServer -Server $global:vCenterServer -Protocol https -Credential $global:Cred -Force -ErrorAction Stop
 
				 Write-Host "Connection established to target VCenter $($global:vCenterServer)`n" -ForegroundColor Green
 
			 } catch {
 
				 Write-Host "Connection could not be established to target VCenter $($global:vCenterServer) .`n" -ForegroundColor Red
				 Break
 
			 }
			 
			 #Datacenter Variables
			 $datacenter_list = Get-Datacenter -Server $global:vCenterServer
			 $datacentername = @()
			 $datacenterid = 1
			 $DCNameMap = @{}
 
             # Display the names of array members with index numbers
			 Write-Host "     VMware Environment DataCenter List:    " -ForegroundColor Yellow
			 Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 foreach ($datacenter in $datacenter_list) {
				 $datacentername = $datacenter.name
 
				 # Display Datacenter Name 
				 Write-Host "ID: $datacenterid - VMware DataCenter Name: $datacentername" -ForegroundColor Yellow
 

				 $DCNameMap["$datacenterid"] = $datacentername
				 $datacenterid++
			 }
             Write-Host "--------------------------------------------" -ForegroundColor Yellow
 
			 do {
				 # Prompt the user to select Datacenter
				 $selecteddcId = $(Write-Host "Select DataCenter by ID [1,2,3,..]: " -NoNewline -ForegroundColor White; Read-Host -ErrorAction SilentlyContinue)
				 $selecteddcname = $DCNameMap[$selecteddcId]
 

				 if ($selecteddcname) {
					 Write-Host "Selected DataCenter Name: $selecteddcname`n" -ForegroundColor Green
					 break 
				 } else {
					 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
				 }
			 } while ($true)
 
			 # List Vmware Clusters
 
			 #Cluster Variables
			 $cluster_list = Get-Cluster -Server $global:vCenterServer -Location $selecteddcname
			 $clustername = @()
			 $clusterid = 1
			 $CLSNameMap = @{}
 
			 # Display the names of datacenter members with index numbers
			 Write-Host "      VMware Environment Cluster List:      " -ForegroundColor Yellow
			 Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 foreach ($cluster in $cluster_list) {
				 $clustername = $cluster.name
 
				 # Display Cluster Name 
				 Write-Host "ID: $clusterid - VMware Cluster Name: $clustername" -ForegroundColor Yellow
 
				 # Map the ID to the IP address and add it to the array
				 $CLSNameMap["$clusterid"] = $clustername
				 $clusterid++
			 }
             Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 do {
				 # Prompt the user to select Cluster
				 $selectedclsId = $(Write-Host "Select Cluster by ID [1,2,3,..]: " -NoNewline -ForegroundColor White; Read-Host -ErrorAction SilentlyContinue)
				 $selectedclsname = $CLSNameMap[$selectedclsId]
 
				 # Validate and assign the selected IP address
				 if ($selectedclsname) {
					 Write-Host "Selected Cluster Name: $selectedclsname`n" -ForegroundColor Green
					 break 
				 } else {
					 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
				 }
			 } while ($true)
 
			 #Connect to the SimpliVity cluster
			 $ovcvms = Get-VM -Location $selectedclsname | Where-Object { $_.Name -like "OmniStackVC*" }
			 $OvcIpAddresses = @()
			 $ovcid = 1
			 $ovcIpMap = @{}
 
			 # Display the names of array members with index numbers
			 Write-Host "     Omnistack Virtual Controller List:     " -ForegroundColor Yellow
			 Write-Host "--------------------------------------------" -ForegroundColor Yellow
			 foreach ($ovcvm in $ovcvms) {
				 $ovc = Get-VMGuest -VM $ovcvm
				 $ovcvmName = $ovcvm
				 $ovchostname = $ovc.HostName
				 $OvcIpAddress = $ovc.IPAddress | Select-Object -First 1
 
				 # Display VM Name and IP Address
				 Write-Host "ID: $ovcid - OVC VM Name: $ovcvmName - Management IP Address: $($OvcIpAddress)" -ForegroundColor Yellow
 
				 # Map the ID to the IP address and add it to the array
				 $ovcIpMap["$ovcid"] = $OvcIpAddress
				 $ovcid++
			 }
			 Write-Host "--------------------------------------------" -ForegroundColor Yellow
 
			 if ($ovcid -ge 2 ){
				 
				 do {
					 # Prompt the user to select an IP address
					 $selectedovcId = $(Write-Host "Select an OVC IP Address by ID: [1,2,3,..]: " -NoNewline -ForegroundColor White; Read-Host -ErrorAction SilentlyContinue)
					 $selectedovcIpAddress = $ovcIpMap[$selectedovcId]
 
					 # Validate and assign the selected IP address
					 if ($selectedovcIpAddress) {
						 Write-Host "Selected OVC IP Address: $selectedovcIpAddress`n" -ForegroundColor Green
						 break 
					 } else {
						 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
					 }
 
				 } while ($true)
 
                ## Network Port Test
	            Write-Host "Executing TCP Ports Connection Tests (22/TCP, 443/TCP, 80/TCP) To The Omnistack Virtual Controller: $($selectedovcIpAddress) ..."  -ForegroundColor Yellow
	            Test-Net-Connection $selectedovcIpAddress
 
				 try {
					 # Attempt to access  OVC IP address in the array    
					 $SSHDumpCon = New-SSHSession -ComputerName $selectedovcIpAddress -port 22 -Credential $Cred -ErrorAction Stop
					 Write-Host "Connection established to target OVC Host - $($selectedovcIpAddress) `n" -ForegroundColor Green
				 } catch {
				 
					 Write-Host "Connection could not be established to target OVC Host - $($selectedovcIpAddress) !!!`n" -ForegroundColor Red
					 Break
				 }
 
			 } else {
				 Write-Host "Message: Can Not Get OVC Informations Rleated Cluster, Re-Run Script Then Select Another Cluster !!! `n" -ForegroundColor Red
				 Break
			 }
			 
			 # Get all the SSH Sessions
			 $DumpSession = Get-SSHSession | Where-Object { $_.Host -like "$($selectedovcIpAddress)" } | Select-Object SessionId
			 
			 try {
				 Write-Host "Purging previous capture files..."
				 $null = Invoke-SSHcommand -SessionId $DumpSession.SessionId -Command $sshpurge -ErrorAction Stop
			 }
			 catch {
				 Write-Warning "Could not find purge old capture files on  virtual controller..."
			 }
 
			 
			 # Capture Support Dump
			 Write-Host "Running capture command on target virtual controller..."
			 $SupportDump = Invoke-SSHcommand -SessionId $DumpSession.SessionId -Command $sshcapture -TimeOut 30
			 Start-Sleep -Seconds 30
 
			 # Total wait time in seconds (5 minutes)
			 $totalWaitTime = 300
			 $additionatime = 4
			 $try = 1
 
			 for ($i = $totalWaitTime; $i -gt 0; $i--) {
					 # Remaining time in minutes and seconds
					 $minutes = [math]::Floor($i / 60)
					 $seconds = $i % 60
				 
					 # Display progress
					 Write-Progress -Activity "Wait for capture to complete on $($Session.Host) try no: $try .." -Status "$minutes minutes $seconds seconds remaining" -PercentComplete ((($totalWaitTime - $i) / $totalWaitTime) * 100)
 
					 # Wait for one second
					 Start-Sleep -Seconds 1
 
					 if ($additionatime -eq 0)
					 {
						 Write-Warning "Could not capture the support file properly !!!" -ForegroundColor Red
						 Remove-SSHSession -SessionId $DumpSession.SessionId | Out-Null
						 Break
					 }
 
					 if ($i -le 5) {
						 $Output = Invoke-SSHcommand -SessionId $DumpSession.SessionId -Command $sshfile | Select-Object -ExpandProperty Output
						 $CaptureFile = ($Output | Select-Object -last 1).Split(' ')[-1]
						 # Check if the last object is a folder, if so wait.
						 if (($CaptureFile[-1]) -eq '/') {
							 $i = 300
							 $additionatime--
							 $try++
							 continue
 
						 } else {
 
							 try {
 
								 Write-Progress -Activity "Wait for capture to complete on $($Session.Host) try no: $try .." -Status "Complete" -PercentComplete 100
								 Start-Sleep 2
								 $CaptureWeb = "http://$selectedovcIpAddress/capture/$CaptureFile"
								 Write-Host "Downloading the capture file: $CaptureWeb ..." -ForegroundColor Green
								 Invoke-WebRequest -Uri $CaptureWeb -OutFile "$global:ReportDirPath\$CaptureFile"
	 
								 # Disconnect SSH Session
								 Remove-SSHSession -SessionId $DumpSession.SessionId | Out-Null
 
								 Write-Host "You Can Find SVT Support Dump Below: $global:ReportDirPath\$CaptureFile `n" -ForegroundColor yellow
								 Break
							 }
							 catch {
								 Write-Warning "Could not download the support file from $selectedovcIpAddress : $($_.Exception.Message)"
								 Break	
							 }
						 }
					 }		 
			 }
			 
        }
	
	catch {}
	
	finally
	{
			
			 Write-Host "Disconnect from vCenter Server..." -ForegroundColor Yellow
			 # Disconnect from vCenter Server
			 Disconnect-VIServer -Server $global:vCenterServer -Force -Confirm:$false
			 
			 Write-Host "Disconnect All SSH Session`n" -ForegroundColor Yellow
			 # Disconnect ALL SSH Sessşon
			 Get-SSHSession | Remove-SSHSession | Out-Null
 
			 if($Error.Count -ne 0 )
			 {
			 	 Write-Host "Script executed with few errors !!!" -ForegroundColor Red
		         Write-host -f Red "Error:" $Error 
			 }
			 
			 Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
			 
			 # Remove Variables
			 Remove-Variable * -ErrorAction SilentlyContinue; $error.Clear();
	}
	
 }

function Upload-Report-Files{
	
	Clear-Host
	 
	Write-Host "`n#############################################################################################################################"  -ForegroundColor White
    Write-Host "#                                                   Upload Report Files                                                       #" -ForegroundColor White
    Write-Host "#############################################################################################################################`n" -ForegroundColor White
 
	#Load Required Modules
	Load-Modules
	 
	# Define Server Name
	$SFTPServer = "hprc-h2.it.hpe.com"
	$SFTPServerPort = "2222"

	# Set local file path and SFTP path
	$SftpPath = "/"
	$ReportDirPath= "$PSScriptRoot\Reports"

	# SFTP Server Credential File
	$SFTPCredFile = "$PSScriptRoot\sftp-cred.XML"

	try {
			
		$Global:ProgressPreference = 'SilentlyContinue'
		$SFTPconnection = Test-NetConnection -Port 2222 -ComputerName $SFTPServer -ErrorAction stop -WarningAction Stop

		Write-Host "`nMessage: TCP Port Connection to $($SFTPServer) Test Success..." -ForegroundColor Green
		$Global:ProgressPreference = 'Continue'
				
	} catch {
			
		Write-Host "`nMessage: TCP Port Connection to $($SFTPServer) Test Failed, Check Firewall or Network Infrastructure !!!" -ForegroundColor Red
		$Global:ProgressPreference = 'Continue'
		Break
				
	}

	# Check if the credential file already exists
	if (-Not (Test-Path $SFTPCredFile)) {
		# Prompt the user for credentials
		Get-Credential -Message 'Enter HPE SFTP Server Credential' | Export-Clixml $SFTPCredFile 
		Write-Host "Credentials saved to $SFTPCredFile ."
			 
	} else {
		Write-Host "The credential file $SFTPCredFile already exists. No action taken..." -ForegroundColor Green
			 
	}

	#Import Credential File
	$SFTPCred = Import-CLIXML $SFTPCredFile
		
	if(Test-Path -Path $ReportDirPath)
	{
		# lists directory files into variable
		$ReportsFilePath = get-childitem $ReportDirPath 

		try {
			
			# Establish the SFTP connection
			Write-Host "Trying to establish connection to the $($SFTPServer)... " -ForegroundColor Yellow
			$SFTPSession = New-SFTPSession -ComputerName $SFTPServer -Credential $SFTPCred  -ConnectionTimeout 60 -Port $SFTPServerPort -Force -ErrorAction Stop
			Write-Host "SFTP Connection to $($SFTPServer) Successfully Established..." -ForegroundColor Green 
			$CaptureSFTPSession = Get-SFTPSession | Where-Object { $_.Host -like "$($SFTPServer)" }  | Select-Object SessionId
		
		} catch {
			
			 Write-Host "`nSFTP Connection to $($SFTPServer) Failed !!! `n" -ForegroundColor Red
			 Break
			
		}
		
		try {
			
			Write-Host "`nUpload Report Files To The HPE SFTP Server... " 
			# Action for each file within the $filepath variable copies them to the SFTP server
			ForEach ($LocalFile in $ReportsFilePath)
			{
			   Write-Host "Upload $global:ReportDirPath\$LocalFile ..." 
			   Set-SFTPItem -SessionId $CaptureSFTPSession.SessionID -Path "$ReportDirPath\$LocalFile" -Destination $SftpPath -Force -ErrorAction Stop
			}
			
			Write-Host "`nUploaded Report Files Successfully... `n" -ForegroundColor Green

		} catch {
			
			 Write-Host "Can Not Upload Report File Successfully: $ReportDirPath\$LocalFile !!! `n" -ForegroundColor Red

		} finally{	
            Remove-SFTPSession -SessionId $CaptureSFTPSession.SessionID | Out-Null	
		}
		
	}else{
		Write-Host "Repors Directory Does Not Exists !!! `n" -f Red
	}
	
	 # Remove Variables
	 Remove-Variable * -ErrorAction SilentlyContinue; $error.Clear();
  
}
 
function Get-Update-Manager{
	 
	 # Define Report Date
	 $reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"
 
	 #Log Timestamp
	 $logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }
	 
	 Clear-Host
	 

		 
		  $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Status, CSName ,Caption, BuildNumber, TotalVisibleMemorySize
		  $totalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
		  $memoryInfo = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
		  
		  $UpdateManagerReportFile = "$($global:ReportDirPath)\$($osInfo.CSName)-$($logtimestamp).log"
		  
		  # Start a transcript log
		  Start-Transcript -Path $UpdateManagerReportFile 
						 
		  Write-Host "#############################################################################################################################" -ForegroundColor Yellow
		  Write-Host "#                      HPE Update Manager Host $($osInfo.CSName) System Requirements Check Report                            "
		  Write-Host "#############################################################################################################################`n" -ForegroundColor Yellow
 
		  Write-Host "`nReport Creation Date: $($reportdate)" 
		  Write-Host "Customer Name:        $($global:customername)" 	
		  Write-Host "Customer E-Mail:      $($global:customermail)" 
		  Write-Host "Company Name:         $($global:companyname)`n" 
		  
		  Write-Host "`n### Operating System Information ###"
		  
		  if ($osInfo) {
			 # Display Operating System information in a table
			 $osTable = $osInfo | ForEach-Object {
				 [PSCustomObject]@{
					 Status = $_.Status
					 OSHostName = $_.CSName
					 Caption = $_.Caption
					 BuildNumber = $_.BuildNumber
					 TotalCPUCores = $totalCores
					 MemoryGB = $($memoryInfo.Sum / 1GB)
				 }
			 }
 
			 $osTable | Format-Table -AutoSize
			 
			 # Check if OS version 
			 $osbuild = $osInfo.BuildNumber 
			 
			 if ($osBuild -in '6003', '7601', '9200', '9600', '14393', '16299', '17134', '17763', '18362', '18363', '19041', '19042', '20348' -and $($memoryInfo.Sum / 1GB) -ge '14' -and $totalCores -ge '2' ) {
				 Write-Host "Message: Supported Operating System Resources & Version found.. `n" -ForegroundColor Green
			 } else {
				 Write-Host "Message: Unsupported Operating System Resources & Version found!!! `n" -ForegroundColor Red
			 }
		 }
		  
		  
		  Write-Host "`n### Installed Java Information ###"
		  # Check Host Status
		  $javaInfo = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE (Name LIKE 'Java%') AND NOT (Name LIKE '%Updater%')"
				   
		  if ($javaInfo) {
			 # Display Java information in a table
			 $javaTable = $javaInfo | ForEach-Object {
				 [PSCustomObject]@{
					 InstalledJava = $_.Name
					 Version = $_.Version
					 Vendor = $_.Vendor
				 }
			 }
 
			 $javaTable | Format-Table -AutoSize
			 
			 # Check if Java version is 8
			 
			 $javaVersion = $javaInfo | Where-Object { $_.Version -ge '8.0' -and $_.Version -lt '9.0' }
			 
			 if ($javaVersion) {
				 Write-Host "Message: Supported Java version found.. `n" -ForegroundColor Green
			 } else {
				 Write-Host "Message: Unsupported Java version found !!! `n" -ForegroundColor Red
			 }
		 } else {
			 Write-Host "Message: No Java installation found !!! `n" -ForegroundColor Red
		 }
 
		  Write-Host "`n### Installed Microsoft .NET Framework Information ###"
		  
		  # Check Host Status
		  $AspNetInfo = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE (Name LIKE 'Microsoft%ASP.NET%Core%')"
				   
		  if ($AspNetInfo) {
			 # Display Microsoft .NET Framework information in a table
			 $AspNetTable = $AspNetInfo | ForEach-Object {
				 [PSCustomObject]@{
					 InstalledAspNet = $_.Name
					 Version = $_.Version
					 Vendor = $_.Vendor
				 }
			}
 
			 $AspNetTable | Format-Table -AutoSize
			 
			 # Check if Microsoft .NET Framework is older then 4.7.x
			 
			 $AspNetVersion = $AspNetInfo | Where-Object { $_.Version -ge '4.7' }
			 
			 if ($AspNetVersion) {
				 Write-Host "Message: Supported Microsoft .NET Framework version found.. `n" -ForegroundColor Green
			 } else {
				 Write-Host "Message: Unsupported Microsoft .NET Framework version found !!! `n" -ForegroundColor Red
			 }
		 } else {
			 Write-Host "Message: No Microsoft .NET Framework installation found !!! `n" -ForegroundColor Red
		 }
 
		 Stop-Transcript

	 
	 finally
	 {
		 if($Error.Count -ne 0 )
		 {
			 Write-Host "`nScript executed with few errors !!!`n" -ForegroundColor Red
		 }
			 
			 Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
			 
			 # Remove Variables
			 Remove-Variable * -ErrorAction SilentlyContinue; $error.Clear();
	 }
 ### End Function	
 }