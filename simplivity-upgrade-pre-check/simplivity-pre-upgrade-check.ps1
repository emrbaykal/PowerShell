####################################################################
#HPE Simplivity Pre-Upgrade Check                                  #
####################################################################

<#
.Synopsis
    This Script perform Pre-Upgrade Checks to the simplivity servers.

.DESCRIPTION
    This Script perform Pre-Upgrade Checks to the simplivity servers.
	
.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\simplivity-pre-upgrade-check.ps1
	
	This script does not take any parameter and gets the server information for the given target iLO's.
    
.INPUTS
	Customer Name & Surname ,Customer E-Mail, Company Name, VMWare VCenter Server(ip), VCenter Username & Password.   

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 2.1.0.0
    Date    : 12/23/2023
	AUTHOR  : Emre Baykal - HPE Services
#>

function Invoke-SVT {
     
	# Define the path to variable file
	 $InfraVariableFile = ".\infra_variable.json"
 
	 # Define the path to the credential file
	 $credFile = ".\cred.XML"
	 
	 #Reports Directory
	 $global:ReportDirPath= ".\Reports"
 
	 #Load HPESimpliVity , VMware.PowerCLI, Posh-SSH
	 $InstalledModule = Get-Module
	 $ModuleNames = $InstalledModule.Name
 
	 if(-not($ModuleNames -like "HPESimpliVity") -or -not($ModuleNames -like "VMware.PowerCLI") -or -not($ModuleNames -like "Posh-SSH"))
	 {
		 Write-Host "Loading module :  HPESimpliVity ,VMware.PowerCLIs, Posh-SSH "
		 Import-Module HPESimpliVity, VMware.PowerCLI, Posh-SSH
		 if(($(Get-Module -Name "HPESimpliVity")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "HPESimpliVity module cannot be loaded. Please fix the problem and try again"
			 Write-Host ""
			 Write-Host "Exit..."
			 exit
		 }
 
		 if(($(Get-Module -Name "VMware.PowerCLI")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "VMware.PowerCLI module cannot be loaded. Please fix the problem and try again"
			 Write-Host ""
			 Write-Host "Exit..."
			 exit
		 }
		 
		 if(($(Get-Module -Name "Posh-SSH")  -eq $null))
		 {
			 Write-Host ""
			 Write-Host "Posh-SSH module cannot be loaded. Please fix the problem and try again"
			 Write-Host ""
			 Write-Host "Exit..."
			 exit
		 }
		 
	 }
 
	 else
	 {
		 $InstalledSimplivityModule  =  Get-Module -Name "HPESimpliVity"
		 $InstalledVmwareModule  =  Get-Module -Name "VMware.PowerCLI"
		 $InstalledPoshSSHModule  =  Get-Module -Name "Posh-SSH"
		 Write-Host "HPESimpliVity Module Version : $($InstalledSimplivityModule.Version) , VMware Module Version : $($InstalledVmwareModule.Version) , SSH Module Version: $($InstalledPoshSSHModule) installed on your machine."
		 Write-host ""
	 }
 
	 $Error.Clear()
 
 
	 if($Error.Count -ne 0)
	 { 
		 Write-Host "`nPlease launch the PowerShell in administrator mode and run the script again." -ForegroundColor Yellow 
		 Write-Host "`n****** Script execution terminated ******" -ForegroundColor Red 
		 exit 
	 }	
 
 
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
		 $global:Cred = Get-Credential -Message 'Enter VMWare VCenter Server Credential' -Username 'administrator@vsphere.local' | Export-Clixml .\cred.XML
		 Write-Host "Credentials saved to $credFile."
		 
	 } else {
		 Write-Host "The credential file $credFile already exists. No action taken..." -ForegroundColor Green
	 }
 
	 #Import Credential File
	 $global:Cred = Import-CLIXML .\cred.XML
	 
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
 
 function Get-SVT-Cluster {
	 
	 Write-Host "`n####################################################################"
	 Write-Host "#                     HPE Simplivity Pre-Upgrade Check             #"
	 Write-Host "####################################################################`n"
 
	 # Define Report Date
	 $reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"
 
	 #Log Timestamp
	 $logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }
 
	 ## Authentication & Variables & Installed Modules
	 Invoke-SVT
 
	 try {
	 #######	
			 $ErrorActionPreference = "SilentlyContinue"
			 $WarningPreference ="SilentlyContinue"
 
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
			 
			 #Cluster Variables
			 $cluster_list = Get-Cluster -Server $global:vCenterServer
			 $clustername = @()
			 $clusterid = 1
			 $CLSNameMap = @{}
 
             # Display the names of array members with index numbers
			 Write-Host "VMware Environment DataCenter List:  " -ForegroundColor Yellow
			 Write-Host "-----------------------------------" -ForegroundColor Yellow
			 foreach ($datacenter in $datacenter_list) {
				 $datacentername = $datacenter.name
 
				 # Display Datacenter Name 
				 Write-Host "ID: $datacenterid - VMware DataCenter Name: $datacentername" -ForegroundColor Yellow
 

				 $DCNameMap["$datacenterid"] = $datacentername
				 $datacenterid++
			 }
 
			 do {
				 # Prompt the user to select Datacenter
				 Write-Host "`nSelect DataCenter by ID:" -ForegroundColor Yellow
				 $selecteddcId = Read-Host "Enter the ID"
				 $selecteddcname = $DCNameMap[$selecteddcId]
 

				 if ($selecteddcname) {
					 Write-Host "Selected DataCenter Name: $selecteddcname`n" -ForegroundColor Green
					 break 
				 } else {
					 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
				 }
			 } while ($true)
 
              
 
			 # Display the names of array members with index numbers
			 Write-Host "VMware Environment Cluster List:  " -ForegroundColor Yellow
			 Write-Host "-----------------------------------" -ForegroundColor Yellow
			 foreach ($cluster in $cluster_list) {
				 $clustername = $cluster.name
 
				 # Display Cluster Name 
				 Write-Host "ID: $clusterid - VMware Cluster Name: $clustername" -ForegroundColor Yellow
 
				 # Map the ID to the IP address and add it to the array
				 $CLSNameMap["$clusterid"] = $clustername
				 $clusterid++
			 }
 
			 do {
				 # Prompt the user to select Cluster
				 Write-Host "`nSelect Cluster by ID:" -ForegroundColor Yellow
				 $selectedclsId = Read-Host "Enter the ID"
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
			 Write-Host "Omnistack Virtual Controller List:  " -ForegroundColor Yellow
			 Write-Host "----------------------------------- " -ForegroundColor Yellow
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
 
			 if ($ovcid -ge 2 )
			 {
				 do {
					 # Prompt the user to select an IP address
					 Write-Host "Select an OVC IP Address by ID:" -ForegroundColor Yellow
					 $selectedovcId = Read-Host "Enter the ID"
					 $selectedovcIpAddress = $ovcIpMap[$selectedovcId]
 
					 # Validate and assign the selected IP address
					 if ($selectedovcIpAddress) {
						 Write-Host "Selected OVC IP Address: $selectedovcIpAddress`n" -ForegroundColor Green
						 break 
					 } else {
						 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
					 }
 
				 } while ($true)
				 
 
				 try {
					 # Attempt to access each OVC IP address in the array
					 Write-Host "Trying to establish connection to the Omnistack Virtual Controller: $($selectedovcIpAddress)" -ForegroundColor Yellow
					 $svt_connection = Connect-Svt -ovc $selectedovcIpAddress -Credential $global:Cred -ErrorAction Stop
 
					 Write-Host "Connection established to target OVC Host - $($selectedovcIpAddress) `n" -ForegroundColor Green
				 } catch {
 
					 Write-Host "Connection could not be established to target OVC Host !!!`n" -ForegroundColor Red
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
			 $CLSReportFile = "$($global:ReportDirPath)\$($clusterstate.omnistack_clusters[0].name)-$($logtimestamp).log"
 
			 # Start a transcript log
			 Start-Transcript -Path $CLSReportFile 
					 
			 Write-Host "`n####################################################################" -ForegroundColor Yellow
			 Write-Host "#     HPE Simplivity Cluster Pre-Upgrade Health Check Report       #" -ForegroundColor Yellow
			 Write-Host "####################################################################`n" -ForegroundColor Yellow
 
			 Write-Host "`nReport Creation Date: $($reportdate)" 
			 Write-Host "Customer Name:        $($global:customername)" 	
			 Write-Host "Customer E-Mail:      $($global:customermail)" 
			 Write-Host "Company Name:         $($global:companyname)`n" 

			 Write-Host "`n### VMWare Virtual Center  ###" -ForegroundColor DarkGray
			 # Get vCenter Server version
			 $vCenterInfo = Get-VIServer $global:vCenterServer -Credential $global:Cred | Select-Object -Property Version, Build, Name
			 
			 Write-Host "`nvCenter Server Name:          $($vCenterInfo.Name)"
			 Write-Host "vCenter Server Version:       $($vCenterInfo.Version)"
			 Write-Host "vCenter Server Build Number : $($vCenterInfo.Build)"
			 
			 Write-Host "`n### SVT Cluster State ###" -ForegroundColor DarkGray
			 # Get VMWare Cluster State
			 $vmwarecluster = Get-Cluster -Name $clusterstate.omnistack_clusters[0].name
			 
			 Write-Host "`nDatacenter Name:                $($clusterstate.omnistack_clusters[0].hypervisor_object_parent_name)"
			 Write-Host "Cluster Name:                   $($clusterstate.omnistack_clusters[0].name)"
			 Write-Host "Hypervisor Type:                $($clusterstate.omnistack_clusters[0].hypervisor_type)"
			 Write-Host "Management System:              $($clusterstate.omnistack_clusters[0].hypervisor_management_system_name)"	
			 
			 if ($clusterstate.omnistack_clusters[0].members.Count -lt 16) {
					 Write-Host "SVT Cluster Members Count:      $($clusterstate.omnistack_clusters[0].members.Count)"
			 
			 } else {
					 Write-Host "SVT  Cluster Members Count:      $($clusterstate.omnistack_clusters[0].members.Count)" -ForegroundColor Red
					 $memberscount = 1
			 }
			 Write-Host "SVT Current Running Version:    $($clusterstate.omnistack_clusters[0].version)"
			 if ($clusterstate.omnistack_clusters[0].upgrade_state -eq 'SUCCESS_COMMITTED') {
					 Write-Host "SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[0].upgrade_state)"
			 
			 } else {
					 Write-Host "SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[0].upgrade_state)" -ForegroundColor Red
					 $upgradestate = 1
			 }				 
			 Write-Host "SVT Time Zone:                  $($clusterstate.omnistack_clusters[0].time_zone)"
			 if ($vmwarecluster.ExtensionData.Summary.OverallStatus -eq 'green') {
				 Write-Host "VMWare CLs State:               HEALTHY"
			 }else {
				 Write-Host "VMWare CLs State:               WARRING" -ForegroundColor yellow
				 $vmclsstate = 1
			 }				
			 Write-Host "VMWare CLs Num Hosts:           $($vmwarecluster.ExtensionData.Summary.NumHosts)"
			 Write-Host "VMWare Total VM:                $($vmwarecluster.ExtensionData.Summary.UsageSummary.TotalVmCount)"
			 Write-Host "VMWare PoweredOff VM:           $($vmwarecluster.ExtensionData.Summary.UsageSummary.PoweredOffVmCount)"
					 
			 Write-Host "`n### SVT Cluster Arbiter State ###" -ForegroundColor DarkGray
			 
			 Write-Host "`nRequired Arbiter:                  $($clusterstate.omnistack_clusters[0].arbiter_required)"
			 
			 if ($clusterstate.omnistack_clusters[0].arbiter_required -eq 'true') {
				 if ($clusterstate.omnistack_clusters[0].arbiter_configured -eq 'true') {
						 Write-Host "Arbiter Configured  :               $($clusterstate.omnistack_clusters[0].arbiter_configured)"
						 
						 if ($clusterstate.omnistack_clusters[0].arbiter_connected -eq 'true') {
								 Write-Host "Arbiter Conected :                 $($clusterstate.omnistack_clusters[0].arbiter_connected)"
								 Write-Host "Arbiter Address  :                  $($clusterstate.omnistack_clusters[0].arbiter_address)"
							 }else {
								 Write-Host "Arbiter Conected  :                 $($clusterstate.omnistack_clusters[0].arbiter_connected)" -ForegroundColor Red
								 $arbiterconnected = 1 
							 }
	             
				 } else {
						 Write-Host "Arbiter Configured  :                  $($clusterstate.omnistack_clusters[0].arbiter_configured)" -ForegroundColor Red
						 $arbiterconfigured = 1
				 }
				 
			 }
	
			 
			 $pysical_space = $($clusterstate.omnistack_clusters[0].allocated_capacity / 1TB).ToString("F2")
			 $used_space = $($clusterstate.omnistack_clusters[0].used_capacity / 1TB).ToString("F2")
			 $free_space = $($clusterstate.omnistack_clusters[0].free_space / 1TB).ToString("F2")
			 $local_backup_space = $($clusterstate.omnistack_clusters[0].local_backup_capacity / 1TB).ToString("F2")
			 $percentFree = $(($clusterstate.omnistack_clusters[0].free_space / $clusterstate.omnistack_clusters[0].allocated_capacity) * 100).ToString("F2")	
			 $efficiency_ratio = $($clusterstate.omnistack_clusters[0].efficiency_ratio) 
 
			 
			 Write-Host "`n### SVT Cluster Storage State ###" -ForegroundColor DarkGray
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

			 Write-Host "`n### SVT Backup Policies ###" -ForegroundColor DarkGray
			 $BackupRulesTable | Format-Table -Property 'Policy Name', 'Backup Days', 'Rule Number', 'Destination', 'External Store Name', 'Frequency - Hours', 'Expiration Time - Day'

			 
			 
			 
			 # Get SVT Datastore Status
			 Write-Host "`n### SVT Datastore List ###" -ForegroundColor DarkGray
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
			 
			 Write-Host "### The Information Of Driven Virtual Machines ###" -ForegroundColor DarkGray
			 
			 # Get Virtual Machine States
			 $VMDetailList = Get-Cluster -Name $clusterstate.omnistack_clusters[0].name | Get-VM
			 # Create a table to display virtual machine information
			 $VMTable = @()
 
			 foreach ($VMDetail in $VMDetailList) {
				 $vmInfo = New-Object PSObject -Property @{
					 'VM Name' = $VMDetail.Name
					 'Power State' = $VMDetail.PowerState
					 'Overall Status' = $VMDetail.ExtensionData.OverallStatus
					 'Config Status' = $VMDetail.ExtensionData.ConfigStatus
					 'CPU Count' = $VMDetail.NumCpu
					 'Memory (GB)' = $VMDetail.MemoryGB
					 'Guest OS' = $VMDetail.GuestId
					 'VM Host' = $VMDetail.VMHost.Name
				 }
				 $VMTable += $vmInfo
			 }
			 # Display Detail of VM to the table
			 $VMTable | Sort -Property 'VMHost', 'Power State', 'Memory (GB)' | Format-Table -Property 'VM Name', 'Power State', 'Overall Status', 'Config Status', 'CPU Count', 'Memory (GB)', 'Guest OS', 'VM Host' 
			 
			 Write-Host "`n### The Information Of VM Replicasets ###" -ForegroundColor DarkGray
			 
			 # Get VM Replicaset State 
			 $vmreplicaset = Get-SVTvmReplicaSet -ClusterName $clusterstate.omnistack_clusters[0].name  | Select-Object  VmName, State,  HAStatus 
			 $vmreplicasetdegreded = Get-SVTvmReplicaSet -ClusterName $clusterstate.omnistack_clusters[0].name | Where-Object  HAStatus -eq  DEGRADED   |  Select-Object  VmName, State,  HAstatus
			 $vmreplicaset | Format-Table -AutoSize 
 
			 if ($upgradestate -eq $null -and $memberscount -eq $null -and $arbiterconfigured -eq $null -and $arbiterconnected -eq $null -and $storagefreestate -eq $null -and $vmreplicasetdegreded.Count -eq 0 -and $vmclsstate -eq $null) {
					 Write-Host "`nMessage: The status of the cluster ($($clusterstate.omnistack_clusters[0].name)) is consistent and you can continue to upgrade .... `n" -ForegroundColor Green
			 } else {
				 
				 Write-Host "`nMessage: SVT cluster ($($clusterstate.omnistack_clusters[0].name)) status is not consistent and should fix error states !!! `n" -ForegroundColor Red
				 
				 if ($upgradestate) {
				 Write-Host "`nError Message: Update status not in the expected state... `n"  -ForegroundColor Red
				 }
				 if ($memberscount) {
				 Write-Host "`nError Message: Svt cluster ($($clusterstate.omnistack_clusters[0].name)) is comprised of more than 16 HPE OmniStack hosts... `n"  -ForegroundColor Red
				 }
				 if ($arbiterconfigured) {
				 Write-Host "`nError Message: Arbiter host configuration is required. It has not been configured... `n"  -ForegroundColor Red
				 }
				 if ($arbiterconnected) {
				 Write-Host "`nError Message: Arbiter host is configured, but not connected to the SVT cluster...`n"  -ForegroundColor Red
				 }
				 if ($storagefreestate) {
				 Write-Host "`nError Message: Free space is below the value required for upgrading... `n"  -ForegroundColor Red
				 }
				 if ($vmreplicasetdegreded.Count -ne 0) {
				 Write-Host "`nError Message: Some Of virtual machines HA NOT COMPLIANT... `n"  -ForegroundColor Red
				 }
				 if ($vmclsstate) {
				 Write-Host "`nError Message: There are some errors or warnings in the cluster, check cluster state... `n"  -ForegroundColor yellow
				 }
			 }	
			 
			 Write-Host "`n#################################################################################################" -ForegroundColor yellow
			 Write-Host "#                  HPE Simplivity Hosts Pre-Upgrade Health Check Report                           " -ForegroundColor yellow
			 Write-Host "#################################################################################################`n" -ForegroundColor yellow
			 
			 # Get SVT Host Status
			 Write-Host "### SVT Host List ###" -ForegroundColor DarkGray
			 $hostlist = Get-Cluster -Name $clusterstate.omnistack_clusters[0].name | Get-VMHost
			 # Create a table to display svt host information
			 $HostTable = @()
 
			 foreach ($HostDetail in $hostlist) {
					 $EsxiPercentCpu = $(($HostDetail.CpuUsageMhz / $HostDetail.CpuTotalMhz ) * 100).ToString("F0")
					 $EsxiPercentMem = $(($HostDetail.MemoryUsageGB / $HostDetail.MemoryTotalGB ) * 100).ToString("F0")
						 
					 $HostInfo = New-Object PSObject -Property @{
							 'Name' = $HostDetail.ExtensionData.Name
							 'ConnectionState' = $HostDetail.ConnectionState
							 'PowerState' = $HostDetail.PowerState
							 'OverallStatus' = $HostDetail.ExtensionData.Summary.OverallStatus
							 'RebootRequired' = $HostDetail.ExtensionData.Summary.RebootRequired
							 'NumCpu' = $HostDetail.NumCpu
							 'CpuUsage %' = $EsxiPercentCpu
							 'MemoryUsage %' = $EsxiPercentMem
							 'Version' = $HostDetail.Version
					 }
					 $HostTable += $HostInfo
			 }
 
			 # Display Detail of SVT Host to the table
			 $HostTable | Sort -Property 'CpuUsage %', 'MemoryUsage %' | Format-Table -Property 'Name', 'ConnectionState', 'PowerState', 'OverallStatus', 'RebootRequired', 'NumCpu', 'CpuUsage %', 'MemoryUsage %', 'Version' | Format-Table -AutoSize
			 
			 
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
				 
				 # Get ESXI Host Infromation
				 $esxihost = Get-VMHost -Name $svthost.name  | Select-Object -Property NumCpu, CpuTotalMhz, CpuUsageMhz, MemoryTotalGB, MemoryUsageGB, Version, Build 
				 $percentCpu = $(($esxihost.CpuUsageMhz / $esxihost.CpuTotalMhz ) * 100).ToString("F0")
				 $percentMem = $(($esxihost.MemoryUsageGB / $esxihost.MemoryTotalGB ) * 100).ToString("F0")		
				 
				 Write-Host "`n#### SVT Host: $($svthost.name) ####`n" -ForegroundColor yellow
				 
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
				 
 
				 Write-Host "`n# SVT Host $($svthost.name) Hardware State  #" -ForegroundColor DarkGray
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
				 
				 Write-Host "`n# SVT Host $($svthost.name) Disk State #" -ForegroundColor DarkGray
				 $diskTable | Format-Table -AutoSize
 
			 
				 if ($hostconnectivity -eq $null -and $hostupgradestate -eq $null -and $hostdisktstate -eq $null -and $hostversion -eq $null -and $hwstate -eq $null -and $raidhwstate -eq $null -and $raidbatteryhwstate -eq $null -and $cpuusage -eq $null -and $memusage -eq $null) {
						 Write-Host "Message: The status of the SVT Host ( $($svthost.name) ) is consistent and you can continue to upgrade ....`n" -ForegroundColor Green
				 
				 } else {
					 
					 Write-Host "Message: SVT Host ( $($svthost.name) status is not consistent and should fix error states !!! `n" -ForegroundColor Red
					 
					 if ($hostconnectivity) {
					 Write-Host "Error Message: SVT Host ( $($svthost.name) State Not Alive `n"  -ForegroundColor Red
					 }
					 if ($hostupgradestate) {
					 Write-Host "Error Message: SVT Host ( $($svthost.name) Update status not in the expected state...`n "  -ForegroundColor Red
					 }
					 if ($hostdisktstate) {
					 Write-Host "Error Message: Detection of faulty discs on the SVT host ( $($svthost.name) , opening of a support case... `n"  -ForegroundColor Red
					 }
					 if ($hostversion) {
					 Write-Host "Error Message: Incompatible software version actively running on SVT host ( $($svthost.name)  ... `n"  -ForegroundColor Red
					 }
					 if ($hwstate) {
					 Write-Host "Error Message: Detection of faulty hardware component on the SVT host ( $($svthost.name) , opening of a support case... `n"  -ForegroundColor Red
					 }
					 if ($raidhwstate) {
					 Write-Host "Error Message: Detection of faulty raid card on the SVT host ( $($svthost.name) , opening of a support case... `n"  -ForegroundColor Red
					 }
					 if ($raidbatteryhwstate) {
					 Write-Host "Error Message: Detection of faulty raid card battery on the SVT host ( $($svthost.name) , opening of a support case... `n"  -ForegroundColor Red
					 }
					 if ($cpuusage) {
					 Write-Host "Error Message: High CPU usage detected on the SVT host ( $($svthost.name) ... `n"  -ForegroundColor yellow
					 }
					 if ($memusage) {
					 Write-Host "Error Message: High Memory usage detected on the SVT host ( $($svthost.name) ... `n"  -ForegroundColor yellow
					 }
				 }	
 
				 Write-Host "`n"
			 }
			 
			 Stop-Transcript
 
			 Write-Host "`n#################################################################################################" -ForegroundColor yellow
			 Write-Host "#                               Capture Balance File                                             #" -ForegroundColor yellow
			 Write-Host "#################################################################################################`n" -ForegroundColor yellow
 
			 $sshbalance = "source /var/tmp/build/bin/appsetup; sudo /var/tmp/build/dsv/dsv-balance-manual --datacenter $($selecteddcname) --cluster $($selectedclsname)"
			 $sshmovebalance = 'sudo find /tmp/balance/replica_distribution_file*.csv -maxdepth 1 -type f -exec cp {} /core/capture/  \;'
			 $sshbalancefile = 'sudo find /core/capture/replica_distribution_file*.csv -maxdepth 1 -type f'
 
			$sshbalance
			 try {
				 # Attempt to access  OVC IP addres 
				 Write-Host "Try to establish target OVC Host - $($selectedovcIpAddress)" -ForegroundColor Yellow  
				 $null = New-SSHSession -ComputerName $selectedovcIpAddress -port 22 -Credential $global:Cred -ErrorAction Stop
				 Write-Host "Connection established to target OVC Host - $($selectedovcIpAddress) `n" -ForegroundColor Green
			 } catch {
			 
				 Write-Host "Connection could not be established to target OVC Host - $($selectedovcIpAddress) !!!`n" -ForegroundColor Red
				 Break
			 }
			 
			 # Get all the SSH Sessions
			 $Session = Get-SSHsession
 
			 try {
				 # Capture Balance Report
				 Write-Host "Running capture balance report command on target virtual controller..."
				 $null = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshbalance -TimeOut 60  -ErrorAction Stop
			 
				 # Move Balance Report to /core/capture directory
				 Write-Host "Move Balance Report to /core/capture directory... `n"
				 $null = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshmovebalance -TimeOut 10 -ErrorAction Stop
			 
			 } catch {
			 
				 Write-Host "Capture balance report can not create on target virtual controller... !!!`n" -ForegroundColor Red
				 Break
			 }
			 
			 try {
			 
				 $balancefile = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshbalancefile | Select-Object -ExpandProperty Output 
				 $CaptureBalanceFile = ($balancefile | Select-Object -last 1).Split('/')[-1]
			 
				 Start-Sleep 2
				 $CaptureBalanceWeb = "http://$selectedovcIpAddress/capture/$CaptureBalanceFile"
				 Write-Host "Downloading the Balance Report file: $CaptureBalanceWeb ..." -ForegroundColor Green
				 Invoke-WebRequest -Uri $CaptureBalanceWeb -OutFile "$global:ReportDirPath\$CaptureBalanceFile"
			 
				 # Delete Balance Report File
				 $null = Invoke-SSHcommand -SessionId $Session.SessionId -Command "sudo rm -f  $balancefile" -TimeOut 10 -ErrorAction Stop
				  
				 # Disconnect All SSH Sessions
				 Get-SSHSession | Remove-SSHSession | Out-Null
 
				 Write-Host "You Can Find SVT Balance Report Below: $global:ReportDirPath\$CaptureBalanceFile `n" -ForegroundColor yellow
			 
			 } catch {
			 
				 Write-Warning "Could not download the support file from $selectedovcIpAddress : $($_.Exception.Message)"
				 Get-SSHSession | Remove-SSHSession | Out-Null
			 
			 }			
 
		 }
	 
	 catch{}    
	 
	 finally
	 {
			
			 Write-Host "Disconnect from vCenter Server`n" -ForegroundColor Yellow
			 # Disconnect from vCenter Server
			 Disconnect-VIServer -Server $global:vCenterServer -Force -Confirm:$false
 
			 if($Error.Count -ne 0 )
			 {
				 Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
			 }
			 
			 Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
	 }
	 
 ### End Function
 }
 
 function Get-SVT-Support-Dump {
 
			 Write-Host "`n#################################################################################################"
			 Write-Host "#                               Capture Support Dump                                            #"
			 Write-Host "#################################################################################################`n"
			 
			 $sshcapture = 'source /var/tmp/build/bin/appsetup; /var/tmp/build/cli/svt-support-capture > /dev/null 2>&1 &'
			 $sshpurge = 'sudo find /core/capture/Capture*.tgz -maxdepth 1 -type f -exec rm -fv {} \;'
			 $sshfile = 'ls -pl /core/capture'
 
			 $ErrorActionPreference = "SilentlyContinue"
			 $WarningPreference ="SilentlyContinue"
 
			 ## Authentication & Variables & Installed Modules
			 Invoke-SVT
 
			 #Login Vmware VCenter
			 try {
 
				 Write-Output "`nTrying to establish connection to the Vmware Virtual Center Server:"
				 $VMWareVcenter = Connect-VIServer -Server $global:vCenterServer -Protocol https -Credential $global:Cred -Force -ErrorAction Stop
 
				 Write-Host "Connection established to target VCenter $($global:vCenterServer)`n" -ForegroundColor Green
 
			 } catch {
 
				 Write-Host "Connection could not be established to target VCenter $($global:vCenterServer) .`n" -ForegroundColor Red
				 Break
 
			 }
 
			 # List Vmware Clusters
 
			 #Connect to the SimpliVity cluster
			 $cluster_list = Get-Cluster -Server $global:vCenterServer
			 $clustername = @()
			 $clusterid = 1
			 $CLSNameMap = @{}
 
 
			 # Display the names of array members with index numbers
			 Write-Host "VMware Environment Cluster List:  " -ForegroundColor Yellow
			 Write-Host "-----------------------------------" -ForegroundColor Yellow
			 foreach ($cluster in $cluster_list) {
				 $clustername = $cluster.name
 
				 # Display Cluster Name 
				 Write-Host "ID: $clusterid - VMware Cluster Name: $clustername" -ForegroundColor Yellow
 
				 # Map the ID to the IP address and add it to the array
				 $CLSNameMap["$clusterid"] = $clustername
				 $clusterid++
			 }
 
			 do {
				 # Prompt the user to select Cluster
				 Write-Host "`nSelect Cluster by ID:" -ForegroundColor Green
				 $selectedclsId = Read-Host "Enter the ID"
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
			 Write-Host "Omnistack Virtual Controller List:  " -ForegroundColor Yellow
			 Write-Host "-----------------------------------" -ForegroundColor Yellow
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
 
			 if ($ovcid -ge 2 ){
				 
				 do {
					 # Prompt the user to select an IP address
					 Write-Host "`nSelect an OVC IP Address by ID:" -ForegroundColor Yellow
					 $selectedovcId = Read-Host "Enter the ID" 
					 $selectedovcIpAddress = $ovcIpMap[$selectedovcId]
 
					 # Validate and assign the selected IP address
					 if ($selectedovcIpAddress) {
						 Write-Host "Selected OVC IP Address: $selectedovcIpAddress`n" -ForegroundColor Green
						 break 
					 } else {
						 Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
					 }
 
				 } while ($true)
 
				 try {
					 # Attempt to access  OVC IP address in the array    
					 $null = New-SSHSession -ComputerName $selectedovcIpAddress -port 22 -Credential $Cred -ErrorAction Stop
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
			 $Session = Get-SSHsession
			 
			 try {
				 Write-Host "Purging previous capture files..."
				 $null = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshpurge -ErrorAction Stop
			 }
			 catch {
				 Write-Warning "Could not find purge old capture files on  virtual controller..."
			 }
 
			 
			 # Capture Support Dump
			 Write-Host "Running capture command on target virtual controller..."
			 $null = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshcapture -TimeOut 30
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
						 Get-SSHSession | Remove-SSHSession | Out-Null
						 Break
					 }
 
					 if ($i -le 5) {
						 $Output = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshfile | Select-Object -ExpandProperty Output
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
	 
								 # Disconnect All SSH Sessions
								 Get-SSHSession | Remove-SSHSession | Out-Null
 
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
 
 function Get-Update-Manager{
	 
	 # Define Report Date
	 $reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"
 
	 #Log Timestamp
	 $logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }
	 
	 #Clear-Host
	 
	 try {
		 
		  $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Status, CSName ,Caption, BuildNumber, TotalVisibleMemorySize
		  $totalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
		  $memoryInfo = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
		  
		  $UpdateManagerReportFile = "$($global:ReportDirPath)\$($osInfo.CSName)-$($logtimestamp).log"
		  
		  # Start a transcript log
		  Start-Transcript -Path $UpdateManagerReportFile 
						 
		  Write-Host "`n#################################################################################################"
		  Write-Host "#        HPE Update Manager Host $($osInfo.CSName) System Requirements Check Report                "
		  Write-Host "#################################################################################################`n"
 
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
	 }
	 catch{}    
	 
	 finally
	 {
		 if($Error.Count -ne 0 )
		 {
			 Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
		 }
			 
			 Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
	 }
 
	 
	 
 ### End Function	
 }