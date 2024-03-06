####### Define Environment Variables ( Customer fill it according to his own environment)##########
@{
    ## Define the URI of the storage system API
    uri = 'https://xx.xx.xx.xx:443/api/v1'
	
	## Define the path to the credential file
    credFile = '$PSScriptRoot\cred.XML'
	
	## Define Snapshot Volume Groups
    volumeGroups = @(
        @{
            volumeName = 'VOL01'
            snapshotName = 'VOL01-SNAP'
            snapshotId = 133
            snapshotWWN = '60002AC0000000000000008100026A1F'
            readWrite = $true
            snapVlunId = 12
            hostSet = 'set:SQL-DEV-HOSTS'
        },
        @{
            volumeName = 'VOL02'
            snapshotName = 'VOL02-SNAP'
            snapshotId = 134
            snapshotWWN = '60002AC0000000000000008200026A1F'
            readWrite = $true
            snapVlunId = 13
            hostSet = 'set:SQL-DEV-HOSTS'
        }
    )
	
	## Define Application set
    applicationset = 'SQL-DB-SNAP'
	
	## Define Snapshot Comment
    snapcomment = 'SQL Database LUNs Daily Snapshot'
}