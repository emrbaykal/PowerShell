####################################################################
#Upgrade HPE Proliant Server Fimware 
####################################################################

<#
.Synopsis
    This Script allows update firmware using SPP CD  for HPE ProLiant servers.

.DESCRIPTION
    This Script allows update firmware using SPP CD.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Find-HPEiLO, Connect-HPEiLO, Get-HPEiLOServerInfo, Disconnect-HPEiLO, Mount-HPEiLOVirtualMedia, Set-HPEiLOOneTimeBootOption, Reset-HPEiLO

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\fw-upgrade.ps1
	
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

# Define the CD/DVD image URL
$cdImageGen10URL = "http://10.254.254.12:8080/SVTSP-2023_0913-SVTSP-2023_0913_01.iso"
$cdImageGen11URL = "http://10.254.254.12:8080/SVTSP-2023_0913-SVTSP-2023_0913_01.iso"

try
{
    $path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\iLOInput.csv"
    $inputcsv = Import-Csv $path
	if($inputcsv.IP.count -eq $inputcsv.Username.count -eq $inputcsv.Password.count -eq 0)
	{
		Write-Host "Provide values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}

    $notNullIP = $inputcsv.IP | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullUsername = $inputcsv.Username | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullPassword = $inputcsv.Password | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
	
	if(-Not($notNullIP.Count -eq $notNullUsername.Count -eq $notNullPassword.Count ))
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

Clear-Host

#Load HPEiLOCmdlets module
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEiLOCmdlets"))
{
    Write-Host "Loading module :  HPEiLOCmdlets"
    Import-Module HPEiLOCmdlets
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
    $InstallediLOModule  =  Get-Module -Name "HPEiLOCmdlets"
    Write-Host "HPEiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine."
    Write-host ""
}

$Error.Clear()

#Enable logging feature
Write-Host "Enabling logging feature" -ForegroundColor Yellow
$log = Enable-HPEiLOLog
$log | fl

if($Error.Count -ne 0)
{ 
	Write-Host "`nPlease launch the PowerShell in administrator mode and run the script again." -ForegroundColor Yellow 
	Write-Host "`n****** Script execution terminated ******" -ForegroundColor Red 
	exit 
}	

try
{
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference ="SilentlyContinue"

    $reachableIPList = Find-HPEiLO $inputcsv.IP -WarningAction SilentlyContinue
    Write-Host "The below list of ILO IP's are reachable."
    $reachableIPList.IP

    $Error.Clear()

	function Get-Post-State {
		$poststate = Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/ -Method GET -Headers $headers -SkipCertificateCheck
		$script:poststate = $poststate.Oem.Hpe.PostState
	}
	
	# Check Hardware Firmware Upgrade Process
	function Get-UpdateState {
		$checkupdatestate = Invoke-RestMethod -Uri https://$ip/redfish/v1/UpdateService -Method GET -Headers $headers -SkipCertificateCheck
		$script:updatestate = $checkupdatestate.Oem.Hpe.State
		#Write-Host "Update State is: $($updatestate)"
  
	  }
	
	# Check Hardware Power State
    function Get-PowerState {
	  $checkpowerstate = Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/ -Method GET -Headers $headers -SkipCertificateCheck
	  $script:powerstate = $checkpowerstate.PowerState
      Write-Host "Hardware $($ip) Power State is: $($script:powerstate)"
    }

	# Mount Firmware Media
    function Invoke-Mount-Media {
	  try {
		  Write-host "Try to Mount Firmware Media... "
		  $response = Invoke-RestMethod -Uri https://$ip/redfish/v1/Managers/1/VirtualMedia/2/Actions/Oem/Hpe/HpeiLOVirtualMedia.InsertVirtualMedia/  -Method POST -Headers $headers -SkipCertificateCheck -Body ($fwmedia | ConvertTo-Json)
		  Start-Sleep -Seconds 5

		  # Check if there is an error field in the response
		  $messageId = $response.error.'@Message.ExtendedInfo'.MessageId
		  if ($messageId -eq "Base.1.4.Success") {
				  Write-host "Mount Firmware CD/DVD Image Succeeded to $($ip)..." -ForeGroundColor GREEN
		  }
	  
	  } catch {
		  Write-Host "An Exception Occurred When Mount Firmware Media: $($_.Exception.Message)" -ForeGroundColor RED
	  }

    }

	# Force First Boot From CDRom 
    function Invoke-Boot-On-Next {
	  try {

		  $BootOnNextServer = @{
			  "Oem" = @{
				  "Hpe" = @{
					  "BootOnNextServerReset" = $true
				  }
			  }
		  }
		  Write-host "Settings are being made to boot from firmware media... "
		  $response = Invoke-RestMethod -Uri https://$ip/redfish/v1/Managers/1/VirtualMedia/2  -Method PATCH -Headers $headers -SkipCertificateCheck -Body ($BootOnNextServer | ConvertTo-Json) 
		  Start-Sleep -Seconds 5

		  # Check if there is an error field in the response
		  $messageId = $response.error.'@Message.ExtendedInfo'.MessageId
  
		  if ($messageId -eq "Base.1.4.Success") {
			  Write-host "Set Boot On Next Server Succeeded to $($ip)..." -ForeGroundColor GREEN
		  }
	  
	  } catch {
		  Write-Host "An Exception Occurred When Set Boot On Next Server: $($_.Exception.Message)" -ForeGroundColor RED
	  }

    }

    # Hardware Powered On 
    function Invoke-Power-On-Server {

	  try {

		  $bodyPoweredON = @{  
			  "ResetType" = "On"
		   }

		   Write-host "Hardware Powering On... "
		  $response = Invoke-RestMethod -Uri https://$ip/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/  -Method POST -Headers $headers -SkipCertificateCheck -Body ($bodyPoweredON | ConvertTo-Json)
		  Start-Sleep -Seconds 5

		  # Check if there is an error field in the response
		  $messageId = $response.error.'@Message.ExtendedInfo'.MessageId
	  
			  if ($messageId -eq "Base.1.4.Success") {
				  Write-host "Hardware Powered On Successfully.." -ForeGroundColor GREEN
			  }

	  } catch {
		  Write-Host "An exception occurred When Server Powered On: $($_.Exception.Message)" -ForeGroundColor RED
	  }

    }

	# Hardware Powered Off
    function Invoke-Power-Off-Server {
	  try {
		  $bodyForceOff = @{  
			  "ResetType" = "ForceOff"
		   }
          
		  Write-host "Server Powering Off... "
		  $response = Invoke-RestMethod -Uri https://$ip/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/  -Method POST -Headers $headers -SkipCertificateCheck -Body ($bodyForceOff  | ConvertTo-Json)
		  Start-Sleep -Seconds 5

		  # Check if there is an error field in the response
		  $messageId = $response.error.'@Message.ExtendedInfo'.MessageId
	  
			  if ($messageId -eq "Base.1.4.Success") {
				  Write-host "Server Powered Off Successfully.." -ForeGroundColor GREEN
			  }

	  } catch {
		  Write-Host "An exception occurred When Server Powered Off: $($_.Exception.Message)" -ForeGroundColor RED
	  }

    }

    foreach($ip in $reachableIPList.IP)
    {
        $index = $inputcsv.IP.IndexOf($ip)
        $inputObject = New-Object System.Object
		
		$ilopassword = $inputcsv[$index].Password 
		$ilousername = $inputcsv[$index].Username

		$pair = "{0}:{1}" -f ($ilousername, $ilopassword)
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
		$token = [System.Convert]::ToBase64String($bytes)

		$headers = @{
			 Authorization = "Basic {0}" -f ($token)
			"Content-Type"="application/json"
		}

		#####

		$CheckILOVersion = Invoke-RestMethod -Uri https://$ip/redfish/v1 -Method GET -Headers $headers -SkipCertificateCheck
		$ILOVersion = $CheckILOVersion.Oem.Hpe.Manager.ManagerType -replace '\w+\D+',''
		Write-Host "ILO Version Is: $($ILOVersion)"
        Write-host ""
        		
        switch($iLOVersion)
        {
            5 {

				$fwmedia 
				$fwmedia =  @{  
					"Image" = "$cdImageGen10URL"
					"Action" = "HpeİLOVirtualMedia.InsertVirtualMedia"
				}

                # Powered Off 
				Get-PowerState 
                if ($script:powerstate -eq "On") {
					Invoke-Power-Off-Server
				}

				# Insert Firmware Media
				Invoke-Mount-Media

				#Set One time BootOption to CD/DVD to ILO 
				Invoke-Boot-On-Next

				# Powered On
				Get-PowerState 
				if ($script:powerstate -eq "Off") {
					Invoke-Power-On-Server
				}

				# Set the timeout value (in seconds)
				$timeout = 300 

				# Start time
				$startTime = Get-Date

				do {
					 # Get Post State
					 Get-Post-State

					 $currentTime = Get-Date
					 $elapsedTime = $currentTime - $startTime

					 # Show the current state and elapsed time with Write-Progress
					 Write-Progress -Activity "Wait For Boot Service Pack For Porliant Media.." -Status "Current state: $script:poststate, Elapsed time: $($elapsedTime.ToString('hh\:mm\:ss'))"
					 
					 if ($state -eq "FinishedPost") {
						Write-Host "POST state is now FinishedPost. Finalizing..."
						break
					}

					if ($elapsedTime.TotalSeconds -gt $timeout) {
						Write-Host "Error: Process exceeded the timeout of $timeout seconds." -ForeGroundColor RED
						break
					}

					Start-Sleep -Seconds 5

                } while ($true)

				#Write-Host "Waiting For Boot Firmware Upgrade Media..."
				# Call the function to check server boot state
				# Write-Host "Wait For Boot Finished Post Process Done..."
				# FinishedPost
				# Start-Sleep -Seconds 5
					 
#####
				# Call the function to check server boot state
				#Write-Host "Firmware Upgrade Process Start Wait For Finilize..."

				# Check Boot State
				#Get-Post-State

				#$script:poststate


				


####				

				#	 InPost
				#	 Start-Sleep -Seconds 5
					 

					# Call the function to check server boot state
				#	 PostDiscoveryComplete
				#	 Start-Sleep -Seconds 5
					 
					# Firmware Upgrade Finished Succe
				#	Write-host "Firmware Upgrade Process Has Been Finished sucessfully..." -ForeGroundColor GREEN
					
				
              
            }

            6{

				$fwmedia =  @{  
					"Image" = "$cdImageGen11URL"
					"Action" = "HpeİLOVirtualMedia.InsertVirtualMedia"
				}
   
                # Powered Off 
				Get-PowerState 
                if ($script:powerstate -eq "On") {
					Invoke-Power-Off-Server
				}
				
				# Insert Firmware Media
				Invoke-Mount-Media

				#Set One time BootOption to CD/DVD to ILO 
				Invoke-Boot-On-Next
              
				# Powered On
				if ($script:powerstate -eq "Off") {
					Invoke-Power-On-Server
				}
            }
                default{continue}
        }
		
        $reachableData += $inputObject
    }


}
catch
{
}    
finally
{
    
	
	#Disable logging feature
	Write-Host "Disabling logging feature`n" -ForegroundColor Yellow
	$log = Disable-HPEiLOLog
	$log | fl
	
#	if($Error.Count -ne 0 )
#    {
#        Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
#    }
	
    Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
}