<#
.Synopsis
    This PowerShell script includes functions for interacting with a storage system API to perform operations 
	such as creating and deleting snapshots, application sets, and VLUNs. 

	   
.Prerequisites
    PowerShell 7.0 or later.
    Access to an HPE Primera or compatible storage system's API.
    Valid credentials for the storage system.
	   

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 2.1.0.0
    Date    : 17/07/2024
	AUTHOR  : Emre Baykal - HPE Services
#>
#Requires -Version 7

param (
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath
)

# Skip SSL certificate validation
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Set TLS version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Silent Warring Actions
$WarningPreference = "SilentlyContinue"


# Check if the config file exists
if (-Not (Test-Path -Path $ConfigFilePath)) {
    Write-Host "Configuration file not found at path: $ConfigFilePath" -ForegroundColor Red
    exit
}

# Configuration Data
$configData = Import-PowerShellDataFile -Path $ConfigFilePath

# Access Variables
$uri = $configData['uri']
$credFile = $configData['credFile'].Replace('$PSScriptRoot', $PSScriptRoot)
$volumeGroups = $configData['volumeGroups']
$applicationset = $configData['applicationset']
$snapcomment = $configData['snapcomment']
$emailBody = "<html><body><h2>HPE Primera Storage Snapshot Process</h2><ul>"
$emailTo = $configData['emailTo']
$emailFrom = $configData['emailFrom']
$SmtpServer = $configData['SmtpServer']

## Initilize Log File
function Log-Message {
    param(
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -FilePath "$PSScriptRoot\hpe-primera.log" -Append
	 $script:emailBody += "<li>$timestamp $Message</li>"
}

function Initialize-Credential {
	# Check if the credential file already exists
	if (-Not (Test-Path $credFile)) {
		# Prompt the user for credentials
		$Cred = Get-Credential -Message 'Enter Storage Credentials'  | Export-Clixml "$PSScriptRoot\cred.XML"
		Write-Host "Credentials saved to $credFile.`n" -ForegroundColor Green
			 
	}

	#Import Credential File
	$Cred = Import-CLIXML "$PSScriptRoot\cred.XML" 
	
	return $Cred 
}

# Get Authentication Token
function Get-AuthToken {
	$Credential = Initialize-Credential 
	
	$auth_token = Invoke-RestMethod -Uri $uri/credentials -Method Post -Body (@{
		user = $Credential.UserName
		password = $Credential.GetNetworkCredential().Password
		sessionType = 1
	} | ConvertTo-Json) -ContentType "application/json" -SkipCertificateCheck

	$headers = @{
				"X-HP3PAR-WSAPI-SessionKey"=($auth_token.key)
				"Content-Type"="application/json"
	}

    return $headers
}

####### Delete & Un-Assign VLUN ########## 
function Delete-Vlun {
    $headers = Get-AuthToken
    
	Write-Host "Snapshot Vlun Deletion Process Start ..." -ForegroundColor White
	Log-Message "Snapshot Vlun Deletion Process Start ..."
	
    $volumeGroups | ForEach-Object {
        $SnapName = $_.snapshotName
        $SnapLunId = $_.snapVlunId
        $HostSet = $_.hostSet
        $delete_vlun_uri = "$uri/vluns/$SnapName,$SnapLunId,$HostSet"
		
        
        try {
             
			$check_vlun = Invoke-RestMethod -Uri $delete_vlun_uri -Method Get -Headers $headers -SkipCertificateCheck
  
                try {
                    # Invoke the REST API with DELETE method
                    $delete_vlun = Invoke-RestMethod -Uri $delete_vlun_uri -Method Delete -Headers $headers -Body (@{ } | ConvertTo-Json) -SkipCertificateCheck
                    Log-Message "Vlun $SnapName Deletion Successfully"
                    Write-Host "Vlun $SnapName Deletion Successfully" -ForegroundColor Green
                } catch {
                    $statusCode = $_.Exception.Response.StatusCode.Value__
                    $statusDescription = $_.Exception.Response.StatusDescription
                    Log-Message "Vlun $SnapName deletion failed with status: $statusDescription"
					Log-Message "Vlun $SnapName deletion Error Occurred: $_"
                    Write-Host "Vlun $SnapName deletion failed with status: $statusDescription" -ForegroundColor Red
                    Write-Verbose "Vlun $SnapName deletion Error Occurred: $_"
                    throw
                }
       
        } catch {
            Log-Message "Vlun $SnapName does not exists. Skipping deletion !!"
            Write-Host "Vlun $SnapName does not exists. Skipping deletion !!" -ForegroundColor Yellow

        }
    }
    # Wait 5 Sec
    Start-Sleep -Seconds 5
}

####### Delete Application Set ##########
function Delete-AppSet {
	$headers = Get-AuthToken
	
	Write-Host "`nApplicationSet Deletion Process Start ..." -ForegroundColor White
	Log-Message "ApplicationSet Deletion Process Start ..."
	
	try {
		  # Check if the LUN exists
           $check_appset = Invoke-RestMethod -Uri $uri/volumesets/$applicationset -Method Get -Headers $headers -SkipCertificateCheck
			
				try {
					 $delete_appset =Invoke-RestMethod -Uri $uri/volumesets/$applicationset -Method Delete -Headers $headers -Body (@{ } | ConvertTo-Json) -SkipCertificateCheck
					 Log-Message "ApplicationSet $applicationset Deleted Successfully"
					 Write-Host "ApplicationSet $applicationset Deleted Successfully" -ForegroundColor Green
				} catch {
					 $statusCode = $_.Exception.Response.StatusCode.Value__
					 $statusDescription =  $_.Exception.Response.StatusDescription
					 Log-Message "ApplicationSet $applicationset deletion failed with status: $statusDescription"
					 Log-Message "ApplicationSet $applicationset deletion Error Occurred: $_"
					 Write-Host "ApplicationSet $applicationset deletion failed with status: $statusDescription" -ForegroundColor Red
					 Write-Verbose "ApplicationSet $applicationset deletion Error Occurred: $_"
					 throw
				}
				# Wait 5 Sec
				Start-Sleep -Seconds 5
	
	} catch {
            Log-Message "ApplicationSet $applicationset does not exists. Skipping deletion !!"
            Write-Host "ApplicationSet $applicationset does not exists. Skipping deletion !!" -ForegroundColor Yellow

    }
}

####### Delete Snapshots ########## 
function Delete-Snapshot {
	$headers = Get-AuthToken
	
	Write-Host "`nSnapshot Deletion Process Start ..." -ForegroundColor White
	Log-Message "Snapshot Deletion Process Start ..."
	
	$volumeGroups | ForEach-Object {
	$SnapName = $_.snapshotName
	$delete_snap_uri ="$uri/volumes/$SnapName"
   
            try {
				
				$check_snap = Invoke-RestMethod -Uri $delete_snap_uri -Method Get -Headers $headers -SkipCertificateCheck
				
				try {
				   # Invoke the REST API with DELETE method
				   $delete_snap =Invoke-RestMethod -Uri $delete_snap_uri -Method Delete -Headers $headers -Body (@{ } | ConvertTo-Json) -SkipCertificateCheck
				   Log-Message "Snapshot $SnapName Deleted Successfully"
				   Write-Host "Snapshot $SnapName Deleted Successfully" -ForegroundColor Green
				} catch {
				   $statusCode = $_.Exception.Response.StatusCode.Value__
				   $statusDescription =  $_.Exception.Response.StatusDescription
				   Log-Message "Snapshot $SnapName deletion failed with status: $statusDescription"
				   Log-Message "Snapshot $SnapName deletion Error Occurred: $_"
				   Write-Host "Snapshot $SnapName deletion failed with status: $statusDescription" -ForegroundColor Red
				   Write-Verbose "Snapshot $SnapName deletion Error Occurred: $_"
				   throw
				}
			} catch {
            Log-Message "Snapshot $SnapName does not exists. Skipping deletion !!"
            Write-Host "Snapshot $SnapName does not exists. Skipping deletion !!" -ForegroundColor Yellow
        }
    }
# Wait 30 Sec
Start-Sleep -Seconds 30
}

####### Create Snapshot ########## 
function Create-Snapshot {
	$headers = Get-AuthToken
	
	Write-Host "`nSnapshot Creation Process Start ..." -ForegroundColor White
	Log-Message "Snapshot Creation Process Start ..."
	
	$create_snap_body = @{
		action = 8
		parameters = @{
		volumeGroup = $volumeGroups | ForEach-Object {
			@{
				volumeName = $_.volumeName
				snapshotName = $_.snapshotName
				snapshotId = $_.snapshotId
				snapshotWWN = $_.snapshotWWN
				readWrite = $_.readWrite
			}
		}
		comment	= $snapcomment
		addToSet = $applicationset
		}
	}

	try {
		 $create_snap = Invoke-RestMethod -Uri $uri/volumes -Method Post -Headers $headers -Body ($create_snap_body | ConvertTo-Json -Depth 10) -SkipCertificateCheck
	} catch {
		$statusCode = $_.Exception.Response.StatusCode.value__
		if ($statusCode -eq 300) {
		   Log-Message "Snapshots Created Successfully"
		   Write-Host "Snapshots Created Successfully" -ForegroundColor Green
		} else {
		   $statusDescription =  $_.Exception.Response.StatusDescription
		   Log-Message "Snapshot Creation failed with status: $statusDescription"
		   Log-Message "Snapshot Creation failed: $_"
		   Write-Host "Snapshot Creation failed with status: $statusDescription" -ForegroundColor Red
		   Write-Verbose "Snapshot Creation failed: $_"
		}
	}
# Wait 5 Sec
Start-Sleep -Seconds 5
}

####### Create & Assign VLun ##########
function Create-Vlun {
	$headers = Get-AuthToken
	
	Write-Host "`nCreate & Assign VLUN Process Start ..." -ForegroundColor White
	Log-Message "Create & Assign VLUN Process Start ..."
	
	$volumeGroups | ForEach-Object {
		$create_snap_body =  @{
			  volumeName = $_.snapshotName
			  lun = $_.snapVlunId
			  hostname = $_.hostSet
			}
			
		$SnapName = $_.snapshotName
		try {
		   $create_vlun = Invoke-RestMethod -Uri $uri/vluns -Method Post -Headers $headers -Body ($create_snap_body | ConvertTo-Json -Depth 10) -SkipCertificateCheck
		   Log-Message "Create & Assign VLUN $SnapName Successfully"
		   Write-Host "Create & Assign VLUN $SnapName Successfully" -ForegroundColor Green
		} catch {
		   $statusCode = $_.Exception.Response.StatusCode.Value__
		   $statusDescription =  $_.Exception.Response.StatusDescription
		   Log-Message "VLUN $SnapName Creation failed with status: $statusDescription"
		   Log-Message "VLUN $SnapName Creation failed: $_"
		   Write-Host "VLUN $SnapName Creation failed with status: $statusDescription" -ForegroundColor Red
		   Write-Verbose "VLUN $SnapName Creation failed: $_"
		}
	}
}

###### Clear all user session environment variables ######
function Clear-UserSessionEnvironmentVariables {
    Write-Verbose "Clearing user session environment variables..."
    
    # Get all environment variables for the current user session
    $userEnvVars = Get-ChildItem Env:
    
    # Loop through each environment variable and remove it
    foreach ($envVar in $userEnvVars) {
        Write-Verbose "Removing environment variable: $($envVar.Name)"
        Remove-Item -Path "Env:$($envVar.Name)"
    }

    Write-Output "`nUser session environment variables cleared."
}

function e-mail {
    # Finalize email body
	$script:emailBody += "</ul></body></html>"

    # Send email
	$sendMailMessageSplat = @{
    From = $emailFrom
    To = $emailTo
    Subject = $snapcomment
    Body = $script:emailBody
    SmtpServer = $SmtpServer
    }
    Send-MailMessage @sendMailMessageSplat

}

Write-Host "`n####################################################################"
Write-Host "#                  HPE Primera LUN Snaphot                         #"
Write-Host "####################################################################`n"

Write-Host "Effective TLS setting: $([Net.ServicePointManager]::SecurityProtocol)`n"

# Initialize Credential
Initialize-Credential | Out-Null

# Get Authentication Token
Get-AuthToken | Out-Null

# Log Message
Log-Message "Script started...."

# Delete & Un-Assign VLUN
Delete-Vlun

# Delete Application Set
Delete-AppSet

# Delete Snapshots
Delete-Snapshot

# Create Snapshot
Create-Snapshot

# Create & Assign VLun
Create-Vlun

# Send Mail
e-mail

# Clean User Environment Varibales
Clear-UserSessionEnvironmentVariables

