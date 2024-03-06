# HPE Primera Storage Management PowerShell Script

This PowerShell script facilitates interaction with an HPE Primera or compatible storage system's API, enabling the creation, deletion, and management of snapshots, application sets, and VLUNs.

## Features

- **Create Snapshots**: Automate the creation of snapshots for data protection and quick recovery.
- **Delete Snapshots**: Clean up old or unnecessary snapshots to free up storage space.
- **Manage VLUNs**: Create and delete virtual LUNs (VLUNs) to manage access to the snapshots.
- **Application Set Management**: Create and delete application sets to group related volumes for easier management.

## Prerequisites

- PowerShell 5.1 or later.
- Access to an HPE Primera or compatible storage system's API.
- Valid credentials for the storage system.

## Getting Started

1. **Download the script**: Clone this repository or download the script file to your local system.

2. **Modify the Config File**: Update the configuration file (`YourConfigFile.ps1`) with your storage system's URI, credentials file path, volume groups, application set, and snapshot comment as needed.

3. **Run the Script**: Open PowerShell as an administrator and run the script with the following command:

    ```powershell
    .\YourScriptName.ps1 -ConfigFilePath .\YourConfigFile.ps1
    ```

## Parameters

- `-ConfigFilePath`: Specifies the path to the configuration file containing necessary parameters for the script to connect and interact with the storage system.

## Script Overview

- The script starts by skipping SSL certificate validation for ease of use in testing environments.
- It then checks if the specified configuration file exists. If not, it exits with an error message.
- Configuration data from the file is imported, including the storage system's URI, credential file path, volume groups, application set name, and snapshot comment.
- Various functions are defined for logging messages, initializing credentials, getting authentication tokens, and creating, assigning, or deleting VLUNs, application sets, and snapshots.
- The script concludes with a sequence of calls to these functions to perform storage management operations as specified in the configuration file.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues to improve the script or add new features.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This script is provided as is, with no warranties. Always test in your environment before using in production.

## Acknowledgments

- Hewlett Packard Enterprise for providing the API and documentation.
- [Emre Baykal - HPE Services](mailto:emre.baykal@hpe.com) for creating this script.
