param (
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath
)

<#
.Synopsis
    This PowerShell script includes functions for interacting with a storage system API to perform operations 
	such as creating and deleting snapshots, application sets, and VLUNs. 

	   
.Prerequisites
    PowerShell 5.1 or later.
    Access to an HPE Primera or compatible storage system's API.
    Valid credentials for the storage system.
	   

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 1.0.0.0
    Date    : 04/03/2024
	AUTHOR  : Emre Baykal - HPE Services
#>

# Skip SSL certificate validation
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Check if the config file exists
if (-Not (Test-Path -Path $ConfigFilePath)) {
    Write-Error "Configuration file not found at path: $ConfigFilePath"
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

## Initilize Log File
function Log-Message {
    param(
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -FilePath "$PSScriptRoot\hpe-primera.log" -Append
}

function Initialize-Credential {
	# Check if the credential file already exists
	if (-Not (Test-Path $credFile)) {
		# Prompt the user for credentials
		$Cred = Get-Credential -Message 'Enter Storage Credentials'  | Export-Clixml "$PSScriptRoot\cred.XML"
		Write-Host "Credentials saved to $credFile."
			 
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
	} | ConvertTo-Json) -ContentType "application/json"

	$headers = @{
				"X-HP3PAR-WSAPI-SessionKey"=($auth_token.key)
				"Content-Type"="application/json"
	}

    return $headers
}

####### Delete & Un-Assign VLUN ########## 
function Delete-Vlun {
	$headers = Get-AuthToken
	
	$volumeGroups | ForEach-Object {
		$SnapName = $_.snapshotName
		$SnapLunId = $_.snapVlunId
		$HostSet = $_.hostSet
		$delete_vlun_uri ="$uri/vluns/$SnapName,$SnapLunId,$HostSet"
		
			try {
			   # Invoke the REST API with DELETE method
			   $delete_vlun = Invoke-RestMethod -Uri $delete_vlun_uri -Method Delete -Headers $headers -Body (@{ } | ConvertTo-Json)
			   Log-Message "Vlun $SnapName Deletion Successfully"
			} catch {
			   $statusCode = $_.Exception.Response.StatusCode.Value__
			   $statusDescription =  $_.Exception.Response.StatusDescription
			   Log-Message "Vlun $SnapName deletion failed with status: $statusDescription"

			}
	}
	# Wait 5 Sec
	Start-Sleep -Seconds 5
}

####### Delete Application Set ##########
function Delete-AppSet {
	$headers = Get-AuthToken
	
	try {
		 $delete_appset =Invoke-RestMethod -Uri $uri/volumesets/$applicationset -Method Delete -Headers $headers -Body (@{ } | ConvertTo-Json)
		 Log-Message "ApplicationSet $applicationset Deleted Successfully"
	} catch {
		 $statusCode = $_.Exception.Response.StatusCode.Value__
		 $statusDescription =  $_.Exception.Response.StatusDescription
		 Log-Message "ApplicationSet $applicationset deletion failed with status: $statusDescription"
	}
	# Wait 5 Sec
	Start-Sleep -Seconds 5
}

####### Delete Snapshots ########## 
function Delete-Snapshot {
	$headers = Get-AuthToken
	
	$volumeGroups | ForEach-Object {
	$SnapName = $_.snapshotName
	$delete_snap_uri ="$uri/volumes/$SnapName"
   
		try {
		   # Invoke the REST API with DELETE method
		   $delete_snap =Invoke-RestMethod -Uri $delete_snap_uri -Method Delete -Headers $headers -Body (@{ } | ConvertTo-Json)
		   Log-Message "Snapshot $SnapName Deleted Successfully"
		} catch {
		   $statusCode = $_.Exception.Response.StatusCode.Value__
		   $statusDescription =  $_.Exception.Response.StatusDescription
		   Log-Message "Snapshot $SnapName deletion failed with status: $statusDescription"
		}
    }
# Wait 30 Sec
Start-Sleep -Seconds 30
}

####### Create Snapshot ########## 
function Create-Snapshot {
	$headers = Get-AuthToken
	
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
		 $create_snap = Invoke-RestMethod -Uri $uri/volumes -Method Post -Headers $headers -Body ($create_snap_body | ConvertTo-Json -Depth 10) 
	} catch {
		$statusCode = $_.Exception.Response.StatusCode.value__
		if ($statusCode -eq 300) {
		   Log-Message "Snapshot Created Successfully"
		} else {
		   $statusDescription =  $_.Exception.Response.StatusDescription
		   Log-Message "Snapshot Creation failed with status: $statusDescription"
		}
	}
# Wait 5 Sec
Start-Sleep -Seconds 5
}

####### Create & Assign VLun ##########
function Create-Vlun {
	$headers = Get-AuthToken
	
	$volumeGroups | ForEach-Object {
		$create_snap_body =  @{
			  volumeName = $_.snapshotName
			  lun = $_.snapVlunId
			  hostname = $_.hostSet
			}
			
		$SnapName = $_.snapshotName
		try {
		   $create_vlun = Invoke-RestMethod -Uri $uri/vluns -Method Post -Headers $headers -Body ($create_snap_body | ConvertTo-Json -Depth 10)
		   Log-Message "Create & Assign VLUN $SnapName Successfully"
		} catch {
		   $statusCode = $_.Exception.Response.StatusCode.Value__
		   $statusDescription =  $_.Exception.Response.StatusDescription
		   Log-Message "VLUN $SnapName Creation failed with status: $statusDescription"
		}
	}
}

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