<#
.Synopsis
    This PowerShell script includes functions for interacting with a HPE Proliant Servers API 
	to perform create disk and storage units reports.

	   
.Prerequisites
    PowerShell 5.1 or later.
    Access to an HPE Proliant Servers ILO's API.
    Valid credentials for the Host ILO.
	   

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 1.0.0.0
    Date    : 14/03/2024
	AUTHOR  : Emre Baykal - HPE Services
#>

# Adjust Powershell Window Size
$pshost = Get-Host              # Get the PowerShell Host.
$pswindow = $pshost.UI.RawUI    # Get the PowerShell Host's UI.

$newsize = $pswindow.BufferSize # Get the UI's current Buffer Size.
$newsize.Width = 186            # Set the new buffer's width to 208 columns.
$newsize.Height = 8000
$pswindow.buffersize = $newsize # Set the new Buffer Size as active.

$newsize = $pswindow.windowsize # Get the UI's current Window Size.
$newsize.Width = 186            # Set the new Window Width to 208 columns.
$newsize.Height = 50
$pswindow.windowsize = $newsize # Set the new Window Size as active.

# Skip SSL certificate validation
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

# Get Script Execution Time 
$timestamp = Get-Date -Format "yyyy-MM-dd"
	
# Get Servers ILO Variables
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
        Write-Host "Provide equal number of values for IP, Username and Password columns in the iLOInput.csv file and try again."
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
	
    "$timestamp $Message" | Out-File -FilePath "$PSScriptRoot\logs\hpe-ilo-$timestamp.log" -Append
}

function Initialize-Credential {
	# Check if the credential file already exists
	if (-Not (Test-Path $PSScriptRoot\cred.XML)) {
		# Prompt the user for credentials
		$Cred = Get-Credential -Message 'Enter Storage Credentials'  | Export-Clixml "$PSScriptRoot\cred.XML"
		Write-Host "Credentials saved to $credFile."
			 
	}

	#Import Credential File
	$Cred = Import-CLIXML "$PSScriptRoot\cred.XML" 
	
	return $Cred 
}

function Create-Report {
	
	# Get ILO Credential 
	$Credential = Initialize-Credential 

    # Initialize an array to hold drive information objects
    $driveInfoList = @()
	
    $pair = "{0}:{1}" -f ($Credential.UserName, $Credential.GetNetworkCredential().Password)
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $token = [System.Convert]::ToBase64String($bytes)

    $headers = @{
         Authorization = "Basic {0}" -f ($token)
         "Content-Type"="application/json"
    }
	
	#Check if Logs Directory Exists
	if(!(Test-Path -Path $PSScriptRoot\report))
	{
		#powershell create Report directory
		Write-Host ""
		$directory = New-Item -ItemType Directory -Path $PSScriptRoot\report
		Write-Host "New reports directory $PSScriptRoot\Report created successfully..." -f Green
	}

	foreach($ip in $inputcsv.IP)
	{

        $index = $inputcsv.IP.IndexOf($ip)
        $inputObject = New-Object System.Object
		
			Write-Host ""
			Log-Message "Server Information Started To Be Collected From $ip"
		    Write-Host "Server Information Started To Be Collected From $ip"
					 
			 try {					 
				# Invoke the REST API with DELETE method
				$get_chassis_info = Invoke-RestMethod -Uri https://$ip/redfish/v1/Chassis/1 -Method Get -Headers $headers 
				
				$chasiss_serial = $get_chassis_info.SerialNumber
				$chasiss_model = $get_chassis_info.Model
				
				Log-Message "Get Chassis Info Successfully from $ip"
				Write-Host "Get Chassis Info Successfully from $ip" -ForegroundColor Green
			 } catch {
				 $statusCode = $_.Exception.Response.StatusCode.Value__
				 $statusDescription = $_.Exception.Response.StatusDescription
				 $errorMessage = $_.Exception.Message
				 $stackTrace = $_.Exception.StackTrace
				 Log-Message "Get Chassis Info Failed From $ip"
				 Write-Host "Get Chassis Info Failed From $ip" -ForegroundColor Red
				 Log-Message "Error: $errorMessage"
				 Log-Message "HTTP Status: $statusCode - $statusDescription"
				 Log-Message "Stack Trace: $stackTrace"
				 Log-Message "Inner Exception: $innerException"
			 }	 
			 
			 try {  
				# Invoke the REST API with DELETE method
				$get_str_cont = Invoke-RestMethod -Uri https://$ip/redfish/v1/systems/1/storage -Method Get -Headers $headers 
				
				$str_adapters = $get_str_cont.members | ConvertTo-Json
				Log-Message "Get Storage Controller Info Successfully from $ip"
				Write-Host "Get Storage Controller Info Successfully from $ip" -ForegroundColor Green
				
			 } catch {
				 
				 $statusCode = $_.Exception.Response.StatusCode.Value__
				 $statusDescription = $_.Exception.Response.StatusDescription
				 $errorMessage = $_.Exception.Message
				 $stackTrace = $_.Exception.StackTrace
				 Log-Message "Get Storage Controller Info Failed From $ip"
				 Write-Host "Get Storage Controller Info From $ip" -ForegroundColor Red
				 Log-Message "Error: $errorMessage"
				 Log-Message "HTTP Status: $statusCode - $statusDescription"
				 Log-Message "Stack Trace: $stackTrace"
				 Log-Message "Inner Exception: $innerException"
			 } 
			 
			foreach ($adapter in $get_str_cont.members ) {
			  	
 			    try { 
				  $StrCont = $adapter."@odata.id" -split '/' | Select-Object -Last 1
				  $fullUri =  $ip + $adapter."@odata.id"
                  $disk_drivers = Invoke-RestMethod -Uri https://$fullUri -Method Get -Headers $headers
				  
					foreach ($drive in $disk_drivers.Drives) {
					  
					  $driveUri = $ip + $drive."@odata.id"
					  
					  $disk_drive = Invoke-RestMethod -Uri https://$driveUri -Method Get -Headers $headers 
					  
						# Create a custom object with the drive information
						$driveInfo = [PSCustomObject]@{
							"Host Ilo IP" = $ip
							"Chassis Serial" = $chasiss_serial
							"Chassis Model" = $chasiss_model
							"Drive ID" = $disk_drive.Id
							"Drive Name" = $disk_drive.Name
							"Drive Model" = $disk_drive.Model
							"Drive Serial Number" = $disk_drive.SerialNumber
							"Drive Media Type" = $disk_drive.MediaType
							"Drive Live Percent" = if ($disk_drive.MediaType -eq "SSD") { $disk_drive.PredictedMediaLifeLeftPercent } else { "N/A" }
							"Drive Health Status" = $disk_drive.Status.Health
						}

						# Add the custom object to the list
						$driveInfoList += $driveInfo

				  }
				 Write-Host "Get Disk State Collection Successfully From Controller: $StrCont" -ForegroundColor Green
				} catch {
					Log-Message "Get Disk State Collection Failed From Controller: $StrCont"
				    Write-Host "Get Disk State Collection Failed From Controller: $StrCont" -ForegroundColor Red
			   }
	      }

#Clear Variable
Clear-Variable get_str_cont	

}

Write-Host ""
Write-Host "Creating a Report File Under The $PSScriptRoot\report Directory..." -f Green
# Export the drive information to a CSV file
$driveInfoList | Export-Csv -Path "$PSScriptRoot\report\drive-information-$timestamp.csv" -NoTypeInformatio

Write-Host "`n###########################################################################################################################"  -ForegroundColor White
Write-Host "#                                             Host Storage Device Report                                                    #" -ForegroundColor White
Write-Host "#############################################################################################################################`n" -ForegroundColor White

# Display the results in a table format
$driveInfoList | Format-Table -AutoSize

}

# script execution started
Write-Host "#############################################################################################################################"  -ForegroundColor White
Write-Host "#                         HPE ILO Disk State Reporting Script Execution Started                                             #" -ForegroundColor White
Write-Host "#                                           $timestamp                                                                       " -ForegroundColor White
Write-Host "#############################################################################################################################`n" -ForegroundColor White


# Initialize Credential
Initialize-Credential | Out-Null

# Log Message
Log-Message "Script started...."

# Create Report
Create-Report 