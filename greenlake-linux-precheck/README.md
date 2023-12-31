# HPE Metering Tool Linux Systems Pre-Check Tool

## Overview
The HPE Metering Tool Pre-Check Script for Linux Systems is a PowerShell script designed to facilitate the pre-check process for Linux servers in a network. This tool automates the process of validating system prerequisites before deploying the HPE Metering Tool.

## Features
- **SSH Connection Management**: Uses Posh-SSH module for establishing SSH connections to Linux servers.
- **Serial Number Collection**: Retrieves the system's serial number using dmidecode.
- **Sysstat Package Check**: Verifies if the sysstat package is installed and its service status.
- **SAR Report Validation**: Checks for the consistency of the SAR (System Activity Report) on the target system.
- **Flexible Authentication**: Supports both username/password and SSH key-based authentication methods.
- **Result Aggregation**: Compiles a detailed report of the checks performed on each server.

## Prerequisites
1. **PowerShell**: The script is written in PowerShell and requires a PowerShell environment to run.
2. **Posh-SSH Module**: This module is required for SSH operations. It's loaded dynamically within the script.
3. **Input File**: A CSV file (iPInput.csv) containing the IP addresses of the target Linux systems.

## Usage
1. **Prepare the Input CSV**: Ensure that iPInput.csv contains the IP addresses of all the Linux servers you intend to check.
2. **Run the Script**: Execute the script in a PowerShell environment.
3. **Choose Authentication Method**: When prompted, choose between username/password or SSH key-based authentication.
4. **Authentication Details**: If choosing username/password, the script will prompt to save credentials. For SSH key-based authentication, ensure the private key file is in the script directory.
5. **Review Results**: After execution, the script will display a table summarizing the status of each server.

## Important Variables
- `$scriptPath`: The path of the script directory.
- `$credFile`: The credential file for storing username/password.
- `$KeyFile`: The private key file for SSH key-based authentication.

## Output
The script generates a table with the following columns for each target server:
- Host IP Address
- SSH Connection Status
- Host Serial Number
- Sysstat Package State
- Sysstat Service State
- Sysstat Cron Entry State

## Notes
- Ensure Posh-SSH module is available or accessible for the script.
- The script must be run with appropriate permissions to access and modify the required files.
- It is recommended to review and test the script in a controlled environment before deploying in a production setting.

## Disclaimer
This script is provided as-is with no guarantees. It is recommended to thoroughly review and test the script in your environment before use.

---

Feel free to contribute or suggest improvements through pull requests or issues in the repository. For any queries or support, please refer to the 'Issues' section of this GitHub repository.
