####################################################################
#            HPE Metering Tool Linux Systems Pre-Check Tool        #  
####################################################################

# Global Variables
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$POSH = "$($scriptPath)\Posh-SSH"
$sshserial = 'sudo /usr/sbin/dmidecode -s system-serial-number'
$sysstat = 'rpm -q sysstat'
$sysstatservice = 'systemctl status sysstat'
$collectsar =  'sar -P ALL'

Write-Host "`n####################################################################"
Write-Host "#         HPE Metering Tool Linux Systems Pre-Check Tool           #"
Write-Host "####################################################################`n"

#Load HPESimpliVity , VMware.PowerCLI, Posh-SSH
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
		 Write-Host "SSH Module Version: $($InstalledPoshSSHModule) installed on your machine."
		 Write-host ""
}
 

try
{
    $path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\iPInput.csv"
    $inputcsv = Import-Csv $path
	if($inputcsv.IP.count -eq 0)
	{
		Write-Host "Provide values for IP column in the iLOInput.csv file and try again."
        exit
	}

    $notNullIP = $inputcsv.IP | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}

	
	if(-Not $notNullIP.Count)
	{
        Write-Host "Provide equal number of values for IP column in the iLOInput.csv file and try again."
        exit
	}
}
catch
{
    Write-Host "iLOInput.csv file import failed. Please check the file path of the iLOInput.csv file and try again."
    Write-Host "iLOInput.csv file path: $path"
    exit
}

 do {
		Write-Host "`nChose Authentication Method..." -ForegroundColor Yellow
		$authmethod = Read-Host -Prompt "Password Or SSH Key-Based ? (p/k)"
 
		if (($authmethod -eq 'P' -or $authmethod -eq 'p') -or ($authmethod -eq 'K' -or $authmethod -eq 'k')) {
			break  
		} else { 
		}
}while ($true)		
 
 if ($authmethod -eq 'P' -or $authmethod -eq 'p') {
	  $credential = Get-Credential -Message 'Enter Greenlake glmeter Credential' -Username 'glmeter' 
	  

} else {
  
      $password = ConvertTo-SecureString 'x' -AsPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential ('glmeter', $password)
	  
	  Write-Host "Copy the private key file to your working directory ($($scriptPath))" -ForegroundColor Yellow
	  $KeyFile = Read-Host -Prompt "Private Key File Name"

}

$resultTable = @()

Write-Host "------------------------------------------------"
Write-Host "####          SSH Connection Test           ####"
Write-Host "------------------------------------------------"

foreach($ip in $inputcsv.IP ){
	 
	try {
		
        Write-Host "Trying to establish SSH Connection to $($ip)" -ForegroundColor Yellow  
		
		if ($authmethod -eq 'P' -or $authmethod -eq 'p') {
			
			$SSHConnection = New-SSHSession -ComputerName $ip -port 22 -Credential $credential -AcceptKey -ErrorAction Stop

		} else {
		
			$SSHConnection = New-SSHSession -ComputerName $ip -port 22 -Credential (Get-Credential -Credential $credential) -KeyFile $KeyFile -AcceptKey -ErrorAction Stop

		}	
			
        
        if ($SSHConnection.Connected) {
            Write-Host "SSH Connection established to $($ip)" -ForegroundColor Green
			
			$Session = Get-SSHSession | Where-Object { $_.Host -like "$($ip)" } | Select-Object SessionId
            
			
			# Capture Host Serial Number
	        $SerialNumber = Invoke-SSHcommand -SessionId $Session.SessionID -Command $sshserial -TimeOut 60  -ErrorAction Stop
			
			if ($SerialNumber.ExitStatus -eq 0 ){
			
			      $HostSerial = "$($SerialNumber.Output)"
				  
			} else {
				
				  $HostSerial = "Serial Not Collected"
				
			}
			
			# Verify sysstat RPM has been installed
			$sysstatpackage =  Invoke-SSHcommand -SessionId $Session.SessionID -Command $sysstat -TimeOut 60  -ErrorAction Stop
			
			# Verify sysstat Service Running
			$sysstatservice =  Invoke-SSHcommand -SessionId $Session.SessionID -Command $sysstatservice -TimeOut 60  -ErrorAction Stop
			
			if ($sysstatservice.ExitStatus -eq 3){
				
				$sysstatservicestate = "Inactive"
			}
			
			if ($sysstatservice.ExitStatus -eq 0){
				
				$sysstatservicestate = "Active"
			}
			
			if ($sysstatservice.ExitStatus -eq 1){
				
				$sysstatservicestate = "Service Not Installed"
			}
			
			# Verify Collect sar report
			$sarreport =  Invoke-SSHcommand -SessionId $Session.SessionID -Command $collectsar -TimeOut 60  -ErrorAction Stop
			
			if ($sarreport.ExitStatus -eq 0 ){
			
			      $sarreportstate = "Consistent"
				  
			} else {
				
				  $sarreportstate = "Not Consistent"
				
			}
			
            # Add success result to the table
            $result = [PSCustomObject]@{
                '     Host     ' = $ip
                ' SSH Connection ' = "Connected"
				'  Host Serial Number ' = $HostSerial
				'     sysstat Package State     ' = "$($sysstatpackage.Output)"
				' sysstat Service State ' = "$($sysstatservicestate)"
				'  sysstat Cron Entry   ' = "$($sarreportstate)"
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
            ' sysstat Service State ' = "NULL"
            '  sysstat Cron Entry   ' = "NULL"		
        }
        $resultTable += $result
    } 
	 
	 
	 
}
Write-Host "`n------------------------------------------------"
Write-Host "####              Test Results              ####"
Write-Host "------------------------------------------------"

# Display the results in a table format
$resultTable | Format-Table -AutoSize

Get-SSHSession | Remove-SSHSession | Out-Null