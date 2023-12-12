# HPE SimpliVity Factory Reset PowerShell Script

## Overview

This PowerShell script is designed for performing a factory reset on HPE SimpliVity servers. It leverages the `HPEiLOCmdlets`, `VMware.PowerCLI`, `HPESimpliVity` PowerShell modules to interact with the servers, ensuring a streamlined and automated process.

### Features

- **Automated Factory Reset**: Facilitates the resetting of SimpliVity servers to their factory settings.
- **Comprehensive Server Analysis**: Retrieves detailed information about server status, network adapters, virtual switches, and more.
- **Credential and Configuration Management**: Handles infrastructure variables and credentials securely.
- **Error Handling**: Implements robust error handling to ensure smooth script execution.

### Prerequisites

- PowerShell environment with administrative privileges.
- `HPEiLOCmdlets`, `HPESimpliVity`, and `VMware.PowerCLI` PowerShell modules installed.
- Input CSV file (`iLOInput.csv`) with server details (iLO IPv4 address, username, password, and OVC Host ip).
- Infrastructure variable filewill be create automaticly  (`infra_variable.json`) and credential file (`cred.XML`) for secure information storage.

### Usage

Run the script in a PowerShell environment with administrative privileges:

```powershell
PS C:\HPEiLOCmdlets\Samples\> .\simplivity-factory-reset.ps1
```

Ensure the `iLOInput.csv` file is present in the script folder with the necessary server details.

## Key Components

- **Pre-Execution Checks**: Verifies the presence of necessary modules and input files.
- **Server and Network Analysis**: Gathers information about the status of SimpliVity and ESXi hosts, network adapters, and virtual switches.
- **Factory Reset Process**:
  - Resets OS RAID configuration.
  - Mounts firmware images.
  - Handles server power resets and state monitoring.
  - Manages SimpliVity thin image handling.
- **Post-Execution Cleanup**: Safely disconnects from servers and handles any errors encountered during execution.

## Important Notes

- **Administrator Mode**: Always run the PowerShell script in administrator mode.

## Disclaimer

This script is provided as-is, and users should ensure they understand its operations before executing it in a production environment. Hewlett Packard Enterprise holds no responsibility for any unintended outcomes resulting from the use of this script.

## License

This script is licensed under the [Apache 2.0](LICENSE).


