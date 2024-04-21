<#
.Synopsis
    This PowerShell script includes functions for interacting with a HPE Proliant Servers API 
	to perform create disk and storage units reports.

	   
.Prerequisites
    PowerShell 5.1 or later.
    Access to an HPE Oneview API.
    Valid credentials for HPE Oneview.
	   

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 1.0.0.0
    Date    : 18/04/2024
	AUTHOR  : Emre Baykal - HPE Services
#>

# Adjust Powershell Window Size
$pshost = Get-Host              # Get the PowerShell Host.
$pswindow = $pshost.UI.RawUI    # Get the PowerShell Host's UI.

$newsize = $pswindow.BufferSize # Get the UI's current Buffer Size.
$newsize.Width = 216            # Set the new buffer's width to 216 columns.
$newsize.Height = 8000
$pswindow.buffersize = $newsize # Set the new Buffer Size as active.

$newsize = $pswindow.windowsize # Get the UI's current Window Size.
$newsize.Width = 216            # Set the new Window Width to 216 columns.
$newsize.Height = 50
$pswindow.windowsize = $newsize # Set the new Window Size as active.

# Bypass SSL certificate validation
Add-Type @"
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


# HPE Oneview URL
$uri = "https://10.254.254.15"

# Diisk Drive Reporting Direcory
$reportpath = "$PSScriptRoot\report\drive-information.csv"

# Get Script Execution Time 
$timestamp = Get-Date -Format "yyyy-MM-dd"
$logtimestamp = Get-Date -Format "dd MM hh:mm:ss"

Clear-Host

## Initilize Log File
function Log-Message {
    param(
        [string]$Message
    )
	
	 #Check if Logs Directory Exists
	 if(!(Test-Path -Path $PSScriptRoot\logs))
	 {
		 #powershell create logs directory
		 $directory = New-Item -ItemType Directory -Path $PSScriptRoot\logs
		 Write-Host "New logs directory $PSScriptRoot\logs created successfully..." -f Green
	 }
	
    "$logtimestamp $Message" | Out-File -FilePath "$PSScriptRoot\logs\hpe-oneview.log" -Append
}

## Catch Rest Api Call Errors
function catch-error {
    $statusCode = $_.Exception.Response.StatusCode.Value__
	$statusDescription = $_.Exception.Response.StatusDescription
	$errorMessage = $_.Exception.Message
	Log-Message "Error: $errorMessage"
	Log-Message "HTTP Status: $statusCode - $statusDescription"
	Log-Message "Inner Exception: $innerException"
}

# Initialize HPE Oneview Credential File
function Initialize-Credential {
	# Check if the credential file already exists
	if (-Not (Test-Path $PSScriptRoot\cred.XML)) {
		# Prompt the user for credentials
		$Cred = Get-Credential -Message 'Enter HPE Oneview Credentials'  | Export-Clixml "$PSScriptRoot\cred.XML"
		Write-Host "Credentials saved to $credFile."
			 
	}

	#Import Credential File
	$Cred = Import-CLIXML "$PSScriptRoot\cred.XML" 
	
	return $Cred 
}

# Get X API Version
function Get-X-API-Version {
    $api_headers = @{
		"X-API-Version"= "800"
    }

	try {
		$api_version = Invoke-RestMethod -Uri $uri/rest/version -Method Get -Headers $api_headers

	} catch {
		Log-Message "Error Getting to X-API-VERSION"
		Write-Host "Error Getting to X-API-VERSION" -ForegroundColor Red
        catch-error
		exit 1
	}

    return $api_version
}

# Get Authentication Token
function Get-AuthToken {
	$Credential = Initialize-Credential 
	$api_version = Get-X-API-Version 
	
	try {
		$auth_token = Invoke-RestMethod -Uri $uri/rest/login-sessions -Method Post -Body (@{
			userName = $Credential.UserName
			password = $Credential.GetNetworkCredential().Password
			authLoginDomain = "Local"
		} | ConvertTo-Json) -ContentType "application/json"

	} catch {
		Log-Message "Error Getting to HPE Oneview Token"
		Write-Host "Error Getting to HPE Oneview Token" -ForegroundColor Red
		catch-error
		exit 1
	}

	$headers = @{
				"X-API-Version"=($api_version.currentVersion)
				"Auth"=($auth_token.sessionID)
	}

    return $headers
}

# Create Chassis Device Collection Report
function Chassis-Report {
   
	param (
        [Parameter(Mandatory=$true)]
        $server,
		[string]$DriveReportStatus = "OK"
    )

	$ChassisList = @()

	$ChassisInfo = [PSCustomObject]@{
		"ILO IP Address" = $server.mpHostInfo.mpIpAddresses[0].address
		"Chassis Serial Number" = $server.serialNumber
		"Chassis Model" = $server.shortModel
		"Chassis Platform" = $server.platform
		"Chassis Power" = $server.powerState
		"Chassis Drive Report" = $DriveReportStatus

	}

	# Add the custom object to the list
	$ChassisList += $ChassisInfo
    return $ChassisList
}

# Create Report
function Create-Report {

	$headers = Get-AuthToken
	$driveInfoList = @()
	$ChassisList = @()

	#Check if Logs Directory Exists
	if(!(Test-Path -Path $PSScriptRoot\report))
	{
		#powershell create Report directory
		$directory = New-Item -ItemType Directory -Path $PSScriptRoot\report
		Write-Host "New reports directory $PSScriptRoot\Report created successfully..." -f Green
	}
	
	try {
		 Write-Host ""
		 Log-Message "Server Information Starting To Be Collected From HPE Oneview" 
		 Write-Host "Server Information Started To Be Collected From HPE Oneview" -f Gray

		 $get_server_hardware =Invoke-RestMethod -Uri $uri/rest/server-hardware -Method Get -Headers $headers 
		 
		 foreach ($server in $get_server_hardware.members ) {
			   try {
				$fullUri =  $uri + $server.subResources.LocalStorageV2.uri
				$get_disk_drivers = Invoke-RestMethod -Uri $fullUri -Method Get -Headers $headers 
				
				   foreach ($disk_driver_data in $get_disk_drivers.data ) {
					  foreach ($drive in $disk_driver_data.Drives) {
								# Create a custom object with the drive information
								$driveInfo = [PSCustomObject]@{
									"ILO IP Address" = $server.mpHostInfo.mpIpAddresses[0].address
									"Chassis Serial Number" = $server.serialNumber
									"Chassis Model" = $server.shortModel
									"Chassis Platform" = $server.platform
									"Chassis Power" = $server.powerState
									"Drive ID" = $drive.Id
									"Drive Name" = $drive.Name
									"Drive Model" = $drive.Model
									"Drive Serial Number" = $drive.SerialNumber
									"Drive State" = $drive.Status.State
									"Drive Media Type" = $drive.MediaType
									"Drive Health Status" = $drive.Status.Health
									"Drive Live Percent %" = if ($drive.MediaType -eq "SSD") { $drive.PredictedMediaLifeLeftPercent } else { "N/A" }

								}

								# Add the custom object to the list
								$driveInfoList += $driveInfo
						 }

				  }
                
				  $ChassisList += Chassis-Report -server $server -DriveReportStatus "OK"


		   		} catch {
					Log-Message "Collect $server.mpHostInfo.mpIpAddresses[0].address Chassis Local Storage Information Failed From HPE Oneview"
					$ChassisList += Chassis-Report -server $server -DriveReportStatus "Fail"
					catch-error
		   		}
			
		 }

         Log-Message "Collected Server Informations Successfully From HPE Oneview"
	     Write-Host "Collected Server Information Successfully From HPE Oneview" -ForegroundColor Green
	     Write-Host "Creating a Report File Under The $PSScriptRoot\report Directory..." -f Green
	     # Export the drive information to a CSV file
	     $driveInfoList | Export-Csv -Path $reportpath -NoTypeInformatio

	} catch {
			Log-Message "Collect Server Information Failed From HPE Oneview"
			Write-Host "Collect Server Information Failed From HPE Oneview" -ForegroundColor Red
			catch-error
			exit 1
	}

	Write-Host "`n#############################################################################################################################"  -ForegroundColor White
	Write-Host "#                                            Chassis Storage Device Collection Report                                       #" -ForegroundColor White
	Write-Host "#############################################################################################################################`n" -ForegroundColor White

	# Display the results in a table format
	$ChassisList | Format-Table -AutoSize

}

# script execution started
Write-Host "#############################################################################################################################"  -ForegroundColor White
Write-Host "#                         HPE Disk State Reporting Script Execution Started                                                 #" -ForegroundColor White
Write-Host "#                                           $timestamp                                                                       " -ForegroundColor White
Write-Host "#############################################################################################################################`n" -ForegroundColor White

# Initialize Credential
Initialize-Credential | Out-Null

# Log Message
Log-Message "Script started...."

# Create Report
Create-Report 
