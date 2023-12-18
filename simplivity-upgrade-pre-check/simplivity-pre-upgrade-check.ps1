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
	iLOInput.csv file in the script folder location having iLO IPv4 or ilo5 address, iLO Username and iLO Password.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 12/05/2023
	AUTHOR  : Emre Baykal HPE Services
#>



function Get-SVT-Cluster {
	
	Write-Host "`n####################################################################"
	Write-Host "#                     HPE Simplivity Pre-Upgrade Check             #"
	Write-Host "####################################################################`n"

	# Define Report Date
	$reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"

	# Define the path to variable file
	$InfraVariableFile = ".\infra_variable.json"

	# Define the path to the credential file
	$credFile = ".\cred.XML"

	#Reports Directory
	$ReportDirPath= ".\Reports"

	#Log Timestamp
	$logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }

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
			$customername  = Read-Host -Prompt 'Customer Name & Surname '
			
			# Define Customer Mail / # Define Custome Name / Enter the name of the person who administers the system.
			$customermail  = Read-Host -Prompt 'Customer E-Mail '
			
			# Define Company Name / Enter the company's name.
			$companyname  = Read-Host -Prompt 'Company Name '
			
			Write-Host "`nPlease fill in the following information about infrastructure..." -ForegroundColor Yellow
			# Define Vmwre vCenter Server Information
			$vcenterserver  = Read-Host -Prompt 'VMWare VCenter Server(ip) '

			Write-Host "`nCheck the following entries..."
			Write-Host "Customer Name:                '$customername' "
			Write-Host "Customer E-Mail:              '$customermail' "
			Write-Host "Company Name:                 '$companyname' "
			Write-Host "Vmware Virtual Center Server: '$vCenterServer' "
			
			# Prompt user for confirmation
			$confirmation = Read-Host -Prompt "`nDo you confirm the entered information? (Y/N)"
	 
			if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
					Write-Host "Information confirmed. Proceeding with the script..."
					break  
			} else {
					Write-Host "Confirmation not received. Please fill in the information again."
			
			}
			} while ($true)
			
				# Create a PowerShell custom object with the entered information
				$jsonData = [PSCustomObject]@{
					vCenterServer = $vcenterserver
					customername = $customername
					customermail = $customermail
					companyname = $companyname
				}

				# Convert the object to JSON format
				$jsonString = $jsonData | ConvertTo-Json
				
				# Write the JSON data to the file
				$jsonString | Set-Content -Path $InfraVariableFile
				
				Write-Host "Information has been saved to: $InfraVariableFile"

	} else {
		
		    Write-Host "The Infrastructure Variable file $InfraVariableFile already exists. No action taken.`n" -ForegroundColor Green
		   
			# Read the JSON content from the file
			$jsonInfraContent = Get-Content -Path $InfraVariableFile | Out-String | ConvertFrom-Json

			# Access the variables from the object
			$vcenterserver = $jsonInfraContent.vcenterserver
			$customername = $jsonInfraContent.customername
			$customermail = $jsonInfraContent.customermail
			$companyname = $jsonInfraContent.companyname
	}

	# Check if the credential file already exists
	if (-Not (Test-Path $credFile)) {
		# Prompt the user for credentials
		$Cred = Get-Credential -Message 'Enter VMWare VCenter Server Credential' -Username 'administrator@vsphere.local' | Export-Clixml .\cred.XML
		Write-Host "Credentials saved to $credFile."
		
	} else {
		Write-Host "The credential file $credFile already exists. No action taken.`n" -ForegroundColor Green
	}

	#Import Credential File
	$Cred = Import-CLIXML .\cred.XML

	#Check if Reports Directory Exists
	if(!(Test-Path -Path $ReportDirPath))
	{
		#powershell create reports directory
		New-Item -ItemType Directory -Path $ReportDirPath
		Write-Host "New reports directory created successfully !`n" -f Green
	}
	else
	{
		Write-Host "Repors directory already exists! `n" -f Yellow
	}
	
	#
	
	try {
		
			$ErrorActionPreference = "SilentlyContinue"
			$WarningPreference ="SilentlyContinue"
			
            #Login Vmware VCenter
            try {

			    Write-Output "`nTrying to establish connection to the Vmware Virtual Center Server:"
			    $VMWareVcenter = Connect-VIServer -Server $vCenterServer -Protocol https -Credential $Cred -Force -ErrorAction Stop

			    Write-Host "Connection established to target VCenter $($vCenterServer)`n" -ForegroundColor Green

            } catch {

                Write-Host "Connection could not be established to target VCenter $($vCenterServer) .`n" -ForegroundColor Red
				Break

            }

			
            #Connect to the SimpliVity cluster
			$ovcvms = Get-VM | Where-Object { $_.Name -like "OmniStackVC*" }
            $OvcIpAddresses = @()
            $ovcid = 1
            $ovcIpMap = @{}
			
            # Display the names of array members with index numbers
            Write-Host "Omnistack Virtual Controller List:  "
            Write-Host "-----------------------------------  `n"
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
            
            do {
                    # Prompt the user to select an IP address
                    Write-Host "`nSelect an OVC IP Address by ID:"
                    $selectedovcId = Read-Host "Enter the ID"
                    $selectedovcIpAddress = $ovcIpMap[$selectedovcId]

                    # Validate and assign the selected IP address
                    if ($selectedovcIpAddress) {
                        Write-Host "Selected OVC IP Address: $selectedovcIpAddress`n"
                        break 
                    } else {
                        Write-Host "Invalid selection. Please try to select a valid ID !!! `n" -ForegroundColor Red
                    }

            } while ($true)

             try {
                 # Attempt to access each OVC IP address in the array
                 Write-Host "Trying to establish connection to the Omnistack Virtual Controller: $($selectedovcIpAddress)"
                 $svt_connection = Connect-Svt -ovc $selectedovcIpAddress -Credential $Cred -ErrorAction Stop

                  Write-Host "Connection established to target OVC Host - $($selectedovcIpAddress) `n" -ForegroundColor Green
             } catch {

                  Write-Host "Connection could not be established to target OVC Host !!!`n" -ForegroundColor Red
                  Break
             }
           
			 
			#######
			# Get SVT Cluster Status
			$clusterstate = Get-SvtCluster -Raw | ConvertFrom-Json
			$upgradestate = $null
			$memberscount = $null
			$arbiterconfigured = $null
			$arbiterconnected = $null
			$storagefreestate = $null
			$vmclsstate = $null
			
			if ($clusterstate) {

				do {
					# Display the names of array members with index numbers
					Write-Host "Omnistack Cluster Name             ID"
					Write-Host "-----------------------         ---------"
					for ($i = 0; $i -lt $clusterstate.omnistack_clusters.Count; $i++) {
						Write-Host " $($clusterstate.omnistack_clusters[$i].name)                           $i"
					}

					Write-Host "`n"
					 
					# Prompt the user to select a cluster by id
					$ClusterId = Read-Host "Enter the id of the Omnistack cluster you want to select"


					# Prompt user for confirmation
					Write-Host "Selected Cluster: $($clusterstate.omnistack_clusters[$ClusterId].name)" -ForegroundColor Yellow
					$confirmation = Read-Host -Prompt "`nDo you confirm the entered information? (Y/N)"
			 
					if (($confirmation -eq 'Y' -or $confirmation -eq 'y') -and $clusterstate.omnistack_clusters[$ClusterId].name -ne $NULL) {
							Write-Host "Information confirmed. Proceeding with the script...`n"
							break  
					} else {
							Write-Host "Entry not approved. Please fill in the information again.`n"
					
					}
				} while ($true)
				
				
				$CLSReportFile = "$($ReportDirPath)\$($clusterstate.omnistack_clusters[$ClusterId].name)-$($logtimestamp).log"

				# Start a transcript log
				Start-Transcript -Path $CLSReportFile 
						
				Write-Host "`n####################################################################"
				Write-Host "#     HPE Simplivity Cluster Pre-Upgrade Health Check Report         #"
				Write-Host "####################################################################`n"

				Write-Host "`nReport Creation Date: $($reportdate)" 
				Write-Host "Customer Name:        $($customername)" 	
				Write-Host "Customer E-Mail:      $($customermail)" 
				Write-Host "Company Name:         $($companyname)`n" 
				
				Write-Host "`n### VMWare Virtual Center  ###`n"
				# Get vCenter Server version
				$vCenterInfo = Get-ViServer $vcenterserver | Select-Object -Property Version, Build, Name
				
				Write-Host "`nvCenter Server Name:          $($vCenterInfo.Name)"
				Write-Host "vCenter Server Version:       $($vCenterInfo.Version)"
				Write-Host "vCenter Server Build Number : $($vCenterInfo.Build)"
				
				Write-Host "`n### SVT Cluster State ###`n" 
				# Get VMWare Cluster State
				$vmwarecluster = Get-Cluster -Name $clusterstate.omnistack_clusters[$ClusterId].name
				
				Write-Host "`nDatacenter Name:                $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_object_parent_name)"
				Write-Host "Cluster Name:                   $($clusterstate.omnistack_clusters[$ClusterId].name)"
				Write-Host "Hypervisor Type:                $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_type)"
				Write-Host "Management System:              $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_management_system_name)"	
				
				if ($clusterstate.omnistack_clusters[0].members.Count -lt 16) {
						Write-Host "SVT Cluster Members Count:      $($clusterstate.omnistack_clusters[$ClusterId].members.Count)"
			  
				} else {
					   Write-Host "SVT  Cluster Members Count:      $($clusterstate.omnistack_clusters[$ClusterId].members.Count)" -ForegroundColor Red
					   $memberscount = 1
				}
				Write-Host "SVT Current Running Version:    $($clusterstate.omnistack_clusters[$ClusterId].version)"
				if ($clusterstate.omnistack_clusters[$ClusterId].upgrade_state -eq 'SUCCESS_COMMITTED') {
						Write-Host "SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[$ClusterId].upgrade_state)"
			  
				} else {
					   Write-Host "SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[$ClusterId].upgrade_state)" -ForegroundColor Red
					   $upgradestate = 1
				}				 
				Write-Host "SVT Time Zone:                  $($clusterstate.omnistack_clusters[$ClusterId].time_zone)"
				if ($vmwarecluster.ExtensionData.Summary.OverallStatus -eq 'green') {
					Write-Host "VMWare CLs State:               HEALTHY"
				}else {
					Write-Host "VMWare CLs State:               WARRING" -ForegroundColor yellow
					$vmclsstate = 1
				}				
				Write-Host "VMWare CLs Num Hosts:           $($vmwarecluster.ExtensionData.Summary.NumHosts)"
				Write-Host "VMWare Total VM:                $($vmwarecluster.ExtensionData.Summary.UsageSummary.TotalVmCount)"
				Write-Host "VMWare PoweredOff VM:           $($vmwarecluster.ExtensionData.Summary.UsageSummary.PoweredOffVmCount)"
						
				Write-Host "`n### SVT Cluster Arbiter State ###`n"
				
				Write-Host "`nRequired Arbiter:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_required)"
				
				if ($clusterstate.omnistack_clusters[$ClusterId].arbiter_required -eq 'true') {
					if ($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured -eq 'true') {
						  Write-Host "Arbiter Configured ?:               $($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured)"
						  
						  if ($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected -eq 'true') {
								  Write-Host "Arbiter Conected ?:                 $($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected)"
								  Write-Host "Arbiter Address ?:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_address)"
							  else {
								 Write-Host "Arbiter Conected ?:                 $($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected)" -ForegroundColor Red
								 $arbiterconnected = 1 
							  }
						  }
					} else {
						  Write-Host "Arbiter Configured ?:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured)" -ForegroundColor Red
						  $arbiterconfigured = 1
					}
					
				}
				
				$pysical_space = $($clusterstate.omnistack_clusters[$ClusterId].allocated_capacity / 1TB).ToString("F2")
				$used_space = $($clusterstate.omnistack_clusters[$ClusterId].used_capacity / 1TB).ToString("F2")
				$free_space = $($clusterstate.omnistack_clusters[$ClusterId].free_space / 1TB).ToString("F2")
				$local_backup_space = $($clusterstate.omnistack_clusters[$ClusterId].local_backup_capacity / 1TB).ToString("F2")
				$percentFree = $(($clusterstate.omnistack_clusters[$ClusterId].free_space / $clusterstate.omnistack_clusters[0].allocated_capacity) * 100).ToString("F2")	

				
				Write-Host "`n### SVT Cluster Storage State ###`n"
				Write-Host "`nHPE Simplivity Efficiency Ratio:   $($clusterstate.omnistack_clusters[0].efficiency_ratio)" 
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
				
				
				# Get SVT Datastore Status
				Write-Host "`n### SVT Datastore List ###"
				$DSDetailList = Get-SvtDatastore | Where-Object  ClusterName -eq $clusterstate.omnistack_clusters[$ClusterId].name |  Select-Object DatastoreName, SizeGB, SingleReplica, ClusterName, Deleted, PolicyName
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
				
				Write-Host "`n### The Information Of Driven Virtual Machines ###"
				
				# Get Virtual Machine States
				$VMDetailList = Get-Cluster -Name $clusterstate.omnistack_clusters[$ClusterId].name | Get-VM
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
				
				Write-Host "`n### The Information Of VM Replicasets ###"
				
				# Get VM Replicaset State 
				$vmreplicaset = Get-SVTvmReplicaSet -ClusterName $clusterstate.omnistack_clusters[$ClusterId].name  | Select-Object  VmName, State,  HAStatus 
				$vmreplicasetdegreded = Get-SVTvmReplicaSet -ClusterName $clusterstate.omnistack_clusters[$ClusterId].name | Where-Object  HAStatus -eq  DEGRADED   |  Select-Object  VmName, State,  HAstatus
				$vmreplicaset | Format-Table -AutoSize 
					


				if ($upgradestate -eq $null -and $memberscount -eq $null -and $arbiterconfigured -eq $null -and $arbiterconnected -eq $null -and $storagefreestate -eq $null -and $vmreplicasetdegreded.Count -eq 0 -and $vmclsstate -eq $null) {
						Write-Host "`nMessage: The status of the cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) is consistent and you can continue to upgrade .... `n" -ForegroundColor Green
				} else {
					
				   Write-Host "`nMessage: SVT cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) status is not consistent and should fix error states !!! `n" -ForegroundColor Red
				   
				   if ($upgradestate) {
					Write-Host "`nError Message: Update status not in the expected state... `n"  -ForegroundColor Red
					}
					if ($memberscount) {
					Write-Host "`nError Message: Svt cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) is comprised of more than 16 HPE OmniStack hosts... `n"  -ForegroundColor Red
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
			
				
				Write-Host "`n--- Host Requirements ---`n"
				
				Write-Host "`n#################################################################################################"
				Write-Host "#                  HPE Simplivity Hosts Pre-Upgrade Health Check Report                           "
				Write-Host "#################################################################################################`n"
				
				# Get SVT Host Status
				Write-Host "`n### SVT Host List ###"
				$hostlist = Get-Cluster -Name $clusterstate.omnistack_clusters[$ClusterId].name | Get-VMHost
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
				
				
				$hoststate = Get-SvtHost -ClusterName $clusterstate.omnistack_clusters[$ClusterId].name -Raw | ConvertFrom-Json
				
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
					
					Write-Host "`n### SVT Host: $($svthost.name) ###`n"
					
					Write-Host "`nSVT Host Name:               $($svthost.name)"
					Write-Host "SVT Host IP:                 $($svthost.hypervisor_management_system)"
					if ($svthost.state -eq 'ALIVE') {
						Write-Host "SVT Host State:              $($svthost.state)" 
					}else {
						Write-Host "SVT Host State:              $($svthost.state)" -ForegroundColor Red
						$hostconnectivity = 1
					}	
					Write-Host "SVT Host Model:              $($svthost.model)"
					if ($svthost.version -eq $clusterstate.omnistack_clusters[$ClusterId].version) {
						Write-Host "SVT Host Version:           $($svthost.version)"
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
					
					#####

					Write-Host "`n# SVT Host $($svthost.name) Hardware State: `n"
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
					
					Write-Host "`n# SVT Host $($svthost.name) Disk State:"
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

					Write-Host "---------------`n"
				}
				
				Stop-Transcript
				
				####
				
				Write-Host "`n#################################################################################################"
				Write-Host "#                               Capture Support Dump                                            #"
				Write-Host "#################################################################################################`n"
				
				$sshcapture = 'source /var/tmp/build/bin/appsetup; /var/tmp/build/cli/svt-support-capture'
				$sshpurge = 'sudo find /core/capture/Capture*.tgz -maxdepth 1 -type f -exec rm -fv {} \;'
				$sshfile = 'ls -pl /core/capture'
				
				# Attempt to access each OVC IP address in the array	
				$null = New-SSHSession -ComputerName $selectedovcIpAddress -port 22 -Credential $Cred -ErrorAction Stop
				
				# Get all the SSH Sessions
				$Session = Get-SSHsession

				
				if ($Session.SessionId -eq 0) {
					Write-Host "SSH Connection established to target OVC Host $selectedovcIpAddress `n" -ForegroundColor Green
					

					try {
						Write-Host "Purging previous capture files... `n"
						$null = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshpurge -ErrorAction Stop
					}
					catch {
						Write-Warning "Could not purge old capture files on one or more virtual controllers... `n"
					}

					
					
					try {
						Write-Host "Running capture command on each target virtual controller. This will take up to 7 minutes... `n"
						$null = Invoke-SSHcommand -SessionId $Session.SessionId -Command $sshcapture -TimeOut 420
					}
					catch {
						Write-Warning "Capture command timed out on one or more virtual controllers. We'll need to wait longer, it seems... `n"
					}
			
	
			        foreach ($ThisSession in $Session) {
						$ThisId = $ThisSession.SessionId
						$ThisHost = $ThisSession.Host
						$FolderFound = $true
						do {
							try {
								$Output = Invoke-SSHcommand -SessionId $ThisId -Command $sshfile | Select-Object -ExpandProperty Output
								$Output

								$CaptureFile = ($Output | Select-Object -last 1).Split(' ')[-1]
								Write-Host "Capture file is $CaptureFile... `n"
								# Check if the last object is a folder, if so wait.
								if (($CaptureFile[-1]) -eq '/') {
									Write-Host "Wait 30 seconds for capture to complete on $ThisHost..."
									Start-Sleep 30
								}
								else {
									$FolderFound = $false
									$CaptureWeb = "http://$ThisHost/capture/$CaptureFile"
									Write-Host "`nDownloading the capture file: $CaptureWeb ..."
									Invoke-WebRequest -Uri $CaptureWeb -OutFile "$ReportDirPath\$CaptureFile"
								}
							}
							catch {
								$FolderFound = $false
								Write-Warning "Could not download the support file from $Thishost : $($_.Exception.Message)"
							}
						}
						While ($FolderFound)
					}
					
					$Error.Clear()
					
					Write-Host "Support Dump Downloaded Successfully ... `n" -ForegroundColor Green
					# Cleanup
					$null = Remove-SSHSession -SessionId $Session.SessionId
						
				}
				else {
					Write-Warning "Could not establish an SSH session to OVC Host $ipAddress `n" -ForegroundColor Red
					
				}	

					
			} else {
				Write-Host "Message: Can Not Get SVT Cluster Informations !!! `n" -ForegroundColor Red
				exit
			}
				
			
		}
	
	catch{}    
	
	finally
	{
		   
			Write-Host "Disconnect from vCenter Server`n" -ForegroundColor Yellow
			# Disconnect from vCenter Server
			Disconnect-VIServer -Server $vCenterServer -Force -Confirm:$false

			if($Error.Count -ne 0 )
			{
				Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
			}
			
			Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
	}
	
### End Function
}

#####

function Get-Update-Manager{
	
	# Define Report Date
	$reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"

	# Define the path to variable file
	$InfraVariableFile = ".\infra_variable.json"

	# Define the path to the credential file
	$credFile = ".\cred.XML"

	#Reports Directory
	$ReportDirPath= ".\Reports"

	#Log Timestamp
	$logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }
	
	# Check if the credential file already exists
	if (-Not (Test-Path $InfraVariableFile)) {
			do {
			Write-Host "`nPlease fill in the following information about customer..." -ForegroundColor Yellow
			
			# Define Customer Name / Enter the name of the person who administers the system.
			$customername  = Read-Host -Prompt 'Customer Name & Surname '
			
			# Define Customer Mail / # Define Custome Name / Enter the name of the person who administers the system.
			$customermail  = Read-Host -Prompt 'Customer E-Mail '
			
			# Define Company Name / Enter the company's name.
			$companyname  = Read-Host -Prompt 'Company Name '
			
			Write-Host "`nPlease fill in the following information about infrastructure..." -ForegroundColor Yellow
			# Define Vmwre vCenter Server Information
			$vcenterserver  = Read-Host -Prompt 'VMWare VCenter Server(ip) '

			Write-Host "`nCheck the following entries..."
			Write-Host "Customer Name:                '$customername' "
			Write-Host "Customer E-Mail:              '$customermail' "
			Write-Host "Company Name:                 '$companyname' "
			Write-Host "Vmware Virtual Center Server: '$vCenterServer' "
			
			# Prompt user for confirmation
			$confirmation = Read-Host -Prompt "`nDo you confirm the entered information? (Y/N)"
	 
			if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
					Write-Host "Information confirmed. Proceeding with the script..."
					break  
			} else {
					Write-Host "Confirmation not received. Please fill in the information again."
			
			}
			} while ($true)
			
				# Create a PowerShell custom object with the entered information
				$jsonData = [PSCustomObject]@{
					vCenterServer = $vcenterserver
					customername = $customername
					customermail = $customermail
					companyname = $companyname
				}

				# Convert the object to JSON format
				$jsonString = $jsonData | ConvertTo-Json
				
				# Write the JSON data to the file
				$jsonString | Set-Content -Path $InfraVariableFile
				
				Write-Host "Information has been saved to: $InfraVariableFile"

	} else {
		
		    Write-Host "The Infrastructure Variable file $InfraVariableFile already exists. No action taken.`n" -ForegroundColor Green
		   
			# Read the JSON content from the file
			$jsonInfraContent = Get-Content -Path $InfraVariableFile | Out-String | ConvertFrom-Json

			# Access the variables from the object
			$vcenterserver = $jsonInfraContent.vcenterserver
			$customername = $jsonInfraContent.customername
			$customermail = $jsonInfraContent.customermail
			$companyname = $jsonInfraContent.companyname
	}

	#Check if Reports Directory Exists
	if(!(Test-Path -Path $ReportDirPath))
	{
		#powershell create reports directory
		New-Item -ItemType Directory -Path $ReportDirPath
		Write-Host "New reports directory created successfully !`n" -f Green
	}
	else
	{
		Write-Host "Repors directory already exists! `n" -f Yellow
	}
	
	#Clear-Host
	
	try {
		
		 $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Status, CSName ,Caption, BuildNumber, TotalVisibleMemorySize
		 $totalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
		 $memoryInfo = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
		 
		 $UpdateManagerReportFile = "$($ReportDirPath)\$($osInfo.CSName)-$($logtimestamp).log"
		 
		 # Start a transcript log
		 Start-Transcript -Path $UpdateManagerReportFile 
						
		 Write-Host "`n#################################################################################################"
		 Write-Host "#        HPE Update Manager Host $($osInfo.CSName) System Requirements Check Report                "
		 Write-Host "#################################################################################################`n"

		 Write-Host "`nReport Creation Date: $($reportdate)" 
		 Write-Host "Customer Name:        $($customername)" 	
		 Write-Host "Customer E-Mail:      $($customermail)" 
		 Write-Host "Company Name:         $($companyname)`n" 
		 
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