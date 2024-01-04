####################################################################
#            HPE Metering Tool Linux Systems Pre-Check Tool        #  
####################################################################

# Global Variables
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$POSH = "$($scriptPath)\Posh-SSH"
# Define the path to the credential file
$credFile = ".\cred.XML"
# Define the path to the private key file
$KeyFile = ".\private.key"
# Define default user name
$DefaultUserName = "glmeter"
#Reports Directory
$ReportDirPath= ".\Reports"
#Log Timestamp
$logtimestamp = get-date -UFormat "%m-%d-%YT%R" | ForEach-Object { $_ -replace ":", "." }
#Report File
$CLSReportFile = "$($ReportDirPath)\$($logtimestamp).log"


Write-Host "`n####################################################################"
Write-Host "#         HPE Metering Tool Linux Systems Pre-Check Tool           #"
Write-Host "####################################################################`n"

#Load Posh-SSH
$InstalledModule = Get-Module 
$ModuleNames = $InstalledModule.Name
 
if(-not($ModuleNames -like "Posh-SSH")){

	Write-Host "Loading module :  Posh-SSH "
	Import-Module "$POSH"
	if(($(Get-Module -Name "Posh-SSH")  -eq $null)){
		Write-Host ""
		Write-Host "Posh-SSH module cannot be loaded. Please fix the problem and try again"
		Write-Host ""
		Write-Host "Exit..."
		exit
	}
		 
}else{
		 $InstalledPoshSSHModule  =  Get-Module -Name "Posh-SSH"
		 Write-Host "SSH Module : $($InstalledPoshSSHModule) installed on your machine."
}
 
#Read Host IP Address From CSV File
try
{
    $path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\iPInput.csv"
    $inputcsv = Import-Csv $path
	if($inputcsv.IP.count -eq 0)
	{
		Write-Host "Provide values for IP column in the iPInput.csv file and try again."
        exit
	}

    $notNullIP = $inputcsv.IP | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}

	
	if(-Not $notNullIP.Count)
	{
        Write-Host "Provide equal number of values for IP column in the iPInput.csv file and try again."
        exit
	}
}
catch
{
    Write-Host "iPInput.csv file import failed. Please check the file path of the iPInput.csv file and try again."
    Write-Host "iPInput.csv file path: $path"
    exit
}

#Create Report Directory
if(!(Test-Path -Path $ReportDirPath))
{
	#powershell create reports directory
	$directory = New-Item -ItemType Directory -Path $ReportDirPath
	Write-Host "New reports directory $($directory) created successfully...`n" -f Green
}else
{
	Write-Host "Repors directory already exists...`n" -f Yellow
}

#Chose Authentication Method
Write-Host "---------------- Chose Authentication Method -----------------------" -ForegroundColor Yellow
Write-Host "[1]" -NoNewline -ForegroundColor Cyan; Write-Host " Username / Password" -ForegroundColor White
Write-Host "[2]" -NoNewline -ForegroundColor Cyan; Write-Host " SSH Key-Based" -ForegroundColor White

do {
	try { 
		[ValidateSet('1','2','$null')]$authmethod = $(Write-Host "`nPlease choose [1 to 2] to chode Authentication Method: " -NoNewline -ForegroundColor White; Read-Host -ErrorAction SilentlyContinue) 
		break
		} 
		
	catch { Write-Host "Invalid option! `nPlease choose option from 1 to 2 " -ForegroundColor Yellow; $authmethod = '$null' }
	
}while ($true)
 
 if ( ($authmethod -eq 1) -and (-Not (Test-Path $credFile)) ) {
	  
	  Write-Host "Username / Password Method Choosed To Authenticate Host..."
	  Get-Credential -Message '`nEnter Greenlake glmeter Credential' -Username 'glmeter' | Export-Clixml .\cred.XML
	  Write-Host "Credentials saved to $credFile..." -ForegroundColor Yellow
	  

} elseif ( ($authmethod -eq 1) -and ((Test-Path $credFile)) ) {
	  Write-Host "Username / Password Method Choosed To Authenticate Host..."
	  Write-Host "Credential File $credFile found under the working director... " -ForegroundColor Green 
}elseif ( $authmethod -eq 2 ){
  
      Write-Host "SSH Key-Based Method Choosed To Authenticate Host..."
	  Write-Host "`nPlease Copy the SSH Private key file to working directory with the file name private.key - Working Directory: ($($scriptPath))" -ForegroundColor Yellow

	  $UserName = $(Write-Host "Metering Tool Linux User Name (default is glmeter): " -NoNewline -ForegroundColor White; Read-Host  -ErrorAction SilentlyContinue ) -f $DefaultUserName
	  
	  if (-not $UserName) { $UserName = $DefaultUserName }
      
	  $password = ConvertTo-SecureString 'x' -AsPlainText -Force
      $Cred = New-Object System.Management.Automation.PSCredential ($UserName, $password)

	  if (-Not (Test-Path $KeyFile)){
		  
		  Write-Host "`nPrivate SSH-Key File did not found under the working directory ($($scriptPath)\private.key) !!!" -ForegroundColor Red
		  Break
	  } else {
		  Write-Host "Private SSH-Key File (private.key) found under the working director... " -ForegroundColor Green
	  }
	  
	  
}

Write-Host ""

# Start a transcript log
Start-Transcript -Path $CLSReportFile 
$resultTable = @()

Write-Host "`n----------------------------------------------------"
Write-Host "####            SSH Connection Test             ####"
Write-Host "----------------------------------------------------"  

#Trying to check requirements tıo the each hosts
foreach($ip in $inputcsv.IP ){
	 
	try {
		
        Write-Host "Trying to establish SSH Connection to $($ip)" -ForegroundColor Yellow  
		if ($authmethod -eq 1) {	
			#Import Credential File
	        $Cred = Import-CLIXML .\cred.XML
			$SSHConnection = New-SSHSession -ComputerName $ip -port 22 -Credential $Cred -AcceptKey -ErrorAction Stop
		}elseif (($authmethod -eq 2) -and ((Test-Path $KeyFile)) ) {
			$SSHConnection = New-SSHSession -ComputerName $ip -port 22 -Credential (Get-Credential -Credential $Cred) -KeyFile $KeyFile -AcceptKey -ErrorAction Stop
		} 
			
        if ($SSHConnection.Connected) {
			
			$Date = Get-Date
            $YesterDayDate = ($date.AddDays(-1)).ToString("dd")
			$sshserial = 'sudo /usr/sbin/dmidecode -s system-serial-number'
			$sshserialText = "cat /home/$($UserName)/serial.txt"
			$sysstat = 'rpm -q sysstat'
			$sysstatservice = 'systemctl status sysstat'
			$sarcurrentday =  "sar -P ALL | grep 'Average.* all'"
			$sarprevdate =  "/usr/bin/sar -P ALL -f /var/log/sa/sa$($YesterDayDate)  -s 00:00:00 | grep 'Average.* all'"
            Write-Host "SSH Connection established to $($ip)" -ForegroundColor Green
			$Session = Get-SSHSession | Where-Object { $_.Host -like "$($ip)" } | Select-Object SessionId
            
			# Capture Host Serial Number
	        $SerialNumber = Invoke-SSHcommand -SessionId $Session.SessionID -Command $sshserial -TimeOut 60  -ErrorAction Stop
			$SerialNumberText = Invoke-SSHcommand -SessionId $Session.SessionID -Command $sshserialText -TimeOut 60  -ErrorAction Stop
			
			if ($SerialNumber.ExitStatus -eq 0 ){
			      $HostSerial = "$($SerialNumber.Output)"  
			}elseif ($SerialNumberText.ExitStatus -eq 0) {
				  $HostSerial = "$($SerialNumberText.Output)"
			}
			else {
				  $HostSerial = "Serial Not Collected"
			}
			
			# Verify sysstat RPM has been installed
			$sysstatpackage =  Invoke-SSHcommand -SessionId $Session.SessionID -Command $sysstat -TimeOut 60  -ErrorAction Stop
			
			# Verify sysstat Service Running
			$sysstatservicechk =  Invoke-SSHcommand -SessionId $Session.SessionID -Command $sysstatservice -TimeOut 60  -ErrorAction Stop
			
			if ($sysstatservicechk.ExitStatus -eq 3){
				$sysstatservicestate = "Inactive"
			}elseif ($sysstatservicechk.ExitStatus -eq 0){	
				$sysstatservicestate = "Active"
			}elseif ($sysstatservicechk.ExitStatus -eq 1){
				$sysstatservicestate = "Service Not Installed"
			}
			
			# Verify Collect Previus Day sar report
			$sarreportprevday =  Invoke-SSHcommand -SessionId $Session.SessionID -Command $sarprevdate -TimeOut 60  -ErrorAction Stop
			
			if ($sarreportprevday.ExitStatus -eq 0 ){
				  $sarreportprevdaysplit = $sarreportprevday.Output -split '\s+'
			      $sarreportprevdaystate = $sarreportprevdaysplit[4]
			} else {
				  $sarreportprevdaystate = "SAR Report Not Collect"
			}

           
			$sarreportcurrentday =  Invoke-SSHcommand -SessionId $Session.SessionID -Command  $sarcurrentday -TimeOut 60  -ErrorAction Stop
			
			if ($sarreportcurrentday.ExitStatus -eq 0 ){
				  $sarreportcurrentdaysplit = $sarreportcurrentday.Output -split '\s+'
			      $sarreportcurrentdaystate = $sarreportcurrentdaysplit[4]
			} else {
				  $sarreportcurrentdaystate = "SAR Report Not Collect"
			}
			
			
            # Add success result to the table
            $result = [PSCustomObject]@{
                '     Host     ' = $ip
                ' SSH Connection ' = "Connected"
				'  Host Serial Number ' = $HostSerial
				'     sysstat Package State     ' = "$($sysstatpackage.Output)"
				' sysstat Service ' = "$($sysstatservicestate)"
				' SAR Prev. Day %system ' = "$($sarreportprevdaystate)"
				' SAR Current Day %system ' = "$($sarreportcurrentdaystate)"
            }
            $resultTable += $result

        }
		
    } catch {
        Write-Host "SSH Connection could not be established to $($ip)" -ForegroundColor Red
        # Add failure result to the table
        $result = [PSCustomObject]@{
            '     Host     ' = $ip
            ' SSH Connection ' = "Failed"
            '  Host Serial Number ' = "NULL"
            '     sysstat Package State     ' = "NULL"
            ' sysstat Service ' = "NULL"
            ' SAR Prev. Day %system ' = "NULL"
			' SAR Current Day %system ' = "NULL"
        }
        $resultTable += $result
    } 
}

Write-Host "`n------------------------------------------------"
Write-Host "####              Test Results              ####"
Write-Host "------------------------------------------------"

# Display the results in a table format
$resultTable | Format-Table -AutoSize

#Stop transcript log
Stop-Transcript
Write-Host ""

Get-SSHSession | Remove-SSHSession | Out-Null