####################################################################
#HPE Simplivity Factory Reset                                      #
####################################################################

<#
.Synopsis
    This Script allows factory Reset simplivity servers.

.DESCRIPTION
    This Script allowsfactory Reset simplivity servers.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Find-HPEiLO, Connect-HPEiLO, Get-HPEiLOServerInfo, Disconnect-HPEiLO, Mount-HPEiLOVirtualMedia, Set-HPEiLOOneTimeBootOption, Reset-HPEiLO

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\simplivity-factory-reset.ps1
	
	This script does not take any parameter and gets the server information for the given target iLO's.
    
.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv4 address, iLO Username and iLO Password.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 10/28/2023 
#>

#Reports Directory
$ReportDirPath= ".\Reports"

# Define Report Date
$reportdate = get-date -Format "dddd dd/MM/yyyy HH:mm"

#Log Timestamp
$logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12

try
{
    $path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\iLOInput.csv"
    $inputcsv = Import-Csv $path
	if($inputcsv.IP.count -eq $inputcsv.Username.count -eq $inputcsv.Password.count -eq  $inputcsv.OmniStack_Host -eq 0)
	{
		Write-Host "Provide values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}

    $notNullIP = $inputcsv.IP | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullUsername = $inputcsv.Username | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullPassword = $inputcsv.Password | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
	$notNullOmniStack_Host = $inputcsv.OmniStack_Host | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
	
	if(-Not($notNullIP.Count -eq $notNullUsername.Count -eq $notNullPassword.Count -eq $notNullOmniStack_Host.Count))
	{
        Write-Host "Provide equal number of values for IP, Username ,Password  and OS IP columns in the iLOInput.csv file and try again."
        exit
	}
}
catch
{
    Write-Host "iLOInput.csv file import failed. Please check the file path of the iLOInput.csv file and try again."
    Write-Host "iLOInput.csv file path: $path"
    exit
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

Clear-Host


Write-Host "`n####################################################################"
Write-Host "#                     HPE Simplivity Factory Reset                 #"
Write-Host "####################################################################`n"

#Load HPESimpliVity , VMware.PowerCLI and HPEiLOCmdlets modules
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPESimpliVity") -or -not($ModuleNames -like "VMware.PowerCLI") -or -not($ModuleNames -like "HPEiLOCmdlets") )
{
    Write-Host "Loading module :  HPESimpliVity ,VMware.PowerCLIs and HPEiLOCmdlets"
    Import-Module HPESimpliVity, VMware.PowerCLI, HPEiLOCmdlets	
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
	
	if(($(Get-Module -Name "HPEiLOCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEiLOCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}

else
{
	$InstalledSimplivityModule  =  Get-Module -Name "HPESimpliVity"
    $InstalledVmwareModule  =  Get-Module -Name "VMware.PowerCLI"
	$InstalledHPEiLOCmdletsModule  =  Get-Module -Name "HPEiLOCmdlets"
    Write-Host "HPESimpliVity Module Version : $($InstalledSimplivityModule.Version) , VMware Module Version : $($InstalledVmwareModule.Version) and VMware Module Version : $($HPEiLOCmdlets) installed on your machine."
    Write-host ""
}

$Error.Clear()


if($Error.Count -ne 0)
{ 
	Write-Host "`nPlease launch the PowerShell in administrator mode and run the script again." -ForegroundColor Yellow 
	Write-Host "`n****** Script execution terminated ******" -ForegroundColor Red 
	exit 
}	

# Define the path to variable file
$InfraVariableFile = ".\infra_variable.json"

# Check if the credential file already exists
if (-Not (Test-Path $InfraVariableFile)) {
		do {
		Write-Host "`nPlease fill in the following information about the infrastructure..." -ForegroundColor Yellow
		
		# Define vCenter Server & OVC Host Infortmations
		$vCenterServer  = Read-Host -Prompt 'VMWare VCenter Server '
		$svtmasterhost = Read-Host -Prompt 'OVC Master Host '

		# Define the CD/DVD image URL
		$cdImagefw = Read-Host -Prompt 'SVT Host Firmware Image '
		$usbtinyimg = Read-Host -Prompt 'SVT Host Thiny Image '

		Write-Host "`nCheck the following entries..."
		Write-Host "Vmware Virtual Center Server: '$vCenterServer' "
		Write-Host "OVC Master Host:  '$svtmasterhost' "
		Write-Host "SVT Fimware Image:  '$cdImagefw' "
		Write-Host "SVT Thiny Image: '$usbtinyimg'  "
		
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
			VCenterServer = $vCenterServer
			OvcMasterHost = $svtmasterhost
			SvtHostFirmwareImage = $cdImagefw
			SvtHostThinyImage = $usbtinyimg
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
		$vCenterServer = $jsonInfraContent.VCenterServer
		$svtmasterhost = $jsonInfraContent.OvcMasterHost
		$cdImagefw = $jsonInfraContent.SvtHostFirmwareImage
		$usbtinyimg = $jsonInfraContent.SvtHostThinyImage
}

# Define the path to the credential file
$credFile = ".\cred.XML"

# Check if the credential file already exists
if (-Not (Test-Path $credFile)) {
# Prompt the user for credentials
$Cred = Get-Credential -Message 'Enter VMWare VCenter Server Credential' -Username 'administrator@vsphere.local' | Export-Clixml .\cred.XML

Write-Host "Credentials saved to $credFile."
} else {
       Write-Host "The credential file $credFile already exists. No action taken.`n" -ForegroundColor Green
}

$Cred = Import-CLIXML .\cred.XML

try
{
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference ="SilentlyContinue"
	

    $reachableIPList = Find-HPEiLO $inputcsv.IP -WarningAction SilentlyContinue
    Write-Host "The below list of ILO IP's are reachable...`n"
    $reachableIPList.IP

    #Login Vmware VCenter
    $VCenter_Connection = Connect-VIServer -Server $vCenterServer -Protocol https -Credential $Cred -Force
    $Error.Clear()
    if($VCenter_Connection -eq $null)
    {
       Write-Host "`nConnection could not be established to target VCenter.`n" -ForegroundColor Red
            
            exit;
     }

    #Connect to the SimpliVity cluster
    $svt_connection = Connect-Svt -ovc $svtmasterhost -Credential $Cred
    $Error.Clear()
    if($svt_connection -eq $null)
    {
       Write-Host "`nConnection could not be established to target SVT Host.`n" -ForegroundColor Red
            
            exit;
     }

            foreach($ip in $reachableIPList.IP)
            {
              $index = $inputcsv.IP.IndexOf($ip)
              $inputObject = New-Object System.Object

              $HostReportFile = "$($ReportDirPath)\$($ip)-host-report-$($logtimestamp).log"
			  
			  # Get the status of SVT Hosts
              $OvcHostStatus = Get-SvtHost  | Where-Object HostName -eq $inputcsv[$index].OmniStack_Host | Select-Object HostName, State, DataCenterName, ClusterName, ManagementIP, FederationIP, FreeSpaceGB

			  # Get the status of the ESXi host
              $SvtHostStatus = Get-VMHost -Name $inputcsv[$index].OmniStack_Host  | Select-Object Name, ConnectionState, PowerState
              
              # Start a transcript log
			  Start-Transcript -Path $HostReportFile 

              Write-Host "`n-------------------------- The status of the ESXi host $inputcsv[$index].OmniStack_Host --------------------------------" 

			  
			  if($SvtHostStatus -ne $null)
			  {	
					$SvtHostStatus | fl 
					$SvtHostStatus | fl | Out-File -Append -FilePath $outputFilePath
					
					Write-Host "`n-------------------------- The List of Virtual Switches to the ESXi host. -------------------------------"
				    # Get Vswitch Information of the ESXi host
				    $virtualSwitches = Get-VirtualSwitch -VMHost $inputcsv[$index].OmniStack_Host | Select-Object Name, VMHost, MTU, NumPortsAvailable, Nic 

				    $virtualSwitches | Format-Table -AutoSize 
					$virtualSwitches | Format-Table -AutoSize | Out-File -Append -FilePath $outputFilePath

				    Write-Host "`n-------------------------- The List of Network Adapters to the ESXi host. -------------------------------"
				    # Get Network Adapters of the ESXi host
				    $networkAdapters = Get-VMHostNetworkAdapter -VMHost $inputcsv[$index].OmniStack_Host | Select-Object Name, Mac, DeviceName

				    $networkAdapters | Format-Table -AutoSize 
					$networkAdapters | Format-Table -AutoSize | Out-File -Append -FilePath $outputFilePath

				    Write-Host "`n-------------------------- The List of Virtual Port Groups to the ESXi host. -------------------------------"
				    # Get Virtual Port Groups of the ESXi host
				    $virtualportgroup = Get-VirtualPortGroup -VMHost $inputcsv[$index].OmniStack_Host | Select-Object Name, VirtualSwitch, VLanId, VirtualSwitchName | Format-Table -AutoSize

				    $virtualportgroup | Format-Table -AutoSize 
					$virtualportgroup | Format-Table -AutoSize | Out-File -Append -FilePath $outputFilePath

				    Write-Host "`n-------------------------- The Information Of VM Host Network to the ESXi host. -------------------------------"
				    # Get VMHost Network Informations of the ESXi host
				    $vmhostnetwork = Get-VMHostNetwork -VMHost $inputcsv[$index].OmniStack_Host | Select-Object VMHost, VMKernelGateway, DnsAddress ,HostName ,DomainName

				    $vmhostnetwork | fl 
					$vmhostnetwork | fl | Out-File -Append -FilePath $outputFilePath
					
           
			  } else {
				
					Write-Host "`nDefined SVT Host ( $inputcsv[$index].OmniStack_Host ) Not Found to the VMware Datacenter.. `n" -ForegroundColor Yellow
			  }
               
              Write-Host "`n-------------------------- The status of the OVC Host. --------------------------------"

			  
              if($OvcHostStatus -ne $null)
			  {	
					$OvcHostStatus | Format-Table -AutoSize 
					$OvcHostStatus | Format-Table -AutoSize | Out-File -Append -FilePath $outputFilePath
					
					Write-Host "`n-------------------------- The Information Of VM Replicasets. -------------------------------"
				    # Get VM Replicaset State 
				    $vmreplicaset = Get-SVTvmReplicaSet   | Select-Object  VmName, State,  HAstatus 
				    $vmreplicasetdegreded = Get-SVTvmReplicaSet   | Where-Object  HAstatus -eq  DEGRADED   |  Select-Object  VmName, State,  HAstatus
					
				    $vmreplicaset | Format-Table -AutoSize 
					$vmreplicaset | Format-Table -AutoSize | Out-File -Append -FilePath $outputFilePath
				
           
			  } else {
				
					Write-Host "`nDefined OVC Host Not Found to the Simplivity Federation.. `n" -ForegroundColor Yellow
					$vmreplicasetdegreded = $null
			  }
###           
              Stop-Transcript

              $Error.Clear()

              if ($vmreplicasetdegreded.Count -eq 0) {

                          # Prompt the user for confirmation
                          $confirmation = Read-Host "Do you want to proceed with the factory reset of the SVT host to $($inputcsv[$index].OmniStack_Host) ? (Type 'y' for Yes, 'n' for No)"

                          if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {

                                  if ($SvtHostStatus.State -eq "ALIVE") {

                                        Write-Host "SVT Host is  alive.`n " -ForegroundColor Green

                                        Write-Host "Removing SVT Host $($inputcsv[$index].OmniStack_Host) to the Simplivity Cluster...`n"
                                        Remove-SvtHost -HostName $inputcsv[$index].OmniStack_Host -Confirm:$false


                                   } else {
                                     Write-Host "`nSVT Host is not alive, We can procceed factory reset process... `n " -ForegroundColor Yellow
                                     }


                                  if ($HostStatus.PowerState -eq "PoweredOn" -and $HostStatus.ConnectionState -eq "Connected") {

                                      $PoweredOnVMs = Get-VMHost -Name $inputcsv[$index].OmniStack_Host | Get-VM | Where-Object { $_.PowerState -eq "PoweredOn" }

                                      Write-Host "Powered on VMs on Host.`n"
                                      $PoweredOnVMs 

                                        if ($PoweredOnVMs.Count -gt 0) {

                                           # Power off all powered-on VMs
                                           Write-Host "Powering off all powered-on VMs.`n "
                                           $PoweredOnVMs | Stop-VM -Kill -Confirm:$false
        
                                          Write-Host "All powered-on VMs on the host have been powered off.`n" -ForegroundColor Yellow
                                         }

                                         Write-Host "Putting host $($inputcsv[$index].OmniStack_Host) into maintenance mode...`n"
                                         Set-VMHost -VMHost $inputcsv[$index].OmniStack_Host -State Maintenance -Confirm:$false
                                         Write-Host "Host is now in maintenance mode.`n" -ForegroundColor Yellow

                                         # Remove the host from the cluster
                                         Write-Host "Removing host $($inputcsv[$index].OmniStack_Host) from the cluster $ClusterName...`n"
                                         Remove-VMHost -VMHost $inputcsv[$index].OmniStack_Host -Confirm:$false
                                         Write-Host "Host has been removed from the cluster.`n"

                                 } else {
                                     Write-Host "The SVT host is not powered on and/or not connected to the VMWare VCenter, We can procceed factory reset process... `n " -ForegroundColor Yellow
                                   }

                                #######################
	
                                   $ilopassword = $inputcsv[$index].Password 
                                   $ilousername = $inputcsv[$index].Username
                                   $pair = "{0}:{1}" -f ($ilousername, $ilopassword)
                                   $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
                                   $token = [System.Convert]::ToBase64String($bytes)

                                   $headers = @{
                                               Authorization = "Basic {0}" -f ($token)
                                               "Content-Type"="application/json"
                                               }


                                   $bodyclean = @{  
                                      "LogicalDrives" = @()
                                      "DataGuard" = "Disabled"
                       
                                    }
                                   
                                    
                                   $bodyPoweredON = @{  
                                      "ResetType" = "ForceRestart"
                                   }

                                   $biosconf = @{
                                      "WorkloadProfile" = "Virtualization-MaxPerformance"  
                                      "AsrStatus" = "Enabled"
                                      "AsrTimeoutMinutes" = "Timeout10"
                                      "AssetTagProtection" = "Locked"
                                      "CustomPostMessage" = "SimpliVity 380 Gen10"
                                      "BootOrderPolicy" = "AttemptOnce"
                                      "NumaGroupSizeOpt" = "Clustered"



                                   }
                                 
                                   $osarray = Get-Content ".\array.json" 
								   
								   $fwmedia =  @{  
                                      "Image" = "$cdImagefw"
									  "Action" = "HpeİLOVirtualMedia.InsertVirtualMedia"
                                   }
								   
								   $thinyimagemedia = @{  
                                      "Image" = "$usbtinyimg"
									  "Action" = "HpeİLOVirtualMedia.InsertVirtualMedia"
                                   }

                                  function InPost {
										  Write-Host "Wait For Firmware Upgrade Process Done..."					  
                                          while ($true) {
                                          # Make the REST API call
                                          $poststate = Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/ -Method GET -Headers $headers 
                                          $response = $poststate.Oem.Hpe.PostState

                                               switch ($response) {
                                                    "InPost" {
                                                        Write-Host "Firmware Upgrade Process Has been done. Proceeding to the next step... "
                                                        return  # Exit the loop in case of an unknown state
                                                    }
                                                    "InPostDiscoveryComplete" {
                                                        Start-Sleep -Seconds 5
                                                        # Continue checking the boot state
                                                        continue
                                                    }
                                                    "FinishedPost" {
                                                        Start-Sleep -Seconds 5
                                                        # Continue checking the boot state
                                                        continue
                                                        
                                                    }
                                                }

                                          }
                                  }

                                  function PostDiscoveryComplete {
									      
										  Write-Host "Wait For Boot Post Discovery Complete Process Done..."
                                          while ($true) {
                                          # Make the REST API call
                                          $poststate = Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/  -Method GET -Headers $headers 
                                          $response = $poststate.Oem.Hpe.PostState

                                               switch ($response) {
                                                    "InPost" {
                                                        Start-Sleep -Seconds 5
                                                        continue
                                                    }
                                                    "InPostDiscoveryComplete" {
                                                        Write-Host "Boot state is InPostDiscoveryComplete. Proceeding to the next step..."
                                                        return  # Exit the loop once the desired state is reached
                                                    }
                                                    "FinishedPost" {
                                                        Start-Sleep -Seconds 5
                                                        continue
                                                    }
                                                }

                                          }
                                  }

                                  function FinishedPost {
									  
										  Write-Host "Wait For Boot Finished Post Process Done..."
                                          while ($true) {
                                          # Make the REST API call
                                          $poststate = Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/  -Method GET -Headers $headers 
                                          $response = $poststate.Oem.Hpe.PostState

                                               switch ($response) {
                                                    "InPost" {
                                                        Start-Sleep -Seconds 5
                                                        # Continue checking the boot state
                                                        continue
                                                    }
                                                    "InPostDiscoveryComplete" {
                                                        Start-Sleep -Seconds 5
                                                        # Continue checking the boot state
                                                        continue
                                                    }
                                                    "FinishedPost" {
                                                        Write-Host "Boot state is FinishedPost. Proceeding to the next step..."
                                                        return  # Exit the loop in case of an unknown state
                                                    }
                                                }

                                          }
                                  }


                                try {
										Write-Host "`nReset OS Raid Config ."
										Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/smartstorageconfig/settings/  -Method PUT -Headers $headers -Body ($bodyclean | ConvertTo-Json) >$null 2>&1
										Start-Sleep -Seconds 10
										Write-host " Reset Operating System Raid Configuration has been successfully." -ForeGroundColor GREEN
								 } catch {
									    Write-Host "`nReset OS Raid Config Rest Call Failed !!" -ForeGroundColor Red
									    Write-Host "Status Message:" $_.Exception.Message.ToString() -ForeGroundColor Red
										Write-host ""
										exit;
								 }

								 try {
										Write-Host "`nPower Reset !! ."
										Invoke-RestMethod -Uri https://$ip/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/  -Method POST -Headers $headers -Body ($bodyPoweredON | ConvertTo-Json) >$null 2>&1
										Start-Sleep -Seconds 5
										Write-host "Power Reset Succeeded.." -ForeGroundColor GREEN
										Write-host ""
								 } catch {
									    Write-Host "`nPower Reset Call Failed !!" -ForeGroundColor Red
									    Write-Host "Status Message:" $_.Exception.Message.ToString() -ForeGroundColor Red
										Write-host ""
										exit;
								 }

                               #Call the function to check server boot state
                                 PostDiscoveryComplete
                                 Start-Sleep -Seconds 10


								 try {
										Write-Host "`nCreate OS Raid Config ."
                                        Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/smartstorageconfig/settings/  -Method PUT -Headers $headers -Body (Get-Content .\array.json) >$null 2>&1
                                        Start-Sleep -Seconds 10
										Write-host "Create New  Operating System Raid Configuration has been successfully..." -ForeGroundColor GREEN
								 } catch {
									    Write-Host "`nCreate OS Raid Config Rest Call Failed !!" -ForeGroundColor Red
									    Write-Host "Status Message:" $_.Exception.Message.ToString() -ForeGroundColor Red
										Write-host ""
										exit;
								 }
								 
                                 
                                 try {
										Write-Host "`nPower Reset !! ."
										Invoke-RestMethod -Uri https://$ip/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/  -Method POST -Headers $headers -Body ($bodyPoweredON | ConvertTo-Json) >$null 2>&1
										Start-Sleep -Seconds 5
										Write-host "Power Reset Succeeded.." -ForeGroundColor GREEN
										Write-host ""
								 } catch {
									    Write-Host "`nPower Reset Call Failed !!" -ForeGroundColor Red
									    Write-Host "Status Message:" $_.Exception.Message.ToString() -ForeGroundColor Red
										Write-host ""
										exit;
								 }

                                # Call the function to check server boot state
                                PostDiscoveryComplete
                                Start-Sleep -Seconds 10
								
								 try {
										Write-Host "`nMount the CD/DVD image to ILO $ip"
                                        Invoke-RestMethod -Uri https://$ip/redfish/v1/Managers/1/VirtualMedia/2/Actions/Oem/Hpe/HpeiLOVirtualMedia.InsertVirtualMedia/  -Method POST -Headers $headers -Body ($fwmedia | ConvertTo-Json) >$null 2>&1
                                        Start-Sleep -Seconds 5
										Write-host "Mount Firmware CD/DVD Image Succeeded." -ForeGroundColor GREEN
										
										Write-Host "`nPower Reset !! ."
										Invoke-RestMethod -Uri https://$ip/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/  -Method POST -Headers $headers -Body ($bodyPoweredON | ConvertTo-Json) >$null 2>&1
										Start-Sleep -Seconds 5
										Write-host "Power Reset Succeeded.." -ForeGroundColor GREEN
										Write-host ""
										
										# Call the function to check server boot state
										 FinishedPost
										 Start-Sleep -Seconds 5

										# Call the function to check server boot state
										 InPost
										 Start-Sleep -Seconds 5
										 

										# Call the function to check server boot state
										 PostDiscoveryComplete
										 Start-Sleep -Seconds 5
										 
										# Firmware Upgrade Finished Succe
										Write-host "Firmware Upgrade Process Has Been Finished sucessfully..." -ForeGroundColor GREEN
										
								 } catch {
									    Write-Host "`nMount the CD/DVD image to ILO $ip Rest Call Failed !!" -ForeGroundColor Red
									    Write-Host "Status Message:" $_.Exception.Message.ToString() -ForeGroundColor Red
										Write-host ""
										exit;
								 }

                               
					            ###########
								
								try {
										Write-Host "`nMount the Thiny image to ILO $ip"
                                        Invoke-RestMethod -Uri https://$ip/redfish/v1/Managers/1/VirtualMedia/1/Actions/Oem/Hpe/HpeiLOVirtualMedia.InsertVirtualMedia/  -Method POST -Headers $headers -Body ($thinyimagemedia | ConvertTo-Json) >$null 2>&1
                                        Start-Sleep -Seconds 5
										Write-host "Mount Simolivity Thiny Image Succeeded." -ForeGroundColor GREEN
										
										Write-Host "`nPower Reset !! ."
										Invoke-RestMethod -Uri https://$ip/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/  -Method POST -Headers $headers -Body ($bodyPoweredON | ConvertTo-Json) >$null 2>&1
										Start-Sleep -Seconds 5
										Write-host "Power Reset Succeeded.." -ForeGroundColor GREEN
										Write-host ""
										
										# Call the function to check server boot state
										 FinishedPost
										 Start-Sleep -Seconds 5
										 
										
										
								 } catch {
									    Write-Host "`nMount the Thiny image to ILO $ip Rest Call Failed !!" -ForeGroundColor Red
									    Write-Host "Status Message:" $_.Exception.Message.ToString() -ForeGroundColor Red
										Write-host ""
										exit;
								 }  


                                  Write-Host "`Simplivity Factory Reset Process Has Been DONE !!!! ...." -ForegroundColor Green
                                     


                           } else {
                             Write-Host "`nTask aborted.`n" -ForegroundColor Red
                           }

              } else {
                Write-Host "`n!!! Virtual Machine HA NOT COMPLIANT !!!`n" -ForegroundColor Red
              }
              
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
}