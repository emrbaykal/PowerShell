####### Define Environment Variables ( Customer fill it according to his own environment)##########
@{
    ## Define the URI of the storage system API
    uri = 'https://xx.xx.xx:443/api/v1'
	
	## Define the path to the credential file
    credFile = '$PSScriptRoot\cred.XML'

    ## Define Application set
    applicationset = 'SQL-DB-SNAP'
	
    ## Define Snapshot Comment
    snapcomment = 'SQL Database LUNs Daily Snapshot'
        
    ## Define E-Mail Parameters
    emailTo = 'emre.baykal@hpe.com'
    emailFrom = 'emre.baykal@hpe.com'
    SmtpServer = 'smtp.fabrikam.com'
	
	## Define Snapshot Volume Groups
    volumeGroups = @(
        @{
            volumeName = 'TEST-VOL01'
            snapshotName = 'TEST-VOL01-SNAP'
            snapshotId = 133
            snapshotWWN = '60002AC000000000000000B900026A1F'
            readWrite = $true
            snapVlunId = 12
            hostSet = 'set:TEST-HOST-SET'
        },
        @{
            volumeName = 'TEST-VOL02'
            snapshotName = 'TEST-VOL02-SNAP'
            snapshotId = 134
            snapshotWWN = '60002AC000000000000000BB00026A1F'
            readWrite = $true
            snapVlunId = 13
            hostSet = 'set:TEST-HOST-SET'
        },
		@{
            volumeName = 'TEST-VOL03'
            snapshotName = 'TEST-VOL03-SNAP'
            snapshotId = 135
            snapshotWWN = '60002AC000000000000000BD00026A1F'
            readWrite = $true
            snapVlunId = 14
            hostSet = 'set:TEST-HOST-SET'
        },
		@{
            volumeName = 'TEST-VOL04'
            snapshotName = 'TEST-VOL04-SNAP'
            snapshotId = 136
            snapshotWWN = '60002AC000000000000000BF00026A1F'
            readWrite = $true
            snapVlunId = 15
            hostSet = 'set:TEST-HOST-SET'
        },
		@{
            volumeName = 'TEST-VOL05'
            snapshotName = 'TEST-VOL05-SNAP'
            snapshotId = 137
            snapshotWWN = '60002AC0000000000000010600026A1F'
            readWrite = $true
            snapVlunId = 16
            hostSet = 'set:TEST-HOST-SET'
        },
		@{
            volumeName = 'TEST-VOL06'
            snapshotName = 'TEST-VOL06-SNAP'
            snapshotId = 138
            snapshotWWN = '60002AC0000000000000010F00026A1F'
            readWrite = $true
            snapVlunId = 17
            hostSet = 'set:TEST-HOST-SET'
        }
    )
	

}