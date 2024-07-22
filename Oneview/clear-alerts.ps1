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
    Date    : 15/07/2024
	AUTHOR  : Emre Baykal - HPE Services
#>

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
$uri = "https://192.168.100.10"

# Get Script Execution Time 
$timestamp = Get-Date -Format "yyyy-MM-dd"
$logtimestamp = Get-Date -Format "dd MM hh:mm:ss"

# Alert Reporting Direcory
$reportpath = "$PSScriptRoot\report\current-alerts-$timestamp.csv"

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
	$errorMessage = $_
	Log-Message "Error: $errorMessage"
	Log-Message "HTTP Status: $statusCode - $statusDescription"
	Write-Host "Error: $errorMessage"
	Write-Host "HTTP Status: $statusCode - $statusDescription"

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


# Create Report
function Active-Alerts-Report {

	$headers = Get-AuthToken
	$AlertTable = @()

	#Check if Logs Directory Exists
	if(!(Test-Path -Path $PSScriptRoot\report))
	{
		#powershell create Report directory
		$directory = New-Item -ItemType Directory -Path $PSScriptRoot\report
		Write-Host "New reports directory $PSScriptRoot\Report created successfully..." -f Green
	}
	
	try {
		 Write-Host ""
		 Log-Message "Starting To Be Collected Active Alerts From HPE Oneview..." 
		 Write-Host "Starting To Be Collected Active Alerts From HPE Oneview..." -f Gray

		 $script:get_active_alerts = Invoke-RestMethod -Uri $uri/rest/alerts -Method Get -Headers $headers 

         if ($script:get_active_alerts.members.Count -eq 0) {
			 Write-Host "No more active alerts.." -ForegroundColor Yellow
			 Log-Message "No more active alerts !!"
		 } else {
			 foreach ($active_alerts in $script:get_active_alerts.members ) {
				# Extract the last segment of the URI
				$alertId = $active_alerts.uri.Split('/')[-1]
				
				$AlertInfo = New-Object PSObject -Property @{
						'Alert ID' = $alertId
						'Alert Creation Time' = $active_alerts.created
						'Alert State' = $active_alerts.alertState
						'Alert Severity' = $active_alerts.severity
						'Alert Urgency' = $active_alerts.urgency
						'Alert Type ID' = $active_alerts.alertTypeID
						'Alert Description' = $active_alerts.description
				} 
								
				$AlertTable += $AlertInfo
		   }	

             Write-Host "`n### HPE Oneview Active Alarms ###" -ForegroundColor White
			 $AlertTable | Sort -Property 'Alert Creation Time' | Format-Table -Property 'Alert ID', 'Alert Creation Time', 'Alert State', 'Alert Severity', 'Alert Urgency', 'Alert Type ID', 'Alert Description' | Format-Table -AutoSize
		
			 Write-Host "Creating a Report File Under The $PSScriptRoot\report Directory..." -f Gray
			 Write-Host "Alert Reports Created Successfully..." -f Green
			 Log-Message "Creating a Report File Under The $PSScriptRoot\report Directory..."
			 Log-Message "Alert Reports Created Successfully..."
			 
			 # Export the drive information to a CSV file
			 $AlertTable | Sort -Property 'Alert Creation Time' | Select-Object -Property 'Alert ID', 'Alert Creation Time', 'Alert State', 'Alert Severity', 'Alert Urgency', 'Alert Type ID', 'Alert Description' | Export-Csv -Path $reportpath -NoTypeInformation   
		 }
					
		 
	} catch {
			Log-Message "Collect Active Alerts Information Failed From HPE Oneview"
			Write-Host "Collect Active Alerts Information Failed From HPE Oneview" -ForegroundColor Red
			catch-error
			exit 1
	}


}

function Clear-Alerts {

	$headers = Get-AuthToken

    if ($script:get_active_alerts.members.Count -eq 0) {
			 Write-Host "`nStarting To Clear Active Alerts From HPE Oneview" -f Gray
			 Log-Message "Starting To Clear Active Alerts From HPE Oneview" 
			 Write-Host "No more active alerts.." -ForegroundColor Yellow
			 Log-Message "No more active alerts !!"
	} else {

			try {
				 Write-Host "`nStarting To Clear Active Alerts From HPE Oneview" -f Gray
				 Log-Message "Starting To Clear Active Alerts From HPE Oneview"

				 $clear_active_alerts = Invoke-RestMethod -Uri $uri/rest/alerts -Method Delete -Headers $headers 
				 
				 Write-Host "Cleared $($script:get_active_alerts.count) Alerts From HPE Oneview`n`n" -f Green
				 Log-Message "Cleared $($script:get_active_alerts.count) Alerts From HPE Oneview`n"

			} catch {
					Log-Message "Clear Active Alerts Failed From HPE Oneview"
					Write-Host "Clear Active Alerts Failed From HPE Oneview" -ForegroundColor Red
					catch-error
					exit 1
			}

    }
}


# script execution started
Write-Host "`n#############################################################################################################################"  -ForegroundColor White
Write-Host "#                       HPE Oneview Alert Collection Script Execution Started                                               #" -ForegroundColor White
Write-Host "#                                           $timestamp                                                                       " -ForegroundColor White
Write-Host "#############################################################################################################################" -ForegroundColor White

# Initialize Credential
Initialize-Credential | Out-Null

# Log Message
Log-Message "Script started...."

# Create Report
Active-Alerts-Report

# Clear Active alerts
Clear-Alerts
