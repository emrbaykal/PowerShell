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
	
	This script does take VMWare Virtual Center information.
    
.INPUTS
	Script asks VMWare Virtual center ip address , administrator user name and password to collect necessery informations. 

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 12/05/2023 
#>
Clear-Host

Write-Host "`n####################################################################"
Write-Host "#                     HPE Simplivity Pre-Upgrade Check              #"
Write-Host "####################################################################`n"

# Define Report Date
$reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"

# Define the path to variable file
$InfraVariableFile = ".\infra_variable.json"

# Define the path to the credential file
$credFile = ".\cred.XML"

#Reports Directory
$ReportDirPath= ".\Reports"

#Load HPESimpliVity , VMware.PowerCLI
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPESimpliVity") -or -not($ModuleNames -like "VMware.PowerCLI") )
{
    Write-Host "Loading module :  HPESimpliVity ,VMware.PowerCLIs "
    Import-Module HPESimpliVity, VMware.PowerCLI
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
	
}

else
{
	$InstalledSimplivityModule  =  Get-Module -Name "HPESimpliVity"
    $InstalledVmwareModule  =  Get-Module -Name "VMware.PowerCLI"
    Write-Host "HPESimpliVity Module Version : $($InstalledSimplivityModule.Version) , VMware Module Version : $($InstalledVmwareModule.Version) installed on your machine."
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

try
{
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference ="SilentlyContinue"

    #Login Vmware VCenter
	Write-Output "`nTrying to establish connection to the Vmware Virtual Center Server:"
    $VCenter_Connection = Connect-VIServer -Server $vCenterServer -Protocol https -Credential $Cred -Force
    $Error.Clear()
    if($VCenter_Connection -ne $null)
    {
       Write-Host "Connection established to target VCenter $($vCenterServer)`n" -ForegroundColor Green
            
     } else {
		 Write-Host "Connection could not be established to target VCenter $($vCenterServer) .`n" -ForegroundColor Red
		  exit;
	 }

    #Connect to the SimpliVity cluster
	# Initialize an array to store the Omnistack Virtual HostsIP addresses
	$OvcIpAddresses = @()

	$ovcvms = Get-VM | Where-Object { $_.Name -like "OmniStackVC*" }

    Write-Host "Omnistack Virtual Controller List:"
	foreach ($ovcvm in $ovcvms) {
		$ovc = Get-VMGuest -VM $ovcvm
		$ovcvmName = $ovcvm
		$ovchostname = $ovc.HostName
		$OvcMgmtIpAddress = $ovc.IPAddress | Select-Object -First 1

		Write-Host "OVC VM Name: $ovcvmName - Managemnt IP Addres: $OvcMgmtIpAddress" -ForegroundColor Yellow
		
		 # Add the IP address to the array
		$OvcMgmtIpAddresses += $OvcMgmtIpAddress
	}

    # Attempt to access each OVC IP address in the array
    foreach ($ipAddress in $OvcMgmtIpAddresses) {
    $svt_connection = Connect-Svt -ovc $ipAddress -Credential $Cred
    $Error.Clear()
	
	Write-Host "`nTrying to establish connection to the Omnistack Virtual Ceontroller:"
    # If successfully accessed, break out of the loop
    if ($svt_connection) {
        Write-Host "Connection established to target OVC Host $ipAddress `n" -ForegroundColor Green
        break
    }
    }

    if($svt_connection -eq $null)
    {
       Write-Host "`nConnection could not be established to target OVC Host.`n" -ForegroundColor Red
       exit;
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
				
		        #Create Report File
                $ReportFile = "$ReportDirPath\$($clusterstate.omnistack_clusters[$ClusterId].name)"
				if (Test-Path $ReportFile) {
				# If the report file exists, delete it
				Remove-Item -Path $ReportFile -Force
				}
				
				
				"####################################################################" | Out-File -Append -FilePath $ReportFile
				"#                     HPE Simplivity Pre-Upgrade Check             #" | Out-File -Append -FilePath $ReportFile
				"####################################################################`n" | Out-File -Append -FilePath $ReportFile
				Write-Host "Report Creation Date: $($reportdate)`n"
				"Report Creation Date: $($reportdate)" | Out-File -Append -FilePath $ReportFile
				"Customer Name:        $($customername)" | Out-File -Append -FilePath $ReportFile			
                "Customer E-Mail:      $($customermail)" | Out-File -Append -FilePath $ReportFile
				"Company Name:         $($companyname)`n" | Out-File -Append -FilePath $ReportFile
				
				Write-Host "`n--- VMWare Virtual Center  ---`n"
				"`n--- VMWare Virtual Center  ---`n" | Out-File -Append -FilePath $ReportFile
				# Get vCenter Server version
				$vCenterInfo = Get-ViServer $vcenterserver | Select-Object -Property Version, Build, Name
				
				Write-Host "vCenter Server Name:          $($vCenterInfo.Name)"
				"vCenter Server Name:          $($vCenterInfo.Name)" | Out-File -Append -FilePath $ReportFile
				Write-Host "vCenter Server Version:       $($vCenterInfo.Version)"
				"vCenter Server Version:       $($vCenterInfo.Version)" | Out-File -Append -FilePath $ReportFile
				Write-Host "vCenter Server Build Number : $($vCenterInfo.Build)"
				"vCenter Server Build Number : $($vCenterInfo.Build)" | Out-File -Append -FilePath $ReportFile
				
		        Write-Host "`n--- Cluster Requirements ---`n"
				"`n--- Cluster Requirements ---`n" | Out-File -Append -FilePath $ReportFile
				
		        Write-Host "### Cluster State ###`n" | Out-File -Append -FilePath $ReportFile
				"### Cluster State ###`n" | Out-File -Append -FilePath $ReportFile
				# Get VMWare Cluster State
				$vmwarecluster = Get-Cluster -Name $clusterstate.omnistack_clusters[$ClusterId].name
				
				Write-Host "Datacenter Name:                $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_object_parent_name)"
				"Datacenter Name:                $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_object_parent_name)" | Out-File -Append -FilePath $ReportFile
				Write-Host "Cluster Name:                   $($clusterstate.omnistack_clusters[$ClusterId].name)"
				"Cluster Name:                   $($clusterstate.omnistack_clusters[$ClusterId].name)" | Out-File -Append -FilePath $ReportFile
				Write-Host "Hypervisor Type:                $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_type)"
				"Hypervisor Type:                $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_type)" | Out-File -Append -FilePath $ReportFile 
				Write-Host "Management System:              $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_management_system_name)"
				"Management System:              $($clusterstate.omnistack_clusters[$ClusterId].hypervisor_management_system_name)" | Out-File -Append -FilePath $ReportFile	
				if ($clusterstate.omnistack_clusters[0].members.Count -lt 16) {
				        Write-Host "SVT Cluster Members Count:      $($clusterstate.omnistack_clusters[$ClusterId].members.Count)"
						"SVT Cluster Members Count:      $($clusterstate.omnistack_clusters[$ClusterId].members.Count)" | Out-File -Append -FilePath $ReportFile
              
		        } else {
				       Write-Host "SVT  Cluster Members Count:      $($clusterstate.omnistack_clusters[$ClusterId].members.Count)" -ForegroundColor Red
					   "SVT Cluster Members Count:      $($clusterstate.omnistack_clusters[$ClusterId].members.Count)" | Out-File -Append -FilePath $ReportFile 
					   $memberscount = 1
				}
				Write-Host "SVT Current Running Version:    $($clusterstate.omnistack_clusters[$ClusterId].version)"
				"SVT Current Running Version:    $($clusterstate.omnistack_clusters[$ClusterId].version)" | Out-File -Append -FilePath $ReportFile
                if ($clusterstate.omnistack_clusters[$ClusterId].upgrade_state -eq 'SUCCESS_COMMITTED') {
				        Write-Host "SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[$ClusterId].upgrade_state)"
						"SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[$ClusterId].upgrade_state)" | Out-File -Append -FilePath $ReportFile
              
		        } else {
				       Write-Host "SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[$ClusterId].upgrade_state)" -ForegroundColor Red
					   "SVT Cluster Ver. Upgrade State: $($clusterstate.omnistack_clusters[$ClusterId].upgrade_state)" | Out-File -Append -FilePath $ReportFile
					   $upgradestate = 1
				}				 
				Write-Host "SVT Time Zone:                  $($clusterstate.omnistack_clusters[$ClusterId].time_zone)"
                "SVT Time Zone:                  $($clusterstate.omnistack_clusters[$ClusterId].time_zone)" | Out-File -Append -FilePath $ReportFile
                if ($vmwarecluster.ExtensionData.Summary.OverallStatus -eq 'green') {
					Write-Host "VMWare CLs State:               HEALTHY"
                    "VMWare CLs State:               HEALTHY" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "VMWare CLs State:               WARRING" -ForegroundColor yellow
                    "VMWare CLs State:               WARRING" | Out-File -Append -FilePath $ReportFile
					$vmclsstate = 1
				}				
				Write-Host "VMWare CLs Num Hosts:           $($vmwarecluster.ExtensionData.Summary.NumHosts)"
                "VMWare CLs Num Hosts:           $($vmwarecluster.ExtensionData.Summary.NumHosts)" | Out-File -Append -FilePath $ReportFile
				Write-Host "VMWare Total VM:                $($vmwarecluster.ExtensionData.Summary.UsageSummary.TotalVmCount)"
                "VMWare Total VM                 $($vmwarecluster.ExtensionData.Summary.UsageSummary.TotalVmCount)" | Out-File -Append -FilePath $ReportFile
				Write-Host "VMWare PoweredOff VM:           $($vmwarecluster.ExtensionData.Summary.UsageSummary.PoweredOffVmCount)"
                "VMWare PoweredOff VM:           $($vmwarecluster.ExtensionData.Summary.UsageSummary.PoweredOffVmCount)" | Out-File -Append -FilePath $ReportFile
						
				Write-Host "`n### Cluster Arbiter State ###`n"
				"`n### Cluster Arbiter State ###`n" | Out-File -Append -FilePath $ReportFile
				
				Write-Host "Required Arbiter:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_required)"
				"Required Arbiter:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_required)" | Out-File -Append -FilePath $ReportFile
				
                if ($clusterstate.omnistack_clusters[$ClusterId].arbiter_required -eq 'true') {
						if ($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured -eq 'true') {
							  Write-Host "Arbiter Configured ?:               $($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured)"
							  "Arbiter Configured ?:               $($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured)" | Out-File -Append -FilePath $ReportFile
							  
							  if ($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected -eq 'true') {
							          Write-Host "Arbiter Conected ?:                 $($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected)"
									  "Arbiter Conected ?:                 $($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected)" | Out-File -Append -FilePath $ReportFile
									  Write-Host "Arbiter Address ?:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_address)"
									  "Arbiter Address ?:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_address)" | Out-File -Append -FilePath $ReportFile
								  else {
									 Write-Host "Arbiter Conected ?:                 $($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected)" -ForegroundColor Red
									 "Arbiter Conected ?:                 $($clusterstate.omnistack_clusters[$ClusterId].arbiter_connected)" | Out-File -Append -FilePath $ReportFile
							         $arbiterconnected = 1 
								  }
							  }
						} else {
							  Write-Host "Arbiter Configured ?:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured)" -ForegroundColor Red
							  "Arbiter Configured ?:                  $($clusterstate.omnistack_clusters[$ClusterId].arbiter_configured)" | Out-File -Append -FilePath $ReportFile
							  $arbiterconfigured = 1
						}
		        	
				}
				
				$pysical_space = $($clusterstate.omnistack_clusters[$ClusterId].allocated_capacity / 1TB).ToString("F2")
				$used_space = $($clusterstate.omnistack_clusters[$ClusterId].used_capacity / 1TB).ToString("F2")
				$free_space = $($clusterstate.omnistack_clusters[$ClusterId].free_space / 1TB).ToString("F2")
				$local_backup_space = $($clusterstate.omnistack_clusters[$ClusterId].local_backup_capacity / 1TB).ToString("F2")
				$percentFree = $(($clusterstate.omnistack_clusters[$ClusterId].free_space / $clusterstate.omnistack_clusters[0].allocated_capacity) * 100).ToString("F2")	
		
				
				Write-Host "`n### Cluster Storage State ###`n"
				"`n### Cluster Storage State ###`n" | Out-File -Append -FilePath $ReportFile
				Write-Host "HPE Simplivity Efficiency Ratio:   $($clusterstate.omnistack_clusters[0].efficiency_ratio)" 
				"HPE Simplivity Efficiency Ratio:   $($clusterstate.omnistack_clusters[0].efficiency_ratio)" | Out-File -Append -FilePath $ReportFile
				Write-Host "Pysical Space:                     $pysical_space TiB" 
				"Pysical Space:                     $pysical_space TiB" | Out-File -Append -FilePath $ReportFile
				Write-Host "Used Space:                        $used_space TiB"
				"Used Space:                        $used_space TiB" | Out-File -Append -FilePath $ReportFile
				Write-Host "Free Space:                        $free_space TiB"
				"Free Space:                        $free_space TiB" | Out-File -Append -FilePath $ReportFile
				if ($percentFree -ge 20) {
					Write-Host "Percentage Free Capacity:          $percentFree %"
					"Percentage Free Capacity:          $percentFree %" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "Percentage Free Capacity:          $percentFree %" -ForegroundColor Red
					"Percentage Free Capacity:           $percentFree %" | Out-File -Append -FilePath $ReportFile
					$storagefreestate = 1
				}
				Write-Host "Local Backup Capacity:             $local_backup_space TiB"
				"Local Backup Capacity:             $local_backup_space TiB" | Out-File -Append -FilePath $ReportFile
				
				Write-Host "`n### The Information Of Driven Virtual Machines. ###"
				"`n### The Information Of Driven Virtual Machines. ###" | Out-File -Append -FilePath $ReportFile
				
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
				$VMTable | Sort -Property 'VMHost', 'Power State', 'Memory (GB)' | Format-Table -Property 'VM Name', 'Power State', 'Overall Status', 'Config Status', 'CPU Count', 'Memory (GB)', 'Guest OS', 'VM Host' | Out-File -Append -FilePath $ReportFile
				
				Write-Host "`n### The Information Of VM Replicasets. ###"
				"`n### The Information Of VM Replicasets. ###" | Out-File -Append -FilePath $ReportFile
				
				# Get VM Replicaset State 
				$vmreplicaset = Get-SVTvmReplicaSet -ClusterName $clusterstate.omnistack_clusters[$ClusterId].name  | Select-Object  VmName, State,  HAStatus 
				$vmreplicasetdegreded = Get-SVTvmReplicaSet -ClusterName $clusterstate.omnistack_clusters[$ClusterId].name | Where-Object  HAStatus -eq  DEGRADED   |  Select-Object  VmName, State,  HAstatus
				$vmreplicaset | Format-Table -AutoSize 
				$vmreplicaset | Format-Table -AutoSize | Out-File -Append -FilePath $ReportFile
					
  
  
                if ($upgradestate -eq $null -and $memberscount -eq $null -and $arbiterconfigured -eq $null -and $arbiterconnected -eq $null -and $storagefreestate -eq $null -and $vmreplicasetdegreded.Count -eq 0 -and $vmclsstate -eq $null) {
				        Write-Host "`nMessage: The status of the cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) is consistent and you can continue to upgrade ...." -ForegroundColor Green
                        "`nMessage: The status of the cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) is consistent and you can continue to upgrade ...." | Out-File -Append -FilePath $ReportFile
		        } else {
					
					   Write-Host "`nMessage: SVT cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) status is not consistent and should fix error states !!! " -ForegroundColor Red
					   "`nMessage: SVT cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) status is not consistent and should fix error states !!! " | Out-File -Append -FilePath $ReportFile
					   
				       if ($upgradestate) {
						Write-Host "Error Message: Update status not in the expected state... "  -ForegroundColor Red
						"Error Message: Update status not in the expected state... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($memberscount) {
				        Write-Host "Error Message: Svt cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) is comprised of more than 16 HPE OmniStack hosts... "  -ForegroundColor Red
						"Error Message: Svt cluster ($($clusterstate.omnistack_clusters[$ClusterId].name)) is comprised of more than 16 HPE OmniStack hosts... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($arbiterconfigured) {
				        Write-Host "Error Message: Arbiter host configuration is required. It has not been configured... "  -ForegroundColor Red
						"Error Message: Arbiter host configuration is required. It has not been configured... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($arbiterconnected) {
				        Write-Host "Error Message: Arbiter host is configured, but not connected to the SVT cluster... "  -ForegroundColor Red
						"Error Message: Arbiter host is configured, but not connected to the SVT cluster... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($storagefreestate) {
				        Write-Host "Error Message: Free space is below the value required for upgrading... "  -ForegroundColor Red
						"Error Message: Free space is below the value required for upgrading... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($vmreplicasetdegreded.Count -ne 0) {
				        Write-Host "Error Message: Some Of virtual machines HA NOT COMPLIANT... "  -ForegroundColor Red
						"Error Message: Some Of virtual machines HA NOT COMPLIANT... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($vmclsstate) {
				        Write-Host "Error Message: There are some errors or warnings in the cluster, check cluster state... "  -ForegroundColor yellow
						"Error Message: There are some errors or warnings in the cluster, check cluster state... " | Out-File -Append -FilePath $ReportFile
                        }
				}	

	} else {
        Write-Host "Message: Can Not Get SVT Cluster Informations !!! `n" -ForegroundColor Red
		"Message: Can Not Get SVT Cluster Informations !!! `n" | Out-File -Append -FilePath $ReportFile
		exit
    }
	
	
	#######
	
	# Get SVT Host Status
	
	Write-Host "`n--- Host Requirements ---`n"
	"`n--- Host Requirements ---`n" | Out-File -Append -FilePath $ReportFile
	
	Write-Host "### SVT Host List ###"
	"### SVT Host List ###" | Out-File -Append -FilePath $ReportFile
	
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
	$HostTable | Sort -Property 'CpuUsage %', 'MemoryUsage %' | Format-Table -Property 'Name', 'ConnectionState', 'PowerState', 'OverallStatus', 'RebootRequired', 'NumCpu', 'CpuUsage %', 'MemoryUsage %', 'Version' | Format-Table -AutoSize | Out-File -Append -FilePath $ReportFile
	
	$hoststate = Get-SvtHost -ClusterName $clusterstate.omnistack_clusters[$ClusterId].name -Raw | ConvertFrom-Json
	
    if ($hoststate) {
		
			
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

				Write-Host "### SVT Host: $($svthost.name) ###`n"
				"### SVT Host: $($svthost.name) ###`n" | Out-File -Append -FilePath $ReportFile
				
				Write-Host "SVT Host Name:               $($svthost.name)"
				"SVT Host Name:               $($svthost.name)" | Out-File -Append -FilePath $ReportFile
				Write-Host "SVT Host IP:                 $($svthost.hypervisor_management_system)"
				"SVT Host IP:                 $($svthost.hypervisor_management_system)" | Out-File -Append -FilePath $ReportFile
				if ($svthost.state -eq 'ALIVE') {
					Write-Host "SVT Host State:              $($svthost.state)" | Out-File -Append -FilePath $ReportFile
					"SVT Host State:              $($svthost.state)" 
				}else {
					Write-Host "SVT Host State:              $($svthost.state)" -ForegroundColor Red
					"SVT Host State:              $($svthost.state)" | Out-File -Append -FilePath $ReportFile
					$hostconnectivity = 1
				}	
				Write-Host "SVT Host Model:              $($svthost.model)"
				"SVT Host Model:              $($svthost.model)" | Out-File -Append -FilePath $ReportFile
				if ($svthost.version -eq $clusterstate.omnistack_clusters[$ClusterId].version) {
					Write-Host "SVT Host Version:           $($svthost.version)"
					"SVT Host Version:            $($svthost.version)" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "SVT Host Version:            $($svthost.version)" -ForegroundColor Red
					"SVT Host Version:            $($svthost.version)" | Out-File -Append -FilePath $ReportFile
					$hostversion = 1
				}
				if ($svthost.upgrade_state -eq 'SUCCESS') {
					Write-Host "SVT Upgrade State:           $($svthost.upgrade_state)"
					"SVT Upgrade State:           $($svthost.upgrade_state)" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "SVT Upgrade State:           $($svthost.upgrade_state)" -ForegroundColor Red
					"SVT Upgrade State:           $($svthost.upgrade_state)" | Out-File -Append -FilePath $ReportFile
					$hostupgradestate = 1
				}
				Write-Host "SVT Host ESXI Image Version: $($esxihost.Version)"
				"SVT Host ESXI Image Version: $($esxihost.Version)" | Out-File -Append -FilePath $ReportFile
				Write-Host "SVT Host ESXI Build:         $($esxihost.Build)"
				"SVT Host ESXI Build:         $($esxihost.Build)" | Out-File -Append -FilePath $ReportFile
				Write-Host "SVT Host CPU Total MHz:      $($esxihost.CpuTotalMhz)"
				"SVT Host CPU Total MHz:      $($esxihost.CpuTotalMhz)" | Out-File -Append -FilePath $ReportFile
				if ($percentCpu -le 85) {
					Write-Host "SVT Host CPU Usage :         $percentCpu %"
					"SVT Host CPU Usage :         $percentCpu %" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "SVT Host CPU Usage :         $percentCpu %" -ForegroundColor yellow
					"SVT Host CPU Usage :         $percentCpu %" | Out-File -Append -FilePath $ReportFile
					$cpuusage = 1
				}
				Write-Host "SVT Host Memory GB:          $($esxihost.MemoryTotalGB.ToString("F0"))"
				"SVT Host Memory GB:          $($esxihost.MemoryTotalGB.ToString("F0"))" | Out-File -Append -FilePath $ReportFile
				if ($percentMem -le 85) {
					Write-Host "SVT Host Memory Usage :      $percentMem %"
					"SVT Host Memory Usage :      $percentMem %" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "SVT Host Memory Usage :      $percentMem %" -ForegroundColor yellow
					"SVT Host Memory Usage :      $percentMem %" | Out-File -Append -FilePath $ReportFile
					$memusage = 1
				}
				
				#####
				
                
                Write-Host "`n# SVT Host $($svthost.name) Hardware State: `n"
				"`n# SVT Host $($svthost.name) Hardware State: `n" | Out-File -Append -FilePath $ReportFile
                $hosthwinfo = Get-SvtHardware -Hostname $svthost.name -Raw | ConvertFrom-Json
				
				Write-Host "Model Number:                $($hosthwinfo.host.model_number)"
				"Model Number:                $($hosthwinfo.host.model_number)" | Out-File -Append -FilePath $ReportFile
				Write-Host "Serial Number:               $($hosthwinfo.host.serial_number)"
				"Serial Number:               $($hosthwinfo.host.serial_number)" | Out-File -Append -FilePath $ReportFile
				Write-Host "Firmware Revision:           $($hosthwinfo.host.firmware_revision)"
				"Firmware Revision:           $($hosthwinfo.host.firmware_revision)" | Out-File -Append -FilePath $ReportFile
				if ($hosthwinfo.host.status -eq 'GREEN') {
					Write-Host "Hardware Status:             HEALTHY"
					"Hardware Status:             HEALTHY" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "Hardware Status:             FAULTY" -ForegroundColor Red
					"Hardware Status:             FAULTY" | Out-File -Append -FilePath $ReportFile
					$hwstate = 1
				}
				Write-Host "Raid Card Product Name:      $($hosthwinfo.host.raid_card.product_name)"
				"Raid Card Product Name:      $($hosthwinfo.host.raid_card.product_name)" | Out-File -Append -FilePath $ReportFile
				Write-Host "Raid Card Firmware Revision: $($hosthwinfo.host.raid_card.firmware_revision)" 
				"Raid Card Firmware Revision: $($hosthwinfo.host.raid_card.firmware_revision)" | Out-File -Append -FilePath $ReportFile
				if ($($hosthwinfo.host.status) -eq 'GREEN') {
					Write-Host "Raid Card Status:            HEALTHY"
					"Raid Card Status:            HEALTHY" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "Raid Card Status:            FAULTY" -ForegroundColor Red
					"Raid Card Status:            FAULTY" | Out-File -Append -FilePath $ReportFile
					$raidhwstate = 1
				}
				if ($($hosthwinfo.host.status) -eq 'GREEN') {
					Write-Host "Raid Card Battery Status:    HEALTHY"
					"Raid Card Battery Status:    HEALTHY" | Out-File -Append -FilePath $ReportFile
				}else {
					Write-Host "Raid Card Battery Status:    FAULTY" -ForegroundColor Red
					"Raid Card Battery Status:    FAULTY" | Out-File -Append -FilePath $ReportFile
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
				
				Write-Host "`n# SVT Host $($svthost.name) Disk State: "
				"`n# SVT Host $($svthost.name) Disk State: " | Out-File -Append -FilePath $ReportFile
				$diskTable | Format-Table -AutoSize
				$diskTable | Format-Table -AutoSize | Out-File -Append -FilePath $ReportFile

			
                if ($hostconnectivity -eq $null -and $hostupgradestate -eq $null -and $hostdisktstate -eq $null -and $hostversion -eq $null -and $hwstate -eq $null -and $raidhwstate -eq $null -and $raidbatteryhwstate -eq $null -and $cpuusage -eq $null -and $memusage -eq $null) {
				        Write-Host "Message: The status of the SVT Host ( $($svthost.name) ) is consistent and you can continue to upgrade ...." -ForegroundColor Green
						"Message: The status of the SVT Host ( $($svthost.name) ) is consistent and you can continue to upgrade ...." | Out-File -Append -FilePath $ReportFile
              
		        } else {
					
					   Write-Host "Message: SVT Host ( $($svthost.name) status is not consistent and should fix error states !!! " -ForegroundColor Red
					   "Message: SVT Host ( $($svthost.name) status is not consistent and should fix error states !!! " | Out-File -Append -FilePath $ReportFile
					   
				       if ($hostconnectivity) {
						Write-Host "Error Message: SVT Host ( $($svthost.name) State Not Alive "  -ForegroundColor Red
						"Error Message: SVT Host ( $($svthost.name) State Not Alive " | Out-File -Append -FilePath $ReportFile
                        }
						if ($hostupgradestate) {
				        Write-Host "Error Message: SVT Host ( $($svthost.name) Update status not in the expected state... "  -ForegroundColor Red
						"Error Message: SVT Host ( $($svthost.name) Update status not in the expected state... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($hostdisktstate) {
				        Write-Host "Error Message: Detection of faulty discs on the SVT host ( $($svthost.name) , opening of a support case... "  -ForegroundColor Red
						"Error Message: Detection of faulty discs on the SVT host ( $($svthost.name) , opening of a support case... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($hostversion) {
				        Write-Host "Error Message: Incompatible software version actively running on SVT host ( $($svthost.name)  ... "  -ForegroundColor Red
						"Error Message: Incompatible software version actively running on SVT host ( $($svthost.name)  ... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($hwstate) {
				        Write-Host "Error Message: Detection of faulty hardware component on the SVT host ( $($svthost.name) , opening of a support case... "  -ForegroundColor Red
						"Error Message: Detection of faulty hardware component on the SVT host ( $($svthost.name) , opening of a support case... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($raidhwstate) {
				        Write-Host "Error Message: Detection of faulty raid card on the SVT host ( $($svthost.name) , opening of a support case... "  -ForegroundColor Red
						"Error Message: Detection of faulty raid card on the SVT host ( $($svthost.name) , opening of a support case... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($raidbatteryhwstate) {
				        Write-Host "Error Message: Detection of faulty raid card battery on the SVT host ( $($svthost.name) , opening of a support case... "  -ForegroundColor Red
						"Error Message: Detection of faulty raid card battery on the SVT host ( $($svthost.name) , opening of a support case... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($cpuusage) {
				        Write-Host "Error Message: High CPU usage detected on the SVT host ( $($svthost.name) ... "  -ForegroundColor yellow
						"Error Message: High CPU usage detected on the SVT host ( $($svthost.name) ... " | Out-File -Append -FilePath $ReportFile
                        }
						if ($memusage) {
				        Write-Host "Error Message: High Memory usage detected on the SVT host ( $($svthost.name) ... "  -ForegroundColor yellow
						"Error Message: High Memory usage detected on the SVT host ( $($svthost.name) ... " | Out-File -Append -FilePath $ReportFile
                        }
				}	

			    Write-Host "`n---`n"
				"`n---`n" | Out-File -Append -FilePath $ReportFile
			}
				
	}else {
		  Write-Host "Message: Can Not Get Host Informations !!! `n" -ForegroundColor Red
		  "Message: Can Not Get Host Informations !!! `n" | Out-File -Append -FilePath $ReportFile
		  exit
	}
	
	#####
	
	 Write-Host "--- Update Manager System Requirements ---"
	 "`n--- Update Manager System Requirements ---" | Out-File -Append -FilePath $ReportFile
	 Write-Host "`n1-Operating System Information:"
	 "`n1-Operating System Information:" | Out-File -Append -FilePath $ReportFile
	 $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Status, CSName ,Caption, BuildNumber, TotalVisibleMemorySize
	 $totalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
	 $memoryInfo = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
	 
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
		$osTable | Format-Table -AutoSize | Out-File -Append -FilePath $ReportFile
		
		# Check if OS version 
		$osbuild = $osInfo.BuildNumber 
		
		if ($osBuild -in '6003', '7601', '9200', '9600', '14393', '16299', '17134', '17763', '18362', '18363', '19041', '19042', '20348' -and $($memoryInfo.Sum / 1GB) -ge '14' -and $totalCores -ge '2' ) {
            Write-Host "Message: Supported Operating System Resources & Version found.. `n" -ForegroundColor Green
			"Message: Supported Operating System Resources & Version found.. `n" | Out-File -Append -FilePath $ReportFile
        } else {
            Write-Host "Message: Unsupported Operating System Resources & Version found!!! `n" -ForegroundColor Red
			"Message: Unsupported Operating System Resources & Version found!!! `n" | Out-File -Append -FilePath $ReportFile
        }
    }
	 
	 
	 Write-Host "`n2-Installed Java Information:"
	 "`n2-Installed Java Information:" | Out-File -Append -FilePath $ReportFile
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
		$javaTable | Format-Table -AutoSize | Out-File -Append -FilePath $ReportFile
		
		# Check if Java version is 8
		
        $javaVersion = $javaInfo | Where-Object { $_.Version -ge '8.0' -and $_.Version -lt '9.0' }
		
		if ($javaVersion) {
            Write-Host "Message: Supported Java version found.. `n" -ForegroundColor Green
			"Message: Supported Java version found.. `n" | Out-File -Append -FilePath $ReportFile
        } else {
            Write-Host "Message: Unsupported Java version found !!! `n" -ForegroundColor Red
			"Message: Unsupported Java version found !!! `n" | Out-File -Append -FilePath $ReportFile
        }
    } else {
        Write-Host "Message: No Java installation found !!! `n" -ForegroundColor Red
		"Message: No Java installation found !!! `n" | Out-File -Append -FilePath $ReportFile
    }

	 Write-Host "`n3-Installed Microsoft .NET Framework Information:"
	 "`n3-Installed Microsoft .NET Framework Information:" | Out-File -Append -FilePath $ReportFile
	 
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
		$AspNetTable | Format-Table -AutoSize | Out-File -Append -FilePath $ReportFile
		
		# Check if Microsoft .NET Framework is older then 4.7.x
		
        $AspNetVersion = $AspNetInfo | Where-Object { $_.Version -ge '4.7' }
		
		if ($AspNetVersion) {
            Write-Host "Message: Supported Microsoft .NET Framework version found.. `n" -ForegroundColor Green
			"Message: Supported Microsoft .NET Framework version found.. `n" | Out-File -Append -FilePath $ReportFile
        } else {
            Write-Host "Message: Unsupported Microsoft .NET Framework version found !!! `n" -ForegroundColor Red
			"Message: Unsupported Microsoft .NET Framework version found !!! `n" | Out-File -Append -FilePath $ReportFile
        }
    } else {
        Write-Host "Message: No Microsoft .NET Framework installation found !!! `n" -ForegroundColor Red
		"Message: No Microsoft .NET Framework installation found !!! `n" | Out-File -Append -FilePath $ReportFile
    }

}
catch
{
}    
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
	"`n****** Script execution completed ******" | Out-File -Append -FilePath $ReportFile
}